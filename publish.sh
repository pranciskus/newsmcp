#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PKG_DIR="packages/mcp-server"
VERSION=$(node -p "require('./${PKG_DIR}/package.json').version")
NAME=$(node -p "require('./${PKG_DIR}/package.json').name")
TAG="v${VERSION}"

echo "=== Publishing ${NAME}@${VERSION} ==="
echo ""

# 1. Preflight checks
echo "--- Preflight checks ---"

if ! command -v npm &>/dev/null; then
  echo "ERROR: npm not found" && exit 1
fi
if ! command -v gh &>/dev/null; then
  echo "ERROR: gh CLI not found (brew install gh)" && exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working tree is dirty. Commit or stash changes first."
  git status --short
  exit 1
fi

if git rev-parse "$TAG" &>/dev/null; then
  echo "ERROR: Tag ${TAG} already exists. Bump version in ${PKG_DIR}/package.json first."
  exit 1
fi

echo "OK: git clean, tag ${TAG} available"
echo ""

# 2. Build
echo "--- Building ---"
rm -rf "${PKG_DIR}/dist"
npm run build
echo "OK: Build complete"
echo ""

# 3. Test MCP handshake
echo "--- Testing MCP server ---"
RESPONSE=$(printf '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}},"id":1}\n' | node "${PKG_DIR}/dist/index.js" 2>/dev/null)
if echo "$RESPONSE" | grep -q '"newsmcp"'; then
  echo "OK: MCP server responds correctly"
else
  echo "ERROR: MCP server did not respond as expected"
  echo "$RESPONSE"
  exit 1
fi
echo ""

# 4. npm publish
echo "--- Publishing to npm ---"
npm -w "${PKG_DIR}" publish --access public
echo "OK: Published ${NAME}@${VERSION} to npm"
echo ""

# 5. Git tag + push
echo "--- Tagging ${TAG} ---"
git tag -a "$TAG" -m "Release ${VERSION}"
git push origin "$TAG"
echo "OK: Tag ${TAG} pushed"
echo ""

# 6. GitHub release
echo "--- Creating GitHub release ---"
gh release create "$TAG" \
  --title "${TAG}" \
  --notes "$(cat <<EOF
## ${VERSION}

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

# 7. Smithery publish
echo "--- Publishing to Smithery ---"
if (cd "${PKG_DIR}" && npx -y @smithery/cli@latest publish) 2>&1; then
  echo "OK: Published to Smithery"
else
  echo "WARN: Smithery publish failed (you may need to authenticate first)"
  echo "  Run: npx @smithery/cli@latest auth"
fi
echo ""

echo "=== Done ==="
echo "  npm: https://www.npmjs.com/package/${NAME}"
echo "  GitHub: https://github.com/pranciskus/newsmcp/releases/tag/${TAG}"
echo "  Smithery: https://smithery.ai/server/${NAME}"
