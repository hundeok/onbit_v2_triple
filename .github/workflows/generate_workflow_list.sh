#!/bin/bash

WORKFLOW_DIR=".github/workflows"
OUTPUT_FILE="docs/workflows.md"

echo "# ⚙️ GitHub Workflows Summary" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "> 자동 생성된 워크플로우 요약. 이름, 파일명, 트리거 포함." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for file in "$WORKFLOW_DIR"/*.yml; do
  filename=$(basename "$file")
  name=$(grep -m 1 '^name:' "$file" | cut -d ':' -f2- | xargs)

  echo "### ✅ $filename" >> "$OUTPUT_FILE"
  echo "- **name**: $name" >> "$OUTPUT_FILE"
  echo "- **triggers**:" >> "$OUTPUT_FILE"

  awk '
    BEGIN { in_on=0; context="" }
    /^on:/ { in_on=1; next }
    /^[^ ]/ { in_on=0 }
    in_on && /workflow_dispatch/ { print "  - workflow_dispatch"; next }
    in_on && /push:/ { context="push"; next }
    in_on && /pull_request:/ { context="pull_request"; next }
    in_on && /branches:/ {
      gsub(/[\[\]]/, "", $2);
      print "  - " context ": [" $2 "]";
      context="";
    }
  ' "$file" >> "$OUTPUT_FILE"

  echo "" >> "$OUTPUT_FILE"
done

echo "✅ docs/workflows.md 생성 완료"
