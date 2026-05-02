# Release to PyPI

Release a new version of a Python package. Accepts an optional argument: `major`, `minor`, or `patch` (defaults to `patch`).

## Steps

1. **Read the current version** from `pyproject.toml` (the `version = "X.Y.Z"` line).

2. **Calculate the new version** based on the argument:
   - `patch`: X.Y.Z → X.Y.(Z+1)
   - `minor`: X.Y.Z → X.(Y+1).0
   - `major`: X.Y.Z → (X+1).0.0

3. **Confirm with the user** before proceeding: show the current version, the new version, and ask for a one-line release summary. Do NOT proceed without confirmation.

4. **Update `pyproject.toml`** with the new version string.

5. **Run tests** with `uv run pytest` to ensure nothing is broken. If tests fail, stop and report.

6. **Commit** the version bump:
   ```
   Bump version to <new_version>
   ```

7. **Push** the commit to origin main.

8. **Create a GitHub release** using `gh release create`:
   ```bash
   gh release create v<new_version> --title "v<new_version>" --notes "<release summary>"
   ```
   This triggers the publish workflow which builds and publishes to PyPI.

9. **Verify** the publish workflow was triggered:
   ```bash
   gh run list --workflow=publish.yml --limit 1
   ```

10. Report the release URL and PyPI workflow status to the user.

## Important

- The `gh release create` command is what triggers PyPI publishing (not a tag push).
- Always run tests before releasing.
- Never skip the user confirmation step.
