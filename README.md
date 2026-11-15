# .github

Organization defaults for penguincam: the contributing guide, the security
policy, the pull request template, the organization profile and the git hooks.

## Start

Copy the hooks into a repository and install them:

```sh
mkdir -p .githooks && cp githooks/* .githooks/
git config core.hooksPath .githooks
```

## Tasks

| Task | Command |
|---|---|
| Test the hooks | `just hooks-test` |
| Prove each refusal is tested | `just mutation-test` |
| Check every README here | `just readme-check` |
| Lint the shell scripts | `just lint` |

## Related

- [template](https://github.com/penguincam/template): the starting point for a new repository.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). A change to `githooks/` needs a test.

## License

The license for this repository is not yet chosen.
