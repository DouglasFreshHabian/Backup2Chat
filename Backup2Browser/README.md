# View Android SMS Backup In The Browser

### (Using jq + HTML + JavaScript)

---

## Step 1 — Sort Messages Chronologically

SMS backups often store timestamps as **Unix time in milliseconds**, and sometimes messages aren’t perfectly ordered.

We can sort them using `jq`.

```bash
jq 'sort_by(.date)' sms_backup.json > sorted_sms.json
```

This creates a new file called:

```
sorted_sms.json
```

Now every message is arranged in chronological order.

---

## Step 2 — Convert Messages Into HTML Conversations

Next we transform the JSON messages into HTML.

We also **group messages by phone number**, which creates individual conversation threads.

Each message becomes a styled chat bubble that includes:

* timestamp
* message text
* sent / received styling

Run this command:

```bash
jq -r '
group_by(.address)[] |

"<div class=\"conversation\" data-number=\"" + .[0].address + "\" style=\"display:none\">" +

"<h2>Conversation with " + .[0].address + "</h2>" +

"<div class=\"chat\">" +

(
  map(
    "<div class=\"" +
    (if .type=="1" then "msg received" else "msg sent" end) +
    "\">" +

    "<span class=\"time\">" +
    (.date|tonumber/1000|strftime("%Y-%m-%d %H:%M")) +
    "</span>" +

    "<p>" +
    (.body
      | gsub("&";"&amp;")
      | gsub("<";"&lt;")
      | gsub(">";"&gt;")
    ) +

    "</p></div>"
  )
  | join("")
)

+

"</div></div>"

' sorted_sms.json > messages.html
```

This generates a file called:

```
messages.html
```

Each conversation is now wrapped inside a container like this:

```html
<div class="conversation" data-number="+1234567890">
```

This structure allows the viewer to dynamically switch between conversations.

---

## Step 3 — Create the Interactive Viewer

Next we create the interface that will display the conversations.

Create a file called:

```
viewer.html
```

This file contains the layout, styling, and JavaScript features.

The viewer includes:

```
• Sidebar with conversation threads + message counts  
• Chat-style message bubbles (sent / received)  
• Automatic conversation statistics  
• Live keyword and phone number search  
• Dark mode toggle  
• Export individual conversations as HTML  
```

---

## Step 4 — Insert Messages Into the Viewer

Now we insert the generated conversations into the viewer template.

Instead of simply appending the file, we insert the messages at the correct location inside the HTML layout.

Run:

```bash
sed '/<!-- conversations inserted here -->/r messages.html' viewer.html > sms_viewer.html
```

This creates the final viewer file:

```
sms_viewer.html
```

---

## Step 5 — Open the Chat Viewer

Now open the file in your browser.

```bash
xdg-open sms_viewer.html
```

You now have a **fully interactive SMS archive viewer** and since everything runs in **static HTML**, the viewer works on almost any system.

---

## Step 6 — Fully Automate The Entire Workflow

Manually running each step works — but it’s slow, repetitive, and easy to mess up.

So we built a script that handles **everything from raw Android backup → interactive viewer** in one command.

The script is called:

```bash
sms_to_Viewer.sh
```

---

## What The Script Does

Starting from:

```bash
backup.ab
```

The script automatically:

1. Extracts the Android backup
2. Decompresses the archive
3. Parses the SMS database
4. Converts messages into JSON
5. Sorts messages chronologically
6. Builds HTML conversation threads
7. Injects them into the viewer
8. Outputs a ready-to-open interactive file

End result:

```bash
sms_viewer.html
```

---

## Required File Structure

For the script to work correctly, all required files must exist in the **same directory**.

Your folder should look like this:

```bash
project/
├── backup.ab
├── abe.jar
├── decompress.sh
├── filter.jq
├── sms_to_Viewer.sh
├── viewer.html
```

---

## Run The Script

Once everything is in place, simply run:

```bash
chmod +x sms_to_Viewer.sh
./sms_to_Viewer.sh
```

---

## Script Execution Output

When you run the script, you’ll see a full step-by-step breakdown of what’s happening internally:

```bash
[+] Decompression complete. JSON files generated.
[+] Found JSON files in Decompressed/
[*] Combining all JSON fragments into one dataset...
[+] Combined JSON created: combined_sms.json
[*] Sorting messages chronologically...
[*] Generating forensic summary...
Messages: 3869
Contacts: 42
[+] Sorted dataset ready: sorted_sms.json
[*] Building conversation threads and HTML rendering...
[+] HTML message blocks created: messages.html
[*] Injecting messages into viewer template...
[+] Final viewer created: sms_viewer.html

[?] Open SMS viewer in browser now? (Y/N):
```

---

## Interactive Prompt

At the end of execution, the script gives you a choice:

```
[?] Open SMS viewer in browser now? (Y/N):
```

* Press **Y** → instantly opens the viewer
* Press **N** → saves everything for later use

---

## Final Output

The script generates:

```
sms_viewer.html
```

This is your **fully interactive SMS analysis interface**, ready to open in any browser.

---
