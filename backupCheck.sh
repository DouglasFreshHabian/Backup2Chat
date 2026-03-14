#!/usr/bin/env bash

# Output files
CSV_FILE="adb_backup_scan.csv"
JSON_FILE="adb_backup_scan.json"

# Colors
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RESET="\033[0m"

echo -e "${BLUE}[*] Starting ADB backup capability scan...${RESET}"

if ! adb get-state >/dev/null 2>&1; then
    echo -e "${RED}[!] No ADB device detected.${RESET}"
    exit 1
fi

echo -e "${BLUE}[*] Device connected.${RESET}"
echo -e "${BLUE}[*] Gathering package data (fast mode)...${RESET}"

# CSV header
echo "package,backup_allowed" > "$CSV_FILE"

TMP=$(mktemp)

adb shell dumpsys package > "$TMP"

allowed=0
blocked=0
total=0

echo "[" > "$JSON_FILE"
first=1

while IFS=, read -r pkg allow; do

    ((total++))

    echo "$pkg,$allow" >> "$CSV_FILE"

    if [[ "$allow" == "true" ]]; then
        echo -e "${GREEN}[+] Backup allowed:${RESET} $pkg"
        ((allowed++))
    else
        echo -e "${RED}[-] Backup disabled:${RESET} $pkg"
        ((blocked++))
    fi

    if [[ $first -eq 1 ]]; then
        first=0
    else
        echo "," >> "$JSON_FILE"
    fi

    printf "  {\"package\": \"%s\", \"backup_allowed\": %s}" "$pkg" "$allow" >> "$JSON_FILE"

done < <(
awk '
/^  Package \[/{
    pkg=$2
    gsub(/\[/,"",pkg)
    gsub(/\]/,"",pkg)
    allow="false"
}
/ALLOW_BACKUP/{
    allow="true"
}
/pkgFlags=\[/{
    if(pkg!=""){
        print pkg","allow
        pkg=""
    }
}
' "$TMP"
)

echo -e "\n]" >> "$JSON_FILE"

rm "$TMP"

echo
echo -e "${YELLOW}[*] Scan complete.${RESET}"
echo -e "${GREEN}    Backup allowed:${RESET} $allowed"
echo -e "${RED}    Backup disabled:${RESET} $blocked"
echo -e "${BLUE}    Total packages:${RESET} $total"
echo
echo -e "${BLUE}[*] Results saved:${RESET}"
echo "    CSV : $CSV_FILE"
echo "    JSON: $JSON_FILE"
