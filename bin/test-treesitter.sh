#!/usr/bin/env bash
# Test that treesitter queries are valid and language injection works
# for fenced code blocks (critical for markview.nvim).
#
# Run after `nix build .#darwinConfigurations.SungkyungM1X.system`
# and before `darwin-rebuild switch` to catch query errors early.

set -euo pipefail

TESTFILE=$(mktemp /tmp/treesitter-test-XXXXXX.md)
trap 'rm -f "$TESTFILE"' EXIT

cat > "$TESTFILE" << 'MARKDOWN'
# Treesitter Query Test

```lua
local M = {}
function M.setup() print("hello") end
return M
```

```python
def hello():
    return "world"
```

```bash
echo "hello world"
```

```nix
{ pkgs, ... }: { environment.systemPackages = [ pkgs.vim ]; }
```

```haskell
main :: IO ()
main = putStrLn "hello"
```

```typescript
const greet = (name: string): string => `Hello, ${name}`;
```
MARKDOWN

echo "Testing treesitter queries and language injection..."

OUTPUT=$(nvim --headless \
  -c "edit $TESTFILE" \
  -c 'lua vim.treesitter.start(0)' \
  -c 'sleep 1' \
  -c 'lua local parser = vim.treesitter.get_parser(0); print("parser: " .. parser:lang()); for _, child in pairs(parser:children()) do print("  injection: " .. child:lang()) end' \
  -c 'redir => g:msgs | silent messages | redir END' \
  -c 'lua for _, line in ipairs(vim.split(vim.g.msgs, "\n")) do if line:match("Error") or line:match("Invalid") then print("QUERY_ERROR: " .. line) end end' \
  -c 'qa' 2>&1)

ERRORS=$(echo "$OUTPUT" | grep "QUERY_ERROR:" || true)
INJECTIONS=$(echo "$OUTPUT" | grep "injection:" || true)

if [ -n "$ERRORS" ]; then
  echo "FAIL: treesitter query errors detected:"
  echo "$ERRORS"
  exit 1
fi

if [ -z "$INJECTIONS" ]; then
  echo "FAIL: no language injections found in fenced code blocks."
  echo "  markview.nvim syntax highlighting will not work."
  exit 1
fi

echo "PASS: treesitter queries valid, injections working:"
echo "$INJECTIONS"
