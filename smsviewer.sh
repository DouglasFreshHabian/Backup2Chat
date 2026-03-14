#!/usr/bin/env bash

FILE="${1:-sms_backup.json}"

if [[ ! -f "$FILE" ]]; then
    echo "Usage: $0 sms_backup.json"
    exit 1
fi

command -v jq >/dev/null || { echo "jq is required"; exit 1; }

# Define colors
BLUE='\033[1;34m'
WHITE='\033[0;97m'
GRAY='\033[1;90m'
RESET='\033[0m'

# Extract unique contacts
CONTACT=$(jq -r '.[].address' "$FILE" | sort -u | \
    if command -v fzf >/dev/null; then
        fzf --prompt="Select contact: "
    else
        nl -w2 -s'. ' | less
    fi
)

[[ -z "$CONTACT" ]] && exit

# Clear the screen to prepare for the conversation display
clear

# Print the header immediately
echo "Conversation with: $CONTACT"
echo "-------------------------------------------"

# Print the conversation with colorized output
CONVERSATION=$(jq -r --arg c "$CONTACT" '
.[] 
| select(.address==$c)
| ((.date | tonumber)/1000 | strftime("%Y-%m-%d %H:%M"))
  + "  "
  + (if .type == "2" then "You:" else "Them:" end)
  + " "
  + (.body // "")
' "$FILE" | while IFS= read -r line; do
    # Split the line into timestamp and message
    TIMESTAMP="${line%%  *}"  # Everything before the first two spaces (timestamp)
    MESSAGE="${line#*  }"     # Everything after the first two spaces (message body)

    # Colorize the timestamp (Blue)
    TIMESTAMP_COLORED="${BLUE}${TIMESTAMP}${RESET}"

    # Colorize the message based on "You" or "Them"
    if [[ "$MESSAGE" == "You:"* ]]; then
        MESSAGE_COLORED="${WHITE}${MESSAGE}${RESET}"
    elif [[ "$MESSAGE" == "Them:"* ]]; then
        MESSAGE_COLORED="${GRAY}${MESSAGE}${RESET}"
    else
        MESSAGE_COLORED="${MESSAGE}"
    fi

    # Output the final colored line
    echo -e "${TIMESTAMP_COLORED}  ${MESSAGE_COLORED}"
done)

# Display conversation in less
echo "$CONVERSATION" | less -R

# Ask if user wants to export the conversation
read -p "Do you want to export this conversation to a file? (y/n): " EXPORT_CHOICE

if [[ "$EXPORT_CHOICE" =~ ^[Yy]$ ]]; then
    # Prompt for the file name
    read -p "Enter the file name (e.g., conversation.txt): " FILENAME

    # Export the conversation to the specified file
    echo "$CONVERSATION" > "$FILENAME"
    echo "Conversation exported to $FILENAME"
fi
