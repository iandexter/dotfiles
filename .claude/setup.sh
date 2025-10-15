#!/usr/bin/env bash
# Aggregate generic + domain-specific Claude configs

set -euo pipefail

DOTFILES_CLAUDE="$HOME/etc/dotfiles/.claude"
LOCAL_CLAUDE="$HOME/.local/.claude"
TARGET="$HOME/.claude"

echo "Aggregating Claude Code configuration..."

# Backup existing config if not already a backup
if [[ -d "$TARGET" && ! -L "$TARGET" ]]; then
  BACKUP="${TARGET}.backup.$(date +%Y%m%d_%H%M%S)"
  echo "Backing up existing ~/.claude to $BACKUP"
  mv "$TARGET" "$BACKUP"
fi

# Create fresh target directory
rm -rf "$TARGET"
mkdir -p "$TARGET/commands" "$TARGET/plugins"

# Merge CLAUDE.md: general + domain-specific
echo "Merging CLAUDE.md..."
cat "$DOTFILES_CLAUDE/CLAUDE.md" > "$TARGET/CLAUDE.md"
if [[ -f "$LOCAL_CLAUDE/CLAUDE_DOMAIN_SPECIFIC.md" ]]; then
  echo "" >> "$TARGET/CLAUDE.md"
  cat "$LOCAL_CLAUDE/CLAUDE_DOMAIN_SPECIFIC.md" >> "$TARGET/CLAUDE.md"
  echo "  ✓ Added domain-specific guidelines"
else
  echo "  ℹ No domain-specific extensions found"
fi

# Merge settings.json using jq
echo "Merging settings.json..."
if [[ -f "$LOCAL_CLAUDE/settings.databricks.json" ]]; then
  jq -s '.[0] * .[1] | .permissions.allow = (.[0].permissions.allow + .[1].permissions.allow | unique)' \
    "$DOTFILES_CLAUDE/settings.base.json" \
    "$LOCAL_CLAUDE/settings.databricks.json" \
    > "$TARGET/settings.json"
  echo "  ✓ Merged with domain-specific permissions"
else
  cp "$DOTFILES_CLAUDE/settings.base.json" "$TARGET/settings.json"
  echo "  ℹ Using base settings only"
fi

# Symlink commands from both locations
echo "Linking commands..."
GENERIC_COUNT=0
DOMAIN_COUNT=0

for cmd in "$DOTFILES_CLAUDE/commands/"*.md; do
  if [[ -f "$cmd" ]]; then
    ln -sf "$cmd" "$TARGET/commands/"
    ((GENERIC_COUNT++))
  fi
done

if [[ -d "$LOCAL_CLAUDE/commands" ]]; then
  for cmd in "$LOCAL_CLAUDE/commands/"*.md; do
    if [[ -f "$cmd" ]]; then
      ln -sf "$cmd" "$TARGET/commands/"
      ((DOMAIN_COUNT++))
    fi
  done
fi

echo "  ✓ Linked ${GENERIC_COUNT} generic + ${DOMAIN_COUNT} domain-specific commands"

# Copy plugins config
cp "$DOTFILES_CLAUDE/plugins/config.json" "$TARGET/plugins/config.json"

echo ""
echo "✓ Claude config aggregated at $TARGET"
echo ""
echo "Commands available:"
ls -1 "$TARGET/commands/" | sed 's/\.md$//' | sed 's/^/  \// '
