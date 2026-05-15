#!/bin/bash
# RAM monitoring module

get_ram_usage() {
    local usage

    if is_macos; then
        usage=$(vm_stat 2>/dev/null | awk '
            /page size of/ { page_size=$8 }
            /Pages active/ { active=$3 }
            /Pages wired down/ { wired=$4 }
            /Pages occupied by compressor/ { compressed=$5 }
            /Pages free/ { free=$3 }
            /Pages inactive/ { inactive=$3 }
            END {
                gsub(/\./, "", active)
                gsub(/\./, "", wired)
                gsub(/\./, "", compressed)
                gsub(/\./, "", free)
                gsub(/\./, "", inactive)
                used=(active + wired + compressed) * page_size
                total=(active + wired + compressed + free + inactive) * page_size
                if (total > 0) printf "%.1f GiB / %.1f GiB (%d%%)", used / 1024 / 1024 / 1024, total / 1024 / 1024 / 1024, used * 100 / total
            }')
    elif is_linux && command_exists free; then
        usage=$(free -m 2>/dev/null | awk '/^Mem:/ { printf "%.1f GiB / %.1f GiB (%d%%)", $3 / 1024, $2 / 1024, $3 * 100 / $2 }')
    fi

    if [ -n "$usage" ]; then
        echo "$usage"
    else
        echo "Unavailable"
    fi
}
