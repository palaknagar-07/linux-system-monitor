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

get_ram_breakdown() {
    local breakdown

    if is_macos && command_exists vm_stat; then
        breakdown=$(vm_stat 2>/dev/null | awk '
            /page size of/ { page_size=$8 }
            /Pages active/ { active=$3 }
            /Pages wired down/ { wired=$4 }
            /Pages occupied by compressor/ { compressed=$5 }
            /Pages inactive/ { inactive=$3 }
            /Pages free/ { free=$3 }
            END {
                gsub(/[^0-9]/, "", page_size)
                gsub(/[^0-9]/, "", active)
                gsub(/[^0-9]/, "", wired)
                gsub(/[^0-9]/, "", compressed)
                gsub(/[^0-9]/, "", inactive)
                gsub(/[^0-9]/, "", free)

                if (page_size > 0) {
                    divisor = 1024 * 1024 * 1024
                    printf "App Memory|%.1f\n", active * page_size / divisor
                    printf "Wired/System|%.1f\n", wired * page_size / divisor
                    printf "Compressed|%.1f\n", compressed * page_size / divisor
                    printf "Cache/Inactive|%.1f\n", inactive * page_size / divisor
                    printf "Free|%.1f\n", free * page_size / divisor
                }
            }')
    elif is_linux && [ -r /proc/meminfo ]; then
        breakdown=$(awk '
            $1 == "MemTotal:" { total=$2 }
            $1 == "MemFree:" { free=$2 }
            $1 == "MemAvailable:" { available=$2 }
            $1 == "Buffers:" { buffers=$2 }
            $1 == "Cached:" { cached=$2 }
            $1 == "SReclaimable:" { sreclaimable=$2 }
            $1 == "Shmem:" { shmem=$2 }
            END {
                cache = cached + sreclaimable - shmem
                used = total - free - buffers - cache
                if (used < 0) used = 0
                if (total > 0) {
                    divisor = 1024 * 1024
                    printf "Used|%.1f\n", used / divisor
                    printf "Buffers|%.1f\n", buffers / divisor
                    printf "Cache|%.1f\n", cache / divisor
                    printf "Free|%.1f\n", free / divisor
                    printf "Available|%.1f\n", available / divisor
                }
            }' /proc/meminfo 2>/dev/null)
    fi

    if [ -n "$breakdown" ]; then
        printf '%s\n' "$breakdown"
    else
        echo "Unavailable"
    fi
}
