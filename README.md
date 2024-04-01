# mkdn.nvim

mkdn.nvim is markdown toolkit for neovim.

## Features

### url

- paste url from clipboard and convert to markdown link
- follow markdown url

### Search

- Find in frontmatter

List files with frontmatter key and value

```lua
require('mkdn').md_files({filter = {tags = {'tag1', 'tag2'}, type = 'note'}})
```

Or
```vim
MkdnFiles tags=tag1,tag2 type=note
```

Live grep files with frontmatter key and value

```lua
require('mkdn').md_grep({filter={tags = {'tag1', 'tag2'}, type = 'daily'}})
```

Or
```vim
MkdnGrep tags=tag1,tag2 type=daily
```

### Fold

make sure treesitter is installed and markdown parser is enabled

set foldexpr to treesitter
