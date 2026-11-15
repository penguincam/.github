# Recipes for the organization defaults. `just` lists them.

default:
    @just --list

# Run the hook self-test against a throwaway repository.
hooks-test:
    bash githooks/test.sh

# Remove each refusal in turn and confirm the self-test fails.
mutation-test:
    bash scripts/mutation-test.sh

# Check the README files here against the README rule.
readme-check:
    bash githooks/readme-check.sh README.md
    bash githooks/readme-check.sh profile/README.md

# Lint the shell scripts with shellcheck.
lint:
    shellcheck -x -P SCRIPTDIR githooks/_lib.sh githooks/commit-msg githooks/pre-commit githooks/pre-push githooks/test.sh githooks/readme-check.sh scripts/mutation-test.sh
