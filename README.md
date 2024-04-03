# mkdn.nvim

mkdn.nvim is markdown toolkit for neovim. It utilize LSP and telescope/ripgrep universal-ctags to provide a better
markdown editing experience.

## Features

### Handling URL

- Paste URL

Paste from clipboard and convert to markdown link, e.g. paste url `https://github.com/` will insert
`[GitHub: Let’s build from here · GitHub](https://github.com/)` to your markdown file

> [!NOTE]<br> requires `curl`

- Follow URL

It will open url in browser; if it is a local file, it will open in neovim

| URL                                         | Action                                                           |
| ------------------------------------------- | ---------------------------------------------------------------- |
| `[sample.md file](sample.md)`               | open sample.md in neovim                                         |
| `[mkdn](http://github.com/ray-x/mkdn.nvim)` | open URL github.com/ray-x/mkdn.nvim with browser                 |
| [[sample]]                                  | open wiki link file `sample.md` in neovim with LSP               |
| [[sample#Sample Heading]]                   | open `sample.md` in neovim and jump to `Sample Heading` with LSP |
| [[sample#^37066d]]                          | open `sample.md` and jump to block `^37066d` with LSP            |

> [!NOTE] To open wiki link in neovim, you need config a markdown LSP, e.g. **marksman** or **markdown-oxide**, also
> please check the LSP documentation for the supported URL format

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

### Table of Content

It is already implemented in lsp. But a Cmdline command is provided to open the table of content

`MkdnToc` open table of content in quickfix `MkdnTocTelescope` open table of content in Telescope

## Config

```lua
require('mkdn').setup{
  follow_link = 'gx',  -- keymap to follow link set to false to disable
  fetch_and_paste_url_title = '<leader>u'  -- keymap to fetch and paste url title
}
```

## Use universal-ctags to generate tags

universal-ctags is capable to parse markdown, frontmatter, fenced languages

The ablitity to generate tags from fenced languages is useful for code block navigation

copy the files in .ctags.d to your note directory and setup nvim to run `ctags -R` on save in your note directory when
you saved/commit your notes

You can use Telescope or [navigator.lua](https://github.com/ray-x/navigator.lua) to navigate the tags

### Create new note

| command                    | description                              |
| -------------------------- | ---------------------------------------- |
| `MkdnNew {subfolder/name}` | create a new note with frontmatter       |
| `MkdnDaily {name}`         | create a new daily note with frontmatter |
| `MkdnListNotes`            | list all notes in note_root              |

> [!NOTE]<br> `MkdnNew note_name` creates a new note name.md in note_path, `MkdnNew subfolder/name` creates a new note name.md in subfolder of note_root.  Default note_root is `~/notes`. If name is not provided, it will prompt for a note name or default to a hash string


## Cridit

There are good resurces and setups for markdown note taking, here are some of them

- [A Vim Note-Taking System &middot; caerul](https://caerul.net/post/a-vim-notetaking-system/)
- [Custom Note Tagging System with Ctags and Vim](https://www.edwinwenink.xyz/posts/43-notes_tagging/)
- [Ctags For Markdown Notes &middot; Michał Góral](https://goral.net.pl/post/ctags-for-notes/)
- [Blog post editing, part 2 |Michael Welford](https://its.mw/posts/blog-post-editing-2/)

## Screenshot

## Table of Content and Link references

![mkdn](https://gist.github.com/assets/1681295/36f671a7-1f15-49dd-9220-f488b4aac883.jpg)
