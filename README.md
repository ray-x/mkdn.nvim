# mkdn.nvim

mkdn.nvim is markdown toolkit for neovim.

## Features

### url

- paste url from clipboard and convert to markdown link
- follow markdown url

### Search

- Find in frontmatter

#### List files with frontmatter key and value

Suppose you have a note with frontmatter like this

```yml
---
tags:
  - tag1
  - tag2
type: note
title: "Note Title"
```

```lua
require('mkdn').list_files({filter = {tags = {'tag1', 'tag2'}, type = 'note'}})
```

Or

```vim
MkdnFiles tags=tag1,tag2 type=note
```

#### Live grep files with frontmatter key and value

```lua
require('mkdn').grep_files({filter={tags = {'tag1', 'tag2'}, type = 'daily'}})
```

Or

```vim
MkdnGrep tags=tag1,tag2 type=daily
```

#### Search tags/page references

It searches

- tags in frontmatter
- page references in markdown
- wiki links in markdown

```lua
require('mkdn').grep_tags({default = 'tag1'})
```

Or

```vim
MkdnTags tag1
```

### Fold

make sure treesitter is installed and markdown parser is enabled

set foldexpr to treesitter

## Config

```lua
require('mkdn').setup{
  follow_link = 'gx',  -- keymap to follow link
  fetch_and_paste_url_title = '<leader>u'
}
```
