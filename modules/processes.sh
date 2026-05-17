#!/bin/bash
# Process monitoring module

get_process_table() {
    local ps_output

    if ! command_exists ps; then
        echo "Unavailable"
        return
    fi

    if is_macos; then
        ps_output=$(ps -axww -o pid=,%cpu=,%mem=,command= 2>/dev/null)
    else
        ps_output=$(ps -eo pid=,%cpu=,%mem=,command= 2>/dev/null)
    fi

    if [ -z "$ps_output" ]; then
        echo "Unavailable"
        return
    fi

    printf '%s\n' "$ps_output" |
        awk '
            function clean_name(command, first_word, app_name) {
                app_name = command
                if (app_name ~ /\/Applications\/.*\.app/) {
                    sub(/^.*\/Applications\//, "", app_name)
                    sub(/\.app.*$/, "", app_name)
                    return app_name
                }

                first_word = command
                sub(/[[:space:]].*$/, "", first_word)
                sub(/^.*\//, "", first_word)

                if (first_word != "") {
                    return first_word
                }

                return command
            }

            NF >= 3 {
                pid=$1
                cpu=$2
                mem=$3
                name=$0
                sub(/^[[:space:]]*[0-9]+[[:space:]]+[0-9.]+[[:space:]]+[0-9.]+[[:space:]]+/, "", name)
                name=clean_name(name)
                gsub(/\|/, "/", name)
                printf "%s|%s|%.1f|%.1f\n", name, pid, cpu, mem
            }
        '
}

get_app_name() {
    local process_name="$1"

    case "$process_name" in
        "Google Chrome"*|"Chrome Helper"*|"Google Chrome Helper"*)
            echo "Google Chrome"
            ;;
        "Code"|"Code Helper"*|"Visual"|"Visual Studio Code"*)
            echo "VS Code"
            ;;
        "Windsurf"|"Windsurf Helper"*)
            echo "Windsurf"
            ;;
        "com.apple.WebKit."*|"Safari"|"Safari Networking"|"Safari Web Content"*)
            echo "Safari/WebKit"
            ;;
        "com.docker."*|"Docker"|"Docker Desktop"*)
            echo "Docker"
            ;;
        "node"|"nodejs")
            echo "Node.js"
            ;;
        "python"|"python3")
            echo "Python"
            ;;
        "java")
            echo "Java"
            ;;
        *)
            echo "$process_name"
            ;;
    esac
}

get_app_table() {
    local process_table

    process_table="$(get_process_table)"

    if [ "$process_table" = "Unavailable" ] || [ -z "$process_table" ]; then
        echo "Unavailable"
        return
    fi

    while IFS='|' read -r name pid cpu memory; do
        printf '%s|%s|%s|%s\n' "$(get_app_name "$name")" "$pid" "$cpu" "$memory"
    done <<EOF |
$process_table
EOF
        awk -F'|' '
            {
                app=$1
                count[app] += 1
                cpu[app] += $3
                memory[app] += $4
            }
            END {
                for (app in count) {
                    printf "%s|%d|%.1f|%.1f\n", app, count[app], cpu[app], memory[app]
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
