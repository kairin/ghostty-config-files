# AI rules

Use our AI rules to get the most out of Tailwind CSS when using AI tools like Cursor, Windsurf, Claude Code, and others.

## Installation

You can get the latest version of Adam's AI rules from the [rules folder](./tailwind.md). Copy and paste these into your prompts as needed, or set them up in your AI tool of choice.

## Using with Cursor

To add these rules to Cursor, create a new file at `.cursor/rules/tailwind.mdc`, and add this header to the new file (adjusting the file extensions if necessary):

```md
---
name: tailwindcss
description: Best practices for using and upgrading Tailwind CSS
globs: ['**/*.{js,ts,jsx,tsx,mdx,css,html,vue,svelte,astro}']
tags:
  - tailwind
  - css
---
```

Finally copy and paste the [rules](./tailwind.md) into the end of the file.

## Using with Claude Code

### Adding the rules as needed

If you want fine-grained control, store the [rules](./tailwind.md) in a dedicated rules folder like `rules/tailwind.md`. Then, whenever you want to make your current Claude Code session an expert in Tailwind CSS, `@`-mention the rules to make Claude read it:

```
╭──────────────────────────────────────────────────────────────────────────────╮
│ > read @rules/tailwind.md and create a new landing page                      │
╰──────────────────────────────────────────────────────────────────────────────╯
```

### Referencing in your CLAUDE.md file

Copy and paste the [rules](./tailwind.md) directly into your `CLAUDE.md` file. Claude Code will now read them for every new session.
