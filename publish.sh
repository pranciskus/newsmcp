#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# --- Package selection ---
usage() {
  echo "Usage: $0 <mcp-server|openclaw-plugin|skill|all>"
  echo ""
  echo "Packages:"
  echo "  mcp-server        Publish @newsmcp/server (npm + GitHub release + Smithery)"
  echo "  openclaw-plugin   Publish @newsmcp/openclaw (npm + GitHub release)"
  echo "  skill             Publish newsmcp skill (ClawHub)"
  echo "  all               Publish all packages"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

publish_mcp_server() {
  local PKG_DIR="packages/mcp-server"
  local VERSION NAME TAG
  VERSION=$(node -p "require('./${PKG_DIR}/package.json').version")
  NAME=$(node -p "require('./${PKG_DIR}/package.json').name")
  TAG="${NAME}@${VERSION}"

  echo "=== Publishing ${NAME}@${VERSION} ==="
  echo ""

  if git rev-parse "$TAG" &>/dev/null; then
    echo "SKIP: Tag ${TAG} already exists"
    return 0
  fi

  # Build
  echo "--- Building ---"
  rm -rf "${PKG_DIR}/dist"
  npm run build
  echo "OK: Build complete"
  echo ""

  # Test MCP handshake
  echo "--- Testing MCP server ---"
  RESPONSE=$(printf '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}\n' | node "${PKG_DIR}/dist/index.js" 2>/dev/null)
  if echo "$RESPONSE" | grep -q 'newsmcp'; then
    echo "OK: MCP server responds correctly"
  else
    echo "ERROR: MCP server did not respond as expected"
    echo "$RESPONSE"
    exit 1
  fi
  echo ""

  # npm publish
  echo "--- Publishing to npm ---"
  npm -w "${PKG_DIR}" publish --access public
  echo "OK: Published ${NAME}@${VERSION} to npm"
  echo ""

  # Git tag + push
  echo "--- Tagging ${TAG} ---"
  git tag -a "$TAG" -m "Release ${NAME}@${VERSION}"
  git push origin "$TAG"
  echo "OK: Tag ${TAG} pushed"
  echo ""

  # GitHub release
  echo "--- Creating GitHub release ---"
  gh release create "$TAG" \
    --title "${TAG}" \
    --notes "$(cat <<EOF
## ${NAME}@${VERSION}

World news for AI agents. Free, no API key.

### Install

\`\`\`bash
# Claude Desktop / Cursor
npx -y ${NAME}

# Claude Code
claude mcp add newsmcp -- npx -y ${NAME}

# Smithery
npx -y @smithery/cli install ${NAME} --client claude
\`\`\`

### Tools
- \`get_news\` — top events with topic/geo/time filtering
- \`get_news_detail\` — full event detail with context
- \`get_topics\` — available topic categories
- \`get_regions\` — available geographic regions

[Docs](https://newsmcp.io) &bull; [README](https://github.com/pranciskus/newsmcp#readme)
EOF
)"
  echo "OK: GitHub release created"
  echo ""

  # Smithery publish
  echo "--- Publishing to Smithery ---"
  if (cd "${PKG_DIR}" && npx -y @smithery/cli@latest publish) 2>&1; then
    echo "OK: Published to Smithery"
  else
    echo "WARN: Smithery publish failed (you may need to authenticate first)"
    echo "  Run: npx @smithery/cli@latest auth"
  fi
  echo ""

  echo "=== Done: ${TAG} ==="
  echo "  npm: https://www.npmjs.com/package/${NAME}"
  echo "  GitHub: https://github.com/pranciskus/newsmcp/releases/tag/${TAG}"
  echo "  Smithery: https://smithery.ai/server/${NAME}"
  echo ""
}

publish_openclaw_plugin() {
  local PKG_DIR="packages/openclaw-plugin"
  local VERSION NAME TAG
  VERSION=$(node -p "require('./${PKG_DIR}/package.json').version")
  NAME=$(node -p "require('./${PKG_DIR}/package.json').name")
  TAG="${NAME}@${VERSION}"

  echo "=== Publishing ${NAME}@${VERSION} ==="
  echo ""

  if git rev-parse "$TAG" &>/dev/null; then
    echo "SKIP: Tag ${TAG} already exists"
    return 0
  fi

  # Type-check
  echo "--- Type-checking ---"
  (cd "${PKG_DIR}" && npx tsc --noEmit)
  echo "OK: Type-check passed"
  echo ""

  # npm publish
  echo "--- Publishing to npm ---"
  npm -w "${PKG_DIR}" publish --access public
  echo "OK: Published ${NAME}@${VERSION} to npm"
  echo ""

  # Git tag + push
  echo "--- Tagging ${TAG} ---"
  git tag -a "$TAG" -m "Release ${NAME}@${VERSION}"
  git push origin "$TAG"
  echo "OK: Tag ${TAG} pushed"
  echo ""

  # GitHub release
  echo "--- Creating GitHub release ---"
  gh release create "$TAG" \
    --title "${TAG}" \
    --notes "$(cat <<EOF
## ${NAME}@${VERSION}

World news for AI agents. Free, no API key.

### Install

\`\`\`bash
# OpenClaw
openclaw plugins install ${NAME}
\`\`\`

### Tools
- \`get_news\` — top events with topic/geo/time filtering
- \`get_news_detail\` — full event detail with context
- \`get_topics\` — available topic categories
- \`get_regions\` — available geographic regions

[Docs](https://newsmcp.io) &bull; [README](https://github.com/pranciskus/newsmcp#readme)
EOF
)"
  echo "OK: GitHub release created"
  echo ""

  echo "=== Done: ${TAG} ==="
  echo "  npm: https://www.npmjs.com/package/${NAME}"
  echo "  GitHub: https://github.com/pranciskus/newsmcp/releases/tag/${TAG}"
  echo ""
}

publish_skill() {
  local SKILL_DIR="packages/skill"
  local SKILL_VERSION
  SKILL_VERSION=$(grep '^version:' "${SKILL_DIR}/SKILL.md" | head -1 | awk '{print $2}')

  echo "=== Publishing skill newsmcp@${SKILL_VERSION} to ClawHub ==="
  echo ""

  if ! command -v clawhub &>/dev/null; then
    echo "ERROR: clawhub CLI not found"
    exit 1
  fi

  # Verify auth
  echo "--- Checking ClawHub auth ---"
  clawhub whoami
  echo ""

  # Publish
  echo "--- Publishing to ClawHub ---"
  clawhub publish "${SKILL_DIR}" \
    --slug newsmcp \
    --name "newsmcp" \
    --version "${SKILL_VERSION}" \
    --changelog "Multi-event briefing fix: tool descriptions and skill instructions now enforce multi-story presentation"
  echo ""

  echo "=== Done: skill newsmcp@${SKILL_VERSION} ==="
  echo ""
}

# --- Preflight checks ---
echo "--- Preflight checks ---"

command -v npm &>/dev/null || { echo "ERROR: npm not found"; exit 1; }
command -v gh  &>/dev/null || { echo "ERROR: gh CLI not found (brew install gh)"; exit 1; }

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working tree is dirty. Commit or stash changes first."
  git status --short
  exit 1
fi

echo "OK: git clean"
echo ""

# --- Dispatch ---
case "$1" in
  mcp-server)
    publish_mcp_server
    ;;
  openclaw-plugin)
    publish_openclaw_plugin
    ;;
  skill)
    publish_skill
    ;;
  all)
    publish_mcp_server
    publish_openclaw_plugin
    publish_skill
    ;;
  *)
    echo "ERROR: Unknown package '$1'"
    usage
    ;;
esac
