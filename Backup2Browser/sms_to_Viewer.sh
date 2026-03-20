#!/usr/bin/env bash
set -euo pipefail

# =========================
# 🎨 Colors & Styling
# =========================
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

# =========================
# 📢 Helper Functions
# =========================
info()    { echo -e "${CYAN}${BOLD}[*]${RESET} $1"; }
success() { echo -e "${GREEN}${BOLD}[+]${RESET} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}[!]${RESET} $1"; }
error()   { echo -e "${RED}${BOLD}[-]${RESET} $1"; exit 1; }

# =========================
# 🔍 Variables
# =========================
JSON_DIR="Decompressed"

# =========================
# 🔍 Pre-checks
# =========================
[[ -f "backup.ab" ]] || error "backup.ab not found in current directory."

command -v jq >/dev/null 2>&1 || error "jq is not installed."
command -v tar >/dev/null 2>&1 || error "tar is missing."
command -v java >/dev/null 2>&1 || error "java is not installed."

[[ -f "abe.jar" ]] || error "abe.jar not found."
[[ -f "decompress.sh" ]] || error "decompress.sh not found."
[[ -f "viewer.html" ]] || error "viewer.html not found."

echo
info "Starting SMS forensic reconstruction pipeline..."
sleep 1

# =========================
# 🔓 Step 1: Convert .ab → .tar
# =========================
info "Converting Android backup (backup.ab → backup.tar)..."
echo -e "${YELLOW}[*] You may be prompted for your backup password now...${RESET}"
sleep 1

java -jar abe.jar unpack backup.ab backup.tar

success "Conversion complete: backup.tar created."
sleep 1

# =========================
# 📦 Step 2: Extract Archive
# =========================
info "Extracting backup archive..."
tar -xf backup.tar

success "Archive extracted."
sleep 1

# =========================
# 🧬 Step 3: Decompress SMS blobs
# =========================
info "Decompressing SMS/MMS backup blobs..."
chmod +x decompress.sh
./decompress.sh

success "Decompression complete. JSON files generated."
sleep 1

# =========================
# 🧪 Step 4: Combine JSON
# =========================
if compgen -G "$JSON_DIR/*.json" > /dev/null; then
    success "Found JSON files in $JSON_DIR/"
else
    error "No JSON files found in $JSON_DIR/. Decompression may have failed."
fi

info "Combining all JSON fragments into one dataset..."
jq -s 'add' "$JSON_DIR"/*.json > combined_sms.json

success "Combined JSON created: combined_sms.json"
sleep 1

# =========================
# ⏳ Step 5: Sort + Normalize
# =========================
info "Sorting messages chronologically..."
jq 'sort_by(.date)' combined_sms.json > sorted_sms.json

info "Generating forensic summary..."

TOTAL_MSGS=$(jq 'length' sorted_sms.json)
UNIQUE_CONTACTS=$(jq '[.[].address] | unique | length' sorted_sms.json)

echo -e "${CYAN}Messages:${RESET} $TOTAL_MSGS"
echo -e "${CYAN}Contacts:${RESET} $UNIQUE_CONTACTS"

success "Sorted dataset ready: sorted_sms.json"
sleep 1

# =========================
# 💬 Step 6: Generate HTML Conversations
# =========================
info "Building conversation threads and HTML rendering..."

jq -r -f filter.jq sorted_sms.json > messages.html

success "HTML message blocks created: messages.html"
sleep 1

# =========================
# 🧩 Step 7: Inject into Viewer
# =========================
info "Injecting messages into viewer template..."

sed '/<!-- conversations inserted here -->/r messages.html' viewer.html > sms_viewer.html

success "Final viewer created: sms_viewer.html"
sleep 1

# =========================
# 🌐 Step 8: Open in Browser
# =========================
echo
read -rp "$(echo -e "${CYAN}${BOLD}[?]${RESET} Open SMS viewer in browser now? (Y/N): ")" choice

case "$choice" in
    [Yy]* )
        info "Opening sms_viewer.html in default browser..."
        xdg-open sms_viewer.html >/dev/null 2>&1 &
        success "Viewer launched."
        ;;
    [Nn]* )
        warn "Viewer not opened. You can open it manually anytime."
        ;;
    * )
        warn "Invalid input. Skipping browser launch."
        ;;
esac

echo
success "Pipeline complete. Your SMS data has been reconstructed into a browsable interface."
