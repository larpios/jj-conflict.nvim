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
  default_mappings = true,   -- disable buffer local mapping
  default_commands = true,   -- disable commands
  disable_diagnostics = false,
  highlights = {
    ours = 'DiffAdd',
    theirs = 'DiffText',
    marker = 'CursorLine',
    label = 'Comment',
  },
  mappings = {
    ours = 'o',
    theirs = 't',
    both = 'b',
    none = '0',
    next = 'n',
    prev = 'p',
  }
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


## How It Works

Unlike Git, Jujutsu uses a different conflict marker format that shows diffs:

```
<<<<<<< conflict 1 of 1
%%%%%%% diff from: abc123 "base commit"
\\\\\        to: def456 "our commit"
-old line
+new line
+++++++ ghi789 "their commit"
their content here
>>>>>>> conflict 1 of 1 ends
```

The plugin detects these markers, highlights them, and provides commands to resolve the conflict by picking one or both sides.

