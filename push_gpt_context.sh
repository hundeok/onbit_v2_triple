#!/bin/bash
set -e

mkdir -p gpt_context

export KST_DATE=$(TZ=Asia/Seoul date "+%Y-%m-%d %H:%M:%S KST")

## 📄 Create context.md (human-readable)
{
  echo "# 🧠 GPT Context Snapshot"
  echo "Generated at: $KST_DATE"
  [ -f README.md ] && { printf "\n## 📄 README\n"; cat README.md; }
  [ -f docs/CHANGELOG.md ] && { printf "\n\n## 📝 Changelog\n"; cat docs/CHANGELOG.md; }
  [ -f docs/module_summary.md ] && { printf "\n\n## 📦 Module Summary\n"; cat docs/module_summary.md; }
} > gpt_context/context.md

## 🤖 Create context.json (OpenAI API format)
{
  echo "{"
  echo "  \"model\": \"gpt-4o\","
  echo "  \"messages\": ["
  echo "    { \"role\": \"system\", \"content\": \"You are a senior developer. Analyze and retain the project context for future interactions.\" },"

  first=true

  if [ -f README.md ]; then
    $first || echo ","
    echo "    { \"role\": \"user\", \"content\": \"## 📄 README\" },"
    echo "    { \"role\": \"user\", \"content\": $(jq -Rs . < README.md) }"
    first=false
  fi

  if [ -f docs/CHANGELOG.md ]; then
    $first || echo ","
    echo "    { \"role\": \"user\", \"content\": \"## 📝 Changelog\" },"
    echo "    { \"role\": \"user\", \"content\": $(jq -Rs . < docs/CHANGELOG.md) }"
    first=false
  fi

  if [ -f docs/module_summary.md ]; then
    $first || echo ","
    echo "    { \"role\": \"user\", \"content\": \"## 📦 Module Summary\" },"
    echo "    { \"role\": \"user\", \"content\": $(jq -Rs . < docs/module_summary.md) }"
    first=false
  fi

  echo ","
  echo "    { \"role\": \"user\", \"content\": \"🕒 Generated at: $KST_DATE\" }"
  echo "  ]"
  echo "}"
} > gpt_context/context.json

## 🔐 Git push with GH_TOKEN (same as GitHub Actions)
git config --global user.name "hundeok"
git config --global user.email "hundeok@users.noreply.github.com"
git remote set-url origin https://hundeok:${GH_TOKEN}@github.com/hundeok/onbit_v2_triple

git add gpt_context/context.md gpt_context/context.json
git commit -m "docs: update GPT context snapshot" || echo "No changes to commit"
git push origin main
