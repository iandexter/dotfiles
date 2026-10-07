#!/usr/bin/env bash
# Gate the Artifact tool's PUBLISH action behind an explicit opt-in.
# Called as a PreToolUse hook for the Artifact tool.
#
# Why: Artifact publish sends a page to a public claude.ai URL. For branded or
# third-party content (e.g. a real firm's website) that can read as impersonation,
# and the model can invoke it on its own initiative. Publishing should be a
# deliberate, opt-in act — not a side effect. `action: "list"` is read-only and
# always allowed.
#
# To allow a publish: run the session with ALLOW_ARTIFACT_PUBLISH=1 in the
# environment, or unset the hook temporarily.

action=$(jq -r '.tool_input.action // .action // "publish"' 2>/dev/null)

# Read-only enumeration is harmless.
if [[ "$action" == "list" ]]; then
  exit 0
fi

if [[ "${ALLOW_ARTIFACT_PUBLISH:-0}" == "1" ]]; then
  exit 0
fi

echo "Blocked: Artifact publish is gated. Publishing sends the page to a public URL, which can read as impersonation for branded/third-party content. If you intend to publish, re-run with ALLOW_ARTIFACT_PUBLISH=1 set in the environment." >&2
exit 2
