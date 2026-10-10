#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
cd "$(dirname "$0")" || exit 1
bin="./vision_ocr"
if [ ! -x "$bin" ] || [ vision_ocr.swift -nt "$bin" ]; then
  swiftc -O vision_ocr.swift -o "$bin" -framework Vision -framework AppKit -framework ImageIO -framework CoreGraphics 2>/dev/null
fi

mode="$1"
TMP_IMG="/tmp/ocr_snap_$$.png"

# If mode is "cap", "screen", "hotkey", or if clipboard has no image -> interactive capture
if [ "$mode" = "cap" ] || [ "$mode" = "screen" ] || [ "$mode" = "hotkey" ] || ! "$bin" --has-image 2>/dev/null; then
  # Direct capture to temporary file: bypasses Clop completely, 0 clipboard image pollution
  screencapture -i "$TMP_IMG"
  if [ ! -f "$TMP_IMG" ]; then
    # User pressed Escape or canceled screencapture
    exit 0
  fi
  text="$("$bin" "$TMP_IMG" 2>/dev/null)"
  rm -f "$TMP_IMG"
else
  # Clipboard already has an image, and user typed 'ocr' without 'cap'
  text="$("$bin" 2>/dev/null)"
fi

if [ -z "$text" ]; then
  printf '%s' '{"alfredworkflow":{"variables":{"title":"Vision OCR","content":"No text detected"}}}'
  exit 0
fi

# Cleanly copy recognized text to clipboard (0 Clop interference, 0 delay)
printf '%s' "$text" | pbcopy

/usr/bin/python3 -c 'import json,sys;print(json.dumps({"alfredworkflow":{"variables":{"title":"✅ Vision OCR Copied to Clipboard","content":(sys.argv[1] or "(No text recognized)")}}}))' "$text"
