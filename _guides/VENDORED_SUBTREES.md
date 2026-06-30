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
| `_ai/quickshell` | https://git.outfoxxed.me/quickshell/quickshell | `master` | Quickshell (QtQuick/QML shell framework) source — API reference for `_research/QUICKSHELL_DESKTOP_RESEARCH.md` |

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
