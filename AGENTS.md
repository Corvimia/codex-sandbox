# AGENTS

Project guidance for Codex working in this repo.

## Workflow
- Default branch: `main`.
- Branch naming: prefix with conventional commit type, e.g. `feat/short-topic`, `fix/issue-id`, `chore/tooling`.
- Conventional commits required for all commit messages.
- PR titles must follow the same conventional commit format as commits.
- PR descriptions should use Markdown formatting.

## Conventional commit types
Use one of: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `build`, `perf`, `style`, `revert`.
Scopes are optional (e.g. `feat(sandbox): add setup helper`).

## Testing
- No automated tests required right now.

## "Send it" automation
If the user says "send it":
- Create a branch if not already on one (following the naming convention).
- Commit with a conventional commit message.
- Push the branch.
- If no PR exists, open a PR targeting `main` using `gh`, with a one-paragraph Markdown summary.
- If a PR already exists for the branch, just commit and push; do not create a new PR.
