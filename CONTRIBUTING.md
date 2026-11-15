# Contributing

This guide covers every repository in the penguincam organization. GitHub
shows it for each repository that has no CONTRIBUTING.md of its own.

## Before you start

You need these on your machine:

| Tool | Why |
|---|---|
| `git` 2.34 or later | SSH commit signing needs it. |
| `gh`, signed in with `gh auth login` | Forks, syncs and pull requests. |
| `just` | Each repository's recipes. A repository with a Nix devshell provides it through `nix develop`. |
| A signing key on your GitHub account | Every commit is signed. See "Set up commit signing". |

Some repositories are private. The owner grants read access to each person
who works on one. Read access lets you fork it.

## Fork first

Only the owner can write to a penguincam repository. Everyone else works
from a fork named `<repo>-contrib` and sends changes as pull requests.

    gh repo fork penguincam/<repo> --fork-name <repo>-contrib --clone
    cd <repo>-contrib
    just fork-setup <your-login>       # origin = your fork, upstream = penguincam, upstream push off
    just hooks-install                 # see "Install the hooks"

`just fork-setup` checks that your fork's parent is the penguincam
repository. It sets `origin` to your fork and `upstream` to the organization.
It turns off pushes to `upstream`.

Start each change from an up-to-date `dev`:

    gh repo sync <your-login>/<repo>-contrib --branch dev
    git fetch origin
    git switch -c feat/short-slug origin/dev

## Branches

A branch name is a prefix, a slash and a short kebab-case slug.

| Prefix | Use |
|---|---|
| `feat/` | New behavior or content. |
| `fix/` | A defect correction. |
| `docs/` | Documentation only. |
| `chore/` | Maintenance with no behavior change. |

Feature branches merge into `dev`. The owner merges `dev` into `main` for a
release. Open every pull request against `dev`, never against `main`.

## Commits

- Subjects follow Conventional Commits: `type(scope): summary`. The scope is
  optional. The types are `feat`, `fix`, `docs`, `chore`, `ci`, `build`,
  `perf`, `refactor`, `revert`, `style` and `test`.
- Every commit is signed with a key on your GitHub account. GitHub must show
  it as verified.
- Commit as yourself. Add no AI attribution anywhere. That means no
  `Co-Authored-By` trailer for an AI, no tool prefix in a title and no
  "generated with" line in a commit, a pull request or a comment.
- Write no em dashes in text you author.

## Set up commit signing

GitHub needs your SSH public key twice: once as an authentication key and
once as a signing key. Add `~/.ssh/id_ed25519.pub` both ways under Settings,
SSH and GPG keys. Create the key first if you have none:

    ssh-keygen -t ed25519 -C "your-github-login"

Then tell git to sign every commit and to trust your own key:

    git config --global gpg.format ssh
    git config --global user.signingkey ~/.ssh/id_ed25519.pub
    git config --global commit.gpgsign true
    mkdir -p ~/.config/git
    echo "$(git config user.email) $(cat ~/.ssh/id_ed25519.pub)" >> ~/.config/git/allowed_signers
    git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers

Check it in a throwaway repository:

    cd "$(mktemp -d)" && git init -q && git commit -q --allow-empty -m "chore: signing check"
    git log -1 --format='%G?'          # must print G

A GPG key also works. Upload it under GPG keys and set `gpg.format` to
`openpgp`.

## Install the hooks

Every repository carries the same git hooks in `.githooks/`. Install them
once per clone:

    just hooks-install

The recipe points `core.hooksPath` at `.githooks`. It sets
`remote.pushDefault` to `origin` and turns off pushes to `upstream`. It adds
the agent file names to your clone's `.git/info/exclude`. It warns when
`commit.gpgsign` is not set. A global `core.hooksPath` of your own still
runs after the repository hooks.

The hooks refuse these:

| Hook | Refuses |
|---|---|
| `commit-msg` | AI attribution in the message. |
| `pre-push` | A push to any `penguincam` remote. |
| `pre-push` | An unsigned commit in the pushed range. Merge commits made by GitHub are exempt. |
| `pre-push` | AI attribution in any pushed commit. |
| `pre-push` | An agent file in any pushed commit or in the pushed tree. See "Agent files". |

The pushed range is every commit the destination remote does not hold yet.
The owner, who alone can write to the organization, sets
`PENGUINCAM_HOOKS_ALLOW_ORG_PUSH=1` for a push there. That lifts only the
first refusal in the table.

They warn about a branch name without a prefix, a subject that is not a
conventional commit, an em dash, a staged agent file and a README that
breaks the README rule. Each message names the section of this guide that
explains the rule and a command that fixes it.

The hooks run on your machine, so they help you and do not bind you. The
control is the access model: only the owner can write, and the owner sends
back a pull request that breaks these rules.

`just hooks-check` compares your `.githooks/` with the copy in this
repository. `just hooks-test` runs the hooks against throwaway commits.

## Agent files

Bring your own agent tooling and keep it on your fork. Upstream repositories
carry no agent files. That covers `AGENTS.md`, `CLAUDE.md`, `.claude/`,
`.agents/`, agent notes, prompts, skills and any other file that directs an
agent. The pre-push hook refuses these paths:

| Kind | Paths |
|---|---|
| Instruction files | `AGENTS.md`, `CLAUDE.md`, `CLAUDE.local.md`, `GEMINI.md`, `llms.txt`, `copilot-instructions.md`, `.cursorrules`, `.windsurfrules`, in any directory |
| Directories | `.claude/`, `.agents/`, `.codex/`, `.cursor/`, `.gemini/`, `.windsurf/`, `agent-notes/`, at any depth |

Keep your files untracked in each clone. `just hooks-install` lists the
common names in `.git/info/exclude`. Add any other name the same way:

    printf '/%s\n' my-agent-file.md >> "$(git rev-parse --git-common-dir)/info/exclude"

To keep the files across clones, put them on an orphan branch named
`agents-overlay` on your fork. The hooks let that branch carry agent files
to your fork and nowhere else. Never merge it and never use it as the base or
head of a pull request. Build it in a second worktree, so your files stay in
place in the first:

    git worktree add --detach ../<repo>-overlay
    cd ../<repo>-overlay
    git switch --orphan agents-overlay
    cp -R ../<repo>-contrib/AGENTS.md ../<repo>-contrib/.claude .
    git add -f AGENTS.md .claude       # -f because .git/info/exclude lists them
    git commit -m "chore(overlay): agent files"
    git push origin agents-overlay
    cd ../<repo>-contrib && git worktree remove ../<repo>-overlay

In a fresh clone, copy the files back without tracking them:

    git fetch origin agents-overlay
    git archive origin/agents-overlay | tar -x -f -

The hooks hold an agent to the same rules as a person. It pushes to your
fork, signs with your key and adds no AI attribution. You are the author of
what your agent writes, and you answer for it in review.

## README rule

Every README in the organization has the same short shape. The sections are
fixed:

    # <name>

    One or two sentences on what the repository holds.

    ## Start
    ## Tasks
    ## Related
    ## Contributing
    ## License

- Use exactly these five `##` sections, in this order, and no deeper
  headings. "Start" says how to get running. "Tasks" is a table of commands.
  "Related" links the neighboring repositories. "Contributing" points here.
  "License" names the license.
- Keep the file to 40 lines or fewer. Longer material goes in `docs/`.
- Write no ticket ids, no issue or pull request numbers and no links to a
  ticket tracker.
- Name no people. Write no mail addresses and no `@handles`. Name a role
  instead, such as the owner or a maintainer.
- Write no internal host names, private addresses or network names.

Check a README with:

    bash .githooks/readme-check.sh README.md

The pre-commit hook runs the same check when README.md is staged. It cannot
spot a person's name or a host name, so the owner checks those in review.

## Pull requests

Open the pull request from a branch on your fork into `dev`:

    gh pr create --repo penguincam/<repo> --base dev --head <your-login>:<branch>

- The title is a conventional commit subject.
- Say what the change does and how you checked it. Paste the commit, your
  operating system, the command you ran and the last lines of its output.
- The owner reviews and merges.

## Security

Report a security issue privately. See [SECURITY.md](SECURITY.md).

## Where the hooks live

This repository holds the canonical hooks in `githooks/`. Each repository
carries a byte-identical copy in `.githooks/`, and `just hooks-check` fails
on any difference. A change to the hooks lands here first, with its test in
`githooks/test.sh`. Then each repository copies the same bytes.
