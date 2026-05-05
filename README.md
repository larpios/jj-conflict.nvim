# jj-conflict.nvim

https://github.com/user-attachments/assets/b587600a-d286-40ec-9954-2531461aa123

A Neovim plugin to visualize and resolve Jujutsu (jj) merge conflicts, inspired by [git-conflict.nvim](https://github.com/akinsho/git-conflict.nvim).

## Features

- **Inline Resolution**: Choose ours, theirs, both, or base directly in the buffer.
- **Visual Enhancements**:
    - **Highlights**: Color-coded conflict regions.
    - **SignColumn**: Gutter icons (O/T/!!) for quick scanning.
    - **Rich Virtual Text**: See commit IDs and messages inline next to markers.
- **Native LSP Support**: Resolve conflicts using your standard LSP Code Action keybind (e.g., `<leader>ca`).
- **3-Way Diffsplit**: Open a dedicated tab with side-by-side diffs (Ours | Base | Theirs) for complex merges.
- **Pickers**: List conflicts, view status, and browse logs via `snacks.nvim` or `fzf-lua`.

## Requirements

- Neovim 0.10+
- [Jujutsu (jj)](https://github.com/jj-vcs/jj) CLI installed
- (Optional) [snacks.nvim](https://github.com/folke/snacks.nvim) or [fzf-lua](https://github.com/ibhagwan/fzf-lua) for improved UI pickers and notifications.
- (Optional) [codediff.nvim](https://github.com/esmuellert/codediff.nvim) for an enhanced VSCode-style 3-way merge UI.

## Installation

### lazy.nvim

```lua
{
    'larpios/jj-conflict.nvim',
    -- If you want to use the latest tagged version
    -- version = '*',
    event = { 'BufReadPre', 'BufNewFile' },
    cmd = {
        'JjConflictList',
        'JjConflictChooseBoth',
        'JjConflictChooseNone',
        'JjConflictChooseOurs',
        'JjConflictChooseTheirs',
        'JjConflictNextConflict',
        'JjConflictPrevConflict',
        'JjConflictSquash',
        'JjConflictResolve',
        'JjConflictLog',
        'JjConflictStatus',
        'JjConflictDiff',
    },
    config = true
}
```

## Configuration

The following options are the default values:

```lua
require('jj-conflict').setup({
    -- Whether to automatically setup default mappings
	default_mappings = true,
    -- Whether to automatically setup default commands
	default_commands = true,
    -- Whether to enable notifications
    notify = true,
    -- Whether to show signs in the gutter
    signs = true,
    -- Whether to show rich virtual text for commits
    virt_text = true,
    -- Whether to use codediff.nvim for 3-way splits if available
    use_codediff = true,
    -- Prefix for keybinding descriptions
    desc_prefix = nil,
    -- Highlight groups
	highlights = {
		ours = "DiffAdd",
		theirs = "DiffText",
		marker = "CursorLine",
		label = "Comment",
		diff_remove = "DiffDelete",
		diff_add = "DiffAdd",
	},
    -- Custom mappings
	mappings = {
		ours = "Ho",
		theirs = "Ht",
		both = "Hb",
		base = "H0",
		next = "Hn",
		prev = "Hp",
	},
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:JjConflictChooseOurs` | Select our side |
| `:JjConflictChooseTheirs` | Select their side |
| `:JjConflictChooseBoth` | Select both sides |
| `:JjConflictChooseNone` | Select none |
| `:JjConflictNextConflict` | Jump to next conflict |
| `:JjConflictPrevConflict` | Jump to previous conflict |
| `:JjConflictList` | List conflicts in a UI picker |
| `:JjConflictjSquash` | Pick a revision from `jj log` and squash current changes into it |
| `:JjConflictjResolve` | Run `jj resolve` for the current buffer |
| `:JjConflictjLog` | Show `jj log` in a picker |
| `:JjConflictjStatus` | Show modified/conflicted files from `jj status` in a picker |
| `:JjConflictDiff` | Show `jj diff` for the current buffer |
| `:JjConflictDiffsplit` | Open 3-way diffsplit for the current conflict |


## Lualine Support

The plugin provides a `statusline` module that optionally exposes the current `jj` workspace ID alongside the conflict count.

```lua
-- In your lualine config:
require('lualine').setup({
  sections = {
    lualine_c = {
      {
        require('jj-conflict.statusline').get_status,
        cond = function() return require('jj-conflict.api').has_conflicts(0) end,
      }
    }
  }
})
```

## How It Works

Unlike Git, Jujutsu uses a different conflict marker format that shows diffs:

```
<<<<<<< conflict 1 of 1
%%%%%%% diff from: abc123 "base commit"
\\\\\\\        to: def456 "our commit"
-old line
+new line
+++++++ ghi789 "their commit"
their content here
>>>>>>> conflict 1 of 1 ends
```

The plugin detects these markers, highlights them, and provides commands to resolve the conflict by picking one or both sides.

