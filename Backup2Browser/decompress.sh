#!/bin/bash

# Folder containing your backups
BACKUP_DIR="apps/com.android.providers.telephony/d_f"

# Output folder for decompressed json files
OUTPUT_DIR="Decompressed"
mkdir -p "$OUTPUT_DIR"

# Loop over each backup file
for f in "$BACKUP_DIR"/*_backup; do
    # Get base filename without path
    filename=$(basename "$f")

    # Create output filename with .json
    out="$OUTPUT_DIR/${filename}.json"

    # Decompress using Python (zlib)
    python3 - <<EOF
import zlib
with open("$f", "rb") as fin:
    data = fin.read()
try:
    decompressed = zlib.decompress(data)
except Exception as e:
    print(f"Failed to decompress {f}: {e}")
    exit(1)
with open("$out", "wb") as fout:
    fout.write(decompressed)
EOF

    echo "Decompressed $f -> $out"
done
