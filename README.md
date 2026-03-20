# Backup2Chat
[![asciicast](https://asciinema.org/a/829241.svg)](https://asciinema.org/a/829241)

**Backup2Chat** is a guided workflow and toolkit for extracting SMS conversations from an Android device backup and transforming them into readable chat logs **in the terminal or in the browser**.

The project demonstrates the **entire pipeline** from:

```
Android device → ADB backup → decrypted archive → extracted JSON → terminal viewer / browser viewer
```

Along the way, you will learn how to:

* Extract encrypted Android backup files
* Decompress telephony backup data
* Analyze SMS data using `jq`
* Reconstruct conversations from raw datasets
* View chats in the terminal (fast, minimal analysis)
* Explore conversations in a browser (interactive, searchable, visual)

By the end of this guide you will understand the **entire manual workflow**, and then appreciate how the automation scripts:

* `smsviewer.sh` → terminal-based viewer
* `sms_to_Viewer.sh` → full interactive HTML viewer

transform the process into a **single-command pipeline**.

---

# Step 1 — Create the Android Backup

Enable **USB debugging** and connect the device.

Run:

```bash
adb backup -nocompress com.android.providers.telephony
```

This creates:

```
backup.ab
```

Your device will display a **backup confirmation screen**.

Tap **Back up my data**.

You may optionally add a password to encrypt the backup.

---

# Step 2 — Convert `.ab` to `.tar`

Android backups use a proprietary container format.

Use **Android Backup Extractor (ABE)**:

```bash
java -jar abe-540a57d.jar unpack backup.ab backup.tar
```

Example output:

```
This backup is encrypted, please provide the password
Password:
Calculated MK checksum: ...
0% ... 100%
306176 bytes written to backup.tar
```

You now have:

```
backup.tar
```

---

# Step 3 — Extract the Archive

```bash
tar -xvf backup.tar
```

Example structure:

```
apps/com.android.providers.telephony/_manifest
apps/com.android.providers.telephony/d_f/000000_sms_backup
apps/com.android.providers.telephony/d_f/000001_mms_backup
apps/com.android.providers.telephony/d_f/000002_mms_backup
apps/com.android.providers.telephony/d_f/000003_sms_backup
apps/com.android.providers.telephony/d_f/000004_sms_backup
```

These files contain compressed telephony backup data.

---

# Step 4 — Decompress the Backup Files

The `_backup` files are **zlib compressed**.

Run:

```bash
./decompress.sh
```

This extracts the contents into JSON fragments.

Next combine them:

```bash
jq -s 'add' *.json > sms_backup.json
```

You now have:

```
sms_backup.json
```

This file contains the **entire SMS dataset**.

---

# Understanding the JSON Structure

Each SMS entry looks similar to:

```json
{
  "address": "+15555555555",
  "body": "E 36th right?",
  "date": "1765057223938",
  "date_sent": "1765057224000",
  "read": "1",
  "recipients": ["+15555555555"],
  "self_phone": "+15555555555",
  "status": "-1",
  "subject": "proto:....",
  "type": "1"
}
```

Important fields:

| Field     | Meaning                  |
| --------- | ------------------------ |
| `address` | Phone number             |
| `body`    | Message text             |
| `date`    | Timestamp (milliseconds) |
| `type`    | Message direction        |

Direction values:

| type | meaning  |
| ---- | -------- |
| 1    | received |
| 2    | sent     |

---

# Exploring the Backup with `jq`
<details>
  
<summary>🖱 Click here to expand</summary>
Before using the chat viewer, we will manually analyze the dataset.

---

## Show Available Fields

```bash
jq '.[0] | keys' sms_backup.json
```

This shows all fields present in each message.

---

## Convert Timestamps to Human Readable Dates

The timestamps are in **milliseconds**, so divide by 1000.

```bash
jq '.[] | {date: (.date|tonumber/1000|strftime("%Y-%m-%d %H:%M:%S")), body, address}' sms_backup.json
```

Example output:

```json
{
  "date": "2025-12-06 15:00:23",
  "body": "Fresh Forensics?",
  "address": "+15555555555"
}
```

---

## Display Messages as a Chat Log

```bash
jq -r '.[] |
  ((.date|tonumber/1000|strftime("%Y-%m-%d %H:%M")) +
  " | " +
  (if .type=="1" then .address else "Me" end) +
  ": " +
  .body)' sms_backup.json
```

Example:

```
2025-12-06 14:59 | +15555555555: Where are you?
2025-12-06 15:00 | Me: Defcon, Lock Picking Village!
```

---

## Filter Messages From One Contact

```bash
jq '.[] | select(.address=="+15555555555")' sms_backup.json
```

---

## Remove Unnecessary Metadata

```bash
jq 'del(.[] .subject)' sms_backup.json > sms_clean.json
```

---

## Export Messages to CSV

```bash
jq -r '.[] |
  [.date, .address, .body] |
  @csv' sms_backup.json
```

---

## Count Messages Per Contact

```bash
jq -r '.[].address' sms_backup.json | sort | uniq -c | sort -nr
```

Example output:

```
452 +15555555555
317 +11234567890
205 +19999999999
```
---
</details>

# Viewing Conversations Manually

Using the commands above, you can manually reconstruct conversations.

However, doing this repeatedly becomes tedious.

This is where **`smsviewer.sh`** comes in.

---

# Terminal Chat Viewer `smsviewer.sh`

`smsviewer.sh` provides an interactive way to browse conversations.

Features:

* Accepts an **SMS backup JSON file**
* Extracts **all unique contacts**
* Lets the user **select a contact**
* Displays the conversation **chronologically**
* Opens the chat in a **scrollable pager**
* Colorizes **You vs Them**
* Optional **chat export**

---

# Usage

```bash
./smsviewer.sh sms_backup.json
```

Example session:

```
Conversation with: +15555555555
-------------------------------------------
Do you want to export this conversation to a file? (y/n): y
Enter the file name (e.g., conversation.txt): convo.txt
Conversation exported to convo.txt
```

Example conversation output:

```
2026-01-28 13:13  You: Morning...
2026-01-28 13:19  Them: Morning hope ur day is going ok so far
2026-01-28 14:01  You: I'm so bored I could fall asleep 🥱
2026-01-28 14:02  You: Are you on the computer?
2026-01-28 14:02  Them: Of course, I live on the computer!
2026-01-28 14:13  You: Congratulations on hitting 15,000 subscribers! 🎉
```

The viewer automatically:

* Converts timestamps
* Orders messages chronologically
* Formats the conversation
* Colorizes message direction

---

## License

MIT License — feel free to fork, modify, and adapt for demos or educational content.

---

### ☕ Support This Project

If **Backup2Chat** helps you better analyze Android SMS backups, consider supporting continued development:

<p align="center">
  <a href="https://www.buymeacoffee.com/dfreshZ" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
</p>

<!-- 
 _____              _       _____                        _          
|  ___| __ ___  ___| |__   |  ___|__  _ __ ___ _ __  ___(_) ___ ___ ™️
| |_ | '__/ _ \/ __| '_ \  | |_ / _ \| '__/ _ \ '_ \/ __| |/ __/ __|
|  _|| | |  __/\__ \ | | | |  _| (_) | | |  __/ | | \__ \ | (__\__ \
|_|  |_|  \___||___/_| |_| |_|  \___/|_|  \___|_| |_|___/_|\___|___/
        freshforensicsllc@tuta.com Fresh Forensics, LLC 2026 -->
