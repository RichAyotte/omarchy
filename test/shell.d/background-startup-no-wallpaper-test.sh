#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"
require_compositor "background startup without a wallpaper"
require_command quickshell

run_case() {
  local variant="$1" stage output
  stage=$(mktemp -d)
  mkdir -p "$stage/bin" "$stage/home/.local/state/omarchy/current"
  if [[ $variant == "a dangling link" ]]; then
    ln -s "$stage/deleted.png" "$stage/home/.local/state/omarchy/current/background"
  fi
  for component in Commons Ui services; do
    ln -s "$ROOT/shell/$component" "$stage/$component"
  done
  ln -s "$ROOT/shell/plugins/background" "$stage/background"
  cp "$SHELL_TEST_DIR/fixtures/background-startup-no-wallpaper/shell.qml" "$stage/shell.qml"
  cat >"$stage/bin/omarchy-theme-bg-boot-intro" <<'SH'
#!/bin/bash
exit 0
SH
  chmod +x "$stage/bin/omarchy-theme-bg-boot-intro"

  # Past the fixture's own 12 s backstop, so its failure message is what reports a hang.
  output=$(HOME="$stage/home" PATH="$stage/bin:$PATH" timeout 14 quickshell -p "$stage" --no-color 2>&1) || {
    rm -rf "$stage"
    fail "startup with $variant exits cleanly" "$output"
  }
  rm -rf "$stage"
  [[ $output == *"RESULT pass"* ]] || fail "a desktop with $variant fades in before the startup deadline" "$output"
  if rg -q 'RESULT fail|ReferenceError|TypeError|Unable to assign|Binding loop' <<<"$output"; then
    fail "startup with $variant has no QML errors" "$output"
  fi
  pass "a desktop with $variant fades in before the startup deadline"
}

run_case "a dangling link"
run_case "no link"
