# jj-conflict.nvim

A Neovim plugin to visualize and resolve Jujutsu (jj) merge conflicts, inspired by [git-conflict.nvim](https://github.com/akinsho/git-conflict.nvim).

## Requirements

- Neovim 0.10+
- [Jujutsu (jj)](https://github.com/jj-vcs/jj) CLI installed

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
        'JjConflictPrevConflict'
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
		none = "H0",
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
| `:JjConflictList` | List conflicts in location list |

## Mappings

Default buffer-local mappings inside conflicted files:

- `co` — choose ours
- `ct` — choose theirs
- `cb` — choose both
- `c0` — choose none
- `]x` — move to next conflict
- `[x` — move to previous conflict

## Autocommands

```lua
vim.api.nvim_create_autocmd('User', {
  pattern = 'JjConflictDetected',
  callback = function()
    vim.notify('Conflict detected in ' .. vim.fn.expand('<afile>'))
  end
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'JjConflictResolved',
  callback = function()
    vim.notify('All conflicts resolved!')
  end
})
```

## API

```lua
local count = require('jj-conflict.detection').conflict_count(bufnr)
local has_conflicts, conflicts = require('jj-conflict.detection').has_conflicts(bufnr)
local conflict = require('jj-conflict.detection').get_conflict_at_cursor(bufnr)
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

