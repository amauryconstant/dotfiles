# Vendored Subtrees (`_ai/`)

`_ai/` holds read-only reference copies of upstream projects, vendored via
`git subtree` so their real source/API is available in-repo — for research, and
for AI assistants to verify APIs against actual code instead of guessing.

## How `_ai/` Is Treated

**It is not ours.** Repo tooling is configured to leave it alone:

| Concern | Where it's excluded |
|---------|---------------------|
| chezmoi (never deployed to `~`) | `.chezmoiignore` → `_ai/` |
| shellcheck / shfmt (whole-repo) | `.mise/config.toml` `format:sh`, `.mise/tasks/lint/sh.sh` |
| pre-commit shellcheck (staged) | `.mise/tasks/lint/staged.sh` (`grep -v '^_ai/'`) |
| chezmoi destroy (staged deletions) | `.mise/tasks/destroy/staged.sh` (`grep -v '^_ai/'`) |
| markdownlint | `.markdownlint-cli2.jsonc` ignores |
| prettier | `.prettierignore` |
| GitHub language stats / diffs | `.gitattributes` → `linguist-vendored` + `linguist-generated` |

**Rules**: never hand-edit, lint, or reformat vendored files. Change them only by
re-pulling from upstream. Treat `_ai/` as a read-only reference.

## Vendored Subtrees

| Prefix | Upstream | Branch | Purpose |
|--------|----------|--------|---------|
| `_ai/quickshell` | https://git.outfoxxed.me/quickshell/quickshell | `master` | Quickshell (QtQuick/QML shell framework) source — the API reference behind `_research/QUICKSHELL_QML_API.md` and `.claude/rules/quickshell-qml.md`, both of which cite `_ai/quickshell/src/` paths for facts that are only readable in the C++ |
| `_ai/dcli` | https://gitlab.com/theblackdon/dcli | `main` | dcli (declarative Arch package manager, NixOS-inspired) source — reference for `system/package-manager` (which cites it as inspiration) |

## Managing Subtrees

Add a new subtree (squashed, so upstream history stays out of this repo's log):

```bash
git subtree add --prefix=_ai/<name> <remote-url> <branch> --squash
```

Update an existing subtree to the latest upstream:

```bash
git subtree pull --prefix=_ai/<name> <remote-url> <branch> --squash
```

Remove a subtree:

```bash
git rm -r _ai/<name> && git commit -m "Remove _ai/<name> vendored subtree"
```

When adding or removing a subtree, update the table above.

## What is deliberately NOT vendored

**Omarchy.** It runs a Quickshell shell of its own (185 files, 104 of them QML, under `shell/`), so
it is read constantly as comparison material for our surfaces — but it is read **in place**, from
the plain checkout at `~/Projects/_external/omarchy` that the `omarchy-release-researcher` agent
already works against. A subtree would duplicate 2.1 MB of `shell/` for no access the checkout does
not already have, and unlike `_ai/quickshell` there is no API to verify against — the value is the
**diff between releases**, which is what `/omarchy-changes` reads and a `--squash` subtree flattens
away. Decision recorded 2026-09-13; the backlog it feeds is `_plans/OMARCHY.md`, the per-release
records are `_research/omarchy/`.

