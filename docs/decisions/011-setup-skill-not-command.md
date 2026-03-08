# 011 Setup exposed as a skill, not a command

**Status:** Accepted
**Date:** 2026-03-08

## Context

Vyasa needs a setup step that checks runtime dependencies (`git`, `jq`) and installs
`prettier` into the plugin directory. The question was whether to expose this as a slash
command (`/vyasa:setup`) or a skill (`vyasa:setup`).

The setup process is conversational by nature: it installs dependencies where possible,
surfaces install links when it cannot, checks for reserved directory names, and asks the
user to act and re-run if anything is missing. This requires back-and-forth with the user.

Slash commands in Claude Code execute a fixed instruction set — they are designed for
deterministic, low-interaction tasks that produce a result and finish. They do not model
the iterative loop well: the agent has no natural place to pause, ask the user to install
a tool, and resume.

Skills are invoked inside a live conversation, where the agent and user are already in
dialogue. The agent can surface problems, explain what to do, wait for the user to act,
and continue — without the user having to re-invoke a command after each step.

## Decision

Setup is exposed as a skill (`plugin/skills/setup/SKILL.md`), not a command. The
`/vyasa:setup` command is removed.

## Consequences

- Setup runs inside a live conversation, where agent-user back-and-forth is natural
- Users invoke setup with `vyasa:setup` (skill) rather than `/vyasa:setup` (command)
- The skill is discoverable by description — users can ask for "setup" and the skill will be triggered

## Alternatives considered

**Command only.** Commands have no good model for "pause, ask the user to do something,
and continue." A command that hits a missing dependency either silently fails or prints
links and exits — leaving the user to re-run manually. That friction compounds with
multiple missing dependencies.

**Command with skill fallback.** Initially considered: keep the command as the primary
interface and expose the skill as a fallback when the command fails. Rejected because it
creates two surfaces with identical logic and no clear ownership. The command's primary
weakness (poor conversational fit) is not a failure mode — it is the normal case for
users who lack some dependencies. A fallback that handles the normal case is just the
right interface under a different name.
