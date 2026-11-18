# yay-ai-review

A [yay](https://github.com/Jguer/yay) hook that has an AI model review AUR
build file changes before each build.

For every AUR package about to be built, the diff of its build files since the
last reviewed commit goes to the model together with the package metadata. The
model answers `OK` or `QUESTIONABLE`:

- `OK`: the build proceeds.
- `QUESTIONABLE`, or the review failed: the justification is printed and you
  review the diff and approve or reject manually.

This replaces yay's diff menu. It is a filter for routine updates, not a
guarantee; a model can miss things.

## Install

Requires yay >= 13.0, `jq`, and [Claude Code](https://claude.com/claude-code)
or [Codex CLI](https://github.com/openai/codex), logged in.

```sh
git clone https://github.com/schuay/yay-ai-review
yay-ai-review/install.sh
```

This adds one line to `~/.config/yay/init.lua` that loads the hook from the
clone. `install.sh -u` removes it.

## Configuration

The backend is detected if exactly one of `claude` and `codex` is installed.
Otherwise set it in `~/.config/yay/ai-review.conf` or the environment:

```sh
YAY_AI_REVIEW_BACKEND=claude   # or codex
YAY_AI_REVIEW_MODEL=...        # default: claude-opus-5-5 / codex default
YAY_AI_REVIEW_EFFORT=...       # default: high
```

The codex backend is best-effort and less tested than the claude one.

## License

MIT
