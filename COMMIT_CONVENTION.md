# Git Commit Convention

This document defines the commit message style for this project, based on
[Conventional Commits](https://www.conventionalcommits.org/).

---

## Format

```
<type>(<scope>): <Subject>

<body>

<footer>
```

---

## Subject Line

```
type(scope): Subject with capital first letter
```

| Rule | Example |
|------|---------|
| Capitalize first word | `feat(auth): Add login validation` ✅ |
| Imperative mood | `Fix bug` ✅ not `Fixed bug` ❌ |
| No period at end | `Add feature` ✅ not `Add feature.` ❌ |
| Max 50 chars (soft limit) | Keep it concise |
| Max 72 chars (hard limit) | GitHub truncates beyond this |

---

## Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `docs` | Documentation only |
| `test` | Adding or updating tests |
| `chore` | Maintenance (deps, config, build) |
| `style` | Formatting, whitespace (no code change) |
| `perf` | Performance improvement |

---

## Scope (Preferred)

The scope provides context about what part of the codebase is affected.

**Why use scope?**
- Instantly know which area changed without reading the body
- Makes `git log --oneline` scannable
- Helps when filtering commits (e.g., `git log --grep="(auth)"`)

**Examples:**
- `feat(auth):` - Authentication module
- `fix(api):` - API layer
- `refactor(users):` - Users module
- `docs(readme):` - README file

Use lowercase. Keep it short (one word preferred).

---

## Body

- Separate from subject with a blank line
- Wrap lines at **72 characters**
- Explain **what** changed and **why** (not how - the code shows how)
- Use bullet points with `-` for lists

### Example

```
feat(search): Implement case-insensitive search

- Add word_text_search field for efficient case-insensitive queries
- Update search DAL to use dedicated search fields
- Preserve original capitalization for display

This enables users to search for "javascript" and find "JavaScript"
entries while maintaining the original capitalization in the UI.
```

---

## Body Sections (For Large Changes)

For significant refactors, use markdown headers:

```
refactor(word): Modernize word module architecture

## Changes
- Split monolithic service into focused components
- Add Pydantic models for type safety
- Implement factory pattern for business logic

## Architecture Improvements
- Separation of concerns between layers
- Consistent patterns across all modules

## Backward Compatibility
- All existing API routes work unchanged
- No breaking changes to external interfaces
```

---

## Footer (Optional)

Reference issues or breaking changes:

```
feat(api): Add user deletion endpoint

BREAKING CHANGE: Removed deprecated /users/remove endpoint

Fixes: #123
Closes: #456
```

---

## Quick Reference

```
50 chars max for subject ----------------------->|
72 chars max for body ------------------------------------------------->|
```

### Good Examples

```
feat(auth): Add JWT refresh token support

- Implement token refresh endpoint
- Add refresh token to login response
- Store refresh tokens with expiration

This allows users to stay logged in without re-authenticating.
```

```
fix(leaderboard): Exclude admin users from results

Filter the leaderboard query to remove admin accounts, ensuring
rankings reflect regular users only.

Fixes: #89
```

```
chore(deps): Update Flask to 3.0.0
```

### Bad Examples

```
fixed the bug          # No type, not capitalized, vague
```

```
feat: added new feature.   # Past tense, period, vague
```

```
FEAT(AUTH): ADD LOGIN   # All caps
```

---

## Tooling

Consider using these tools to enforce the convention:

- [commitlint](https://commitlint.js.org/) - Lint commit messages
- [commitizen](https://commitizen-tools.github.io/commitizen/) - Interactive commit CLI
- [husky](https://typicode.github.io/husky/) - Git hooks for validation
