#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

echo "🔨 Compiling Swift binary..."
swiftc -O Workflow/vision_ocr.swift -o Workflow/vision_ocr \
  -framework Vision -framework AppKit -framework ImageIO -framework CoreGraphics

echo "🧹 Stripping quarantine & extended attributes..."
xattr -c Workflow/* 2>/dev/null || true

echo "📦 Packaging Vision-OCR.alfredworkflow..."
rm -f Vision-OCR.alfredworkflow
(cd Workflow && zip -r -X ../Vision-OCR.alfredworkflow . -x "*.DS_Store")

echo "✅ Package created successfully!"
ls -lh Vision-OCR.alfredworkflow
shasum -a 256 Vision-OCR.alfredworkflow
