# jj-conflict.nvim

https://github.com/user-attachments/assets/b587600a-d286-40ec-9954-2531461aa123

A Neovim plugin to visualize and resolve Jujutsu (jj) merge conflicts, inspired by [git-conflict.nvim](https://github.com/akinsho/git-conflict.nvim).

## Requirements

- Neovim 0.10+
- [Jujutsu (jj)](https://github.com/jj-vcs/jj) CLI installed
- (Optional) [snacks.nvim](https://github.com/folke/snacks.nvim) or [fzf-lua](https://github.com/ibhagwan/fzf-lua) for improved UI pickers and notifications.

## Installation

### lazy.nvim

```lua
{
    'larpios/jj-conflict.nvim',
    version = '*',
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

```lua
require('jj-conflict').setup({
    -- Whether to automatically setup default mappings
	default_mappings = true,
    -- Whether to automatically setup default commands
	default_commands = true,
    -- Whether to enable notifications
    notify = true,
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
| `:JConflictjSquash` | Pick a revision from `jj log` and squash current changes into it |
| `:JConflictjResolve` | Run `jj resolve` for the current buffer |
| `:JConflictjLog` | Show `jj log` in a picker |
| `:JConflictjStatus` | Show modified/conflicted files from `jj status` in a picker |
| `:JConflictjDiff` | Show `jj diff` for the current buffer |

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

