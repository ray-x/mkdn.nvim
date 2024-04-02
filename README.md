# mkdn.nvim

mkdn.nvim is markdown toolkit for neovim. It utilize LSP and telescope to provide a better markdown editing experience.

## Features

### Handling URL

- Paste URL

Paste from clipboard and convert to markdown link, e.g. paste url `https://github.com/` will insert
`[GitHub: Let’s build from here · GitHub](https://github.com/)` to your markdown file

> [!NOTE] require `curl`

- Follow URL

It will open url in browser; if it is a local file, it will open in neovim

| URL                                         | Action                                                           |
| ------------------------------------------- | ---------------------------------------------------------------- |
| `[sample.md file](sample.md)`               | open sample.md in neovim                                         |
| `[mkdn](http://github.com/ray-x/mkdn.nvim)` | open URL github.com/ray-x/mkdn.nvim with browser                 |
| [[sample]]                                  | open wiki link file `sample.md` in neovim with LSP               |
| [[sample#Sample Heading]]                   | open `sample.md` in neovim and jump to `Sample Heading` with LSP |
| [[sample#^37066d]]                          | open `sample.md` and jump to block `^37066d` with LSP            |

> [!NOTE] open wiki link in neovim, you need config a markdown LSP, e.g. **marksman** or **markdown-oxide**, also please
> check the LSP documentation for the supported URL format

### Search

- Find in frontmatter

#### List files with frontmatter key and value

Suppose you have a note with the following frontmatter

```yml
---
tags:
  - tag1
  - tag2
type: note
title: "Note Title"
```

You can list all notes with tag1 and tag2

```lua
require('mkdn').list_files({filter = {tags = {'tag1', 'tag2'}, type = 'note'}})
```

Or

```vim
MkdnFiles tags=tag1,tag2 type=note
```

User case: list all notes with tag `python` and `ML`

#### Live grep files with frontmatter key and value

```lua
require('mkdn').grep_files({filter={tags = {'tag1', 'tag2'}, type = 'daily'}})
```

Or

```vim
MkdnGrep tags=tag1,tag2 type=daily
```

User case: search all notes with tag `python` and `ML` and do a live grep for `scipy`

````lua
#### Search tags/page references

It searches

- tags in frontmatter
- page references in markdown
- wiki links in markdown

```lua
require('mkdn').grep_tags({default = 'tag1'})
````

Or

```vim
MkdnTags tag1
```

### Fold

make sure treesitter markdown parser is installed

set foldexpr to treesitter

## Config

```lua
require('mkdn').setup{
  follow_link = 'gx',  -- keymap to follow link set to false to disable
  fetch_and_paste_url_title = '<leader>u'  -- keymap to fetch and paste url title
}
```
