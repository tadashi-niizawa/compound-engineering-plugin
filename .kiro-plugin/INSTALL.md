# Installing Compound Engineering for Kiro CLI

Kiro CLI loads Compound Engineering through its native **skills** discovery — the same
`SKILL.md` directories shipped in this repository's `skills/` folder. No Bun converter or
generated copy step is required.

Kiro CLI discovers skills from `skill://` resources declared by the active agent. The
default agent already includes:

```
skill://.kiro/skills/*/SKILL.md     # workspace skills
skill://~/.kiro/skills/*/SKILL.md   # global skills
```

Each skill lives in `<name>/SKILL.md` with YAML frontmatter (`name`, `description`), which is
exactly the format CE already ships. This installer symlinks each CE skill directory into the
Kiro skills directory so they appear as `/skill-name` slash commands.

## Install skills

From a clone of this repository:

```bash
# Global (~/.kiro/skills/) — available in every project
./compound-engineering-plugin/.kiro-plugin/scripts/install-skills.sh --global

# Project (.kiro/skills/ in the current directory)
./compound-engineering-plugin/.kiro-plugin/scripts/install-skills.sh --project
```

Start a **new** Kiro CLI session after installing. Then type `/ce-` and press Tab, or run
`/prompts`, to see the skills. Invoke one with, for example:

```
/ce-plan add pagination to the users endpoint
```

The script creates symlinks so Kiro reads the live skill directories from your checkout.
Re-run it after `git pull` to refresh links when skill folder names change. It only ever
creates or replaces CE-owned symlinks (links whose target resolves under this checkout's
`skills/` tree); an existing `~/.kiro/skills/<name>` pointing at your own skill, a fork, or
another checkout is left untouched.

## Manual-only skills

Some skills are marked `disable-model-invocation: true` in their frontmatter
(`ce-dogfood`, `ce-polish`, `ce-product-pulse`, `ce-promote`, `ce-retune`, `ce-setup`,
`ce-sweep`, `ce-test-xcode`, `wtf`). In model-auto-activation hosts like Cline these are
withheld by default to avoid firing unintentionally.

Kiro CLI invokes skills explicitly as `/skill-name` slash commands rather than auto-activating
them from description matches, so these skills are **linked by default** here — they only run
when you type the command. If you would rather keep them out of the default skill-discovery
glob entirely, exclude them:

```bash
./compound-engineering-plugin/.kiro-plugin/scripts/install-skills.sh --global --exclude-manual
```

## Verify

```bash
ls -l ~/.kiro/skills | grep -- '-> .*/compound-engineering-plugin/skills/'
```

In a Kiro CLI session, run `/context` to confirm the skills are loaded as resources, or
`/prompts` to list them.

## Pin a release

Clone the tag you want, then run the install script against that checkout:

```bash
git clone --branch compound-engineering-vX.Y.Z --depth 1 \
  https://github.com/EveryInc/compound-engineering-plugin.git
./compound-engineering-plugin/.kiro-plugin/scripts/install-skills.sh --global
```

Because the links point at the pinned checkout, the skills stay on that release until you
re-run the installer against a different checkout.

## Local development

Point the links at your working checkout and edit `skills/<name>/SKILL.md` directly — Kiro
reads the live files on each new session. Run `/prompts` or start a new session to pick up
edits.

## Uninstall

```bash
./compound-engineering-plugin/.kiro-plugin/scripts/uninstall-skills.sh --global
# or, for a project install:
./compound-engineering-plugin/.kiro-plugin/scripts/uninstall-skills.sh --project
```

This removes only CE-owned symlinks; your own skills are left in place.

## Notes and limitations

- A few CE skills declare host-specific frontmatter fields (for example `argument-hint`,
  `allowed-tools`, `disable-model-invocation`). Kiro reads only `name` and `description`
  from frontmatter and ignores the rest, so the skills load fine; any host-specific
  behavior those fields would enable elsewhere simply does not apply in Kiro.
- Skill arguments: Kiro expands the text after the command only where a skill contains the
  literal `$ARGUMENTS` placeholder. CE skills do not use that placeholder; instead they load
  the full `SKILL.md` as the prompt and interpret the surrounding request from the
  conversation, the same way they behave on other skill hosts. Typing your request in the same
  message as the command (for example `/ce-plan add pagination to the users endpoint`) gives
  the skill that context.
- This is a community-maintained integration. Kiro CLI is not one of the upstream project's
  officially listed hosts.
