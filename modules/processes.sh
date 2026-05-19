#!/bin/bash
# Process monitoring module

get_process_records() {
    local ps_output

    if ! command_exists ps; then
        echo "Unavailable"
        return
    fi

    if is_macos; then
        ps_output=$(ps -axww -o pid=,ppid=,%cpu=,%mem=,command= 2>/dev/null)
    else
        ps_output=$(ps -eww -o pid=,ppid=,%cpu=,%mem=,command= 2>/dev/null)
    fi

    if [ -z "$ps_output" ]; then
        echo "Unavailable"
        return
    fi

    printf '%s\n' "$ps_output" |
        awk '
            function basename_from_path(value) {
                sub(/[[:space:]].*$/, "", value)
                sub(/^.*\//, "", value)
                return value
            }

            function app_from_bundle(command, before_app, app_name, app_index, offset, suffix, remainder) {
                offset = 0
                remainder = command

                while ((app_index = index(remainder, ".app")) > 0) {
                    suffix = substr(remainder, app_index + 4, 10)
                    if (suffix == "/Contents/") {
                        before_app = substr(command, 1, offset + app_index - 1)
                        app_name = before_app
                        sub(/^.*\//, "", app_name)
                        return app_name
                    }

                    offset += app_index
                    remainder = substr(command, offset + 1)
                }

                return ""
            }

            function display_name(command, bundle_name, executable_name) {
                bundle_name = app_from_bundle(command)
                if (bundle_name != "") {
                    return bundle_name
                }

                executable_name = basename_from_path(command)
                if (executable_name != "") {
                    return executable_name
                }

                return command
            }

            NF >= 5 {
                pid=$1
                ppid=$2
                cpu=$3
                memory=$4
                command=$0
                sub(/^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9.]+[[:space:]]+[0-9.]+[[:space:]]+/, "", command)
                name=display_name(command)

                gsub(/\|/, "/", name)
                gsub(/\|/, "/", command)

                printf "%s|%s|%.1f|%.1f|%s|%s\n", pid, ppid, cpu, memory, name, command
            }
        '
}

get_process_table() {
    local process_records

    process_records="$(get_process_records)"

    if [ "$process_records" = "Unavailable" ] || [ -z "$process_records" ]; then
        echo "Unavailable"
        return
    fi

    printf '%s\n' "$process_records" |
        awk -F'|' '{ printf "%s|%s|%s|%s\n", $5, $1, $3, $4 }'
}

get_app_table() {
    local process_records

    process_records="$(get_process_records)"

    if [ "$process_records" = "Unavailable" ] || [ -z "$process_records" ]; then
        echo "Unavailable"
        return
    fi

    printf '%s\n' "$process_records" |
        awk -F'|' '
            function app_from_bundle(command, before_app, app_name, app_index, offset, suffix, remainder) {
                offset = 0
                remainder = command

                while ((app_index = index(remainder, ".app")) > 0) {
                    suffix = substr(remainder, app_index + 4, 10)
                    if (suffix == "/Contents/") {
                        before_app = substr(command, 1, offset + app_index - 1)
                        app_name = before_app
                        sub(/^.*\//, "", app_name)
                        return app_name
                    }

                    offset += app_index
                    remainder = substr(command, offset + 1)
                }

                return ""
            }

            function is_system_process(name) {
                return name == "WindowServer" ||
                    name == "kernel_task" ||
                    name == "launchd" ||
                    name == "loginwindow" ||
                    name == "mds" ||
                    name == "mdworker" ||
                    name == "notifyd" ||
                    name == "configd" ||
                    name == "syslogd" ||
                    name == "trustd" ||
                    name == "powerd" ||
                    name == "runningboardd"
            }

            function is_webkit_process(name, command) {
                return name ~ /^com\.apple\.WebKit\./ || command ~ /com\.apple\.WebKit\./
            }

            function is_helper_process(name) {
                return name ~ /(^|[[:space:]])Helper($|[[:space:]])/ ||
                    name ~ /Renderer/ ||
                    name ~ /GPU/ ||
                    name ~ /Plugin/
            }

            function confidence_score(confidence) {
                if (confidence == "high") {
                    return 3
                }
                if (confidence == "medium") {
                    return 2
                }
                return 1
            }

            function confidence_name(score) {
                if (score >= 3) {
                    return "high"
                }
                if (score == 2) {
                    return "medium"
                }
                return "low"
            }

            function resolve_app(pid, parent, depth, app_name, parent_app) {
                app_name = app_from_bundle(command_by_pid[pid])
                if (app_name != "") {
                    resolved_name = app_name
                    resolved_confidence = "high"
                    resolved_reason = "app_bundle"
                    return
                }

                parent = ppid_by_pid[pid]
                depth = 0
                while (parent != "" && parent != "0" && depth < 10) {
                    parent_app = app_from_bundle(command_by_pid[parent])
                    if (parent_app != "") {
                        resolved_name = parent_app
                        resolved_confidence = "high"
                        resolved_reason = "parent_app_bundle"
                        return
                    }
                    parent = ppid_by_pid[parent]
                    depth += 1
                }

                if (is_system_process(name_by_pid[pid])) {
                    resolved_name = "System: " name_by_pid[pid]
                    resolved_confidence = "high"
                    resolved_reason = "known_system_process"
                    return
                }

                if (is_webkit_process(name_by_pid[pid], command_by_pid[pid])) {
                    resolved_name = "Unresolved WebKit Process"
                    resolved_confidence = "low"
                    resolved_reason = "webkit_owner_not_found"
                    return
                }

                if (is_helper_process(name_by_pid[pid])) {
                    resolved_name = "Unresolved Helper: " name_by_pid[pid]
                    resolved_confidence = "low"
                    resolved_reason = "helper_owner_not_found"
                    return
                }

                resolved_name = name_by_pid[pid]
                resolved_confidence = "medium"
                resolved_reason = "executable_name"
            }

            {
                pid=$1
                ppid_by_pid[pid]=$2
                cpu_by_pid[pid]=$3
                memory_by_pid[pid]=$4
                name_by_pid[pid]=$5
                command_by_pid[pid]=$6
                pids[++pid_count]=pid
            }

            END {
                for (i = 1; i <= pid_count; i++) {
                    pid = pids[i]
                    resolve_app(pid)

                    app = resolved_name
                    count[app] += 1
                    cpu[app] += cpu_by_pid[pid]
                    memory[app] += memory_by_pid[pid]

                    score = confidence_score(resolved_confidence)
                    if (!(app in min_confidence) || score < min_confidence[app]) {
                        min_confidence[app] = score
                    }

                    if (!(app in reason)) {
                        reason[app] = resolved_reason
                    } else if (reason[app] != resolved_reason) {
                        reason[app] = "mixed"
                    }
                }

                for (app in count) {
                    printf "%s|%d|%.1f|%.1f|%s|%s\n",
                        app,
                        count[app],
                        cpu[app],
                        memory[app],
                        confidence_name(min_confidence[app]),
                        reason[app]
                }
            }
        '
}

get_top_ram_processes() {
    local limit="${1:-3}"
    local process_table

    process_table="$(get_process_table)"

    if [ "$process_table" = "Unavailable" ] || [ -z "$process_table" ]; then
        echo "Unavailable"
        return
    fi

    printf '%s\n' "$process_table" |
        sort -t'|' -k4,4nr |
        head -n "$limit"
}

get_top_ram_apps() {
    local limit="${1:-3}"
    local app_table

    app_table="$(get_app_table)"

    if [ "$app_table" = "Unavailable" ] || [ -z "$app_table" ]; then
        echo "Unavailable"
        return
    fi

    printf '%s\n' "$app_table" |
        sort -t'|' -k4,4nr |
        head -n "$limit"
}

get_top_cpu_processes() {
    local limit="${1:-3}"
    local process_table

    process_table="$(get_process_table)"

    if [ "$process_table" = "Unavailable" ] || [ -z "$process_table" ]; then
        echo "Unavailable"
        return
    fi

    printf '%s\n' "$process_table" |
        sort -t'|' -k3,3nr |
        head -n "$limit"
}

get_top_cpu_apps() {
    local limit="${1:-3}"
    local app_table

    app_table="$(get_app_table)"

    if [ "$app_table" = "Unavailable" ] || [ -z "$app_table" ]; then
        echo "Unavailable"
        return
    fi

    printf '%s\n' "$app_table" |
        sort -t'|' -k3,3nr |
        head -n "$limit"
}
