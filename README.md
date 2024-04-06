# mkdn.nvim

mkdn.nvim is markdown toolkit for neovim. It utilize LSP and telescope/ripgrep universal-ctags to provide a better
markdown editing experience.

## Features

### Handling URL

- Paste URL

  - Paste from clipboard and convert to markdown link,
e.g. paste url `https://github.com/` will insert
`[GitHub: Let’s build from here · GitHub](https://github.com/)`
to your markdown file

  - If the URL is a image URL, it will download the URL and
insert `![image](url)` to your markdown file


> [!NOTE]<br> requires `curl`

- Follow URL

A keybinding to open url in browser; if it is a local file, it will open in neovim, The feature utilize LSP to open wiki
link in neovim

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

#### Search tags/page references

It searches

- tags in frontmatter
- page references in markdown
- wiki links in markdown

```lua
require('mkdn').grep_tag({default_text = 'tag1'})
```

Or

```vim
MkdnTag tag1
```

### Fold

make sure treesitter markdown parser is installed

set foldexpr to treesitter

### Table of Content

It is already implemented in lsp. But a Cmdline command is provided to open the table of content

`MkdnToc` open table of content in quickfix `MkdnTocTelescope` open table of content in Telescope

You can also use [navigator.lua](https://github.com/ray-x/navigator.lua) LspSymbol to navigate the table of content

## Config

```lua
require('mkdn').setup{
  follow_link = 'gx',  -- keymap to follow link set to false to disable
  paste_link = '<leader>u',  -- keymap to fetch and paste url title
  templates = {
    -- see below: templates setup
  },
  note_root = '~/notes',  -- default note root
  assets_path = 'assets',  -- default assets path, a subfolder of note_root
  author = os.getenv('USER'),  -- default author
}
```

## Use universal-ctags to generate tags

universal-ctags is capable to parse markdown, frontmatter, fenced languages

The ablitity to generate tags from fenced languages is useful for code block navigation

copy the files in .ctags.d to your note directory and setup nvim to run `ctags -R` on save in your note directory when
you saved/commit your notes

You can use Telescope or [navigator.lua](https://github.com/ray-x/navigator.lua) to navigate the tags

### Create new note

The plugin allow you to capture your ideas quickly with a template


| command                    | description                              |
| -------------------------- | ---------------------------------------- |
| `MkdnNew {subfolder/name}` | create a new note with frontmatter       |
| `MkdnDaily {name}`         | create a new daily note with frontmatter |
| `MkdnCapture`       | create note from your selected template  |
| `MkdnListNotes`            | list all notes in note_root              |

> [!NOTE]<br> `MkdnNew note_name` creates a new note name.md in note_path, `MkdnNew subfolder/name` creates a new note
> name.md in subfolder of note_root. Default note_root is `~/notes`. If name is not provided, it will prompt for a note
> name or default to a hash string

### Capture ideas and templates setup

Capture allows you to create a note without interrupting your workflow.
You can define a template for your notes. The default template is defined in config.lua

```lua
  {
    templates = {
      _meta = { -- meta data for templates
        -- some default value for templates e.g. {{auther}}
        author = os.getenv('USER'),  -- replace {{auther}}
        date = os.date('%Y-%m-%d'),  -- replace {{date}} in template
      },
      daily = {                       -- `daily` note template
        name = function()             -- default name for daily note
          return os.date('%Y-%m-%d')
        end, -- or a function that returns the name
        path = 'journal',            -- default path for daily note inside note_root
        content = {                   -- content of daily note
          function()                  -- content can be a function return a string or a table
            return frontmatter({ tags = 'daily', category = 'daily' })
          end,                        -- frontmatter generates frontmatter
          '# {{name}}',               -- content item can be a string with meta data
          '\n',                       -- extra empty line
          '## Tasks',
          '- [ ] Task 1',
        },
      },
      default = {
        path = '',
        name = function()
          -- default name with random number in hex
          vim.ui.input({
            prompt = 'Note name: ',
            default = 'default_' .. string.format('%x', math.random(16, 1000000)):sub(1, 4),
          }, function(result)
            return result
          end)
        end, -- or a function that returns the name
        content = {
          function()
            return frontmatter({ category = 'note' })
          end,
          '# {{name}}',
        },
      },
    }
```

## Cridit

There are good resources and setups for markdown note taking, here are some of them

- [A Vim Note-Taking System &middot; caerul](https://caerul.net/post/a-vim-notetaking-system/)
- [Custom Note Tagging System with Ctags and Vim](https://www.edwinwenink.xyz/posts/43-notes_tagging/)
- [Ctags For Markdown Notes &middot; Michał Góral](https://goral.net.pl/post/ctags-for-notes/)
- [Blog post editing, part 2 |Michael Welford](https://its.mw/posts/blog-post-editing-2/)

## Screenshot

## Table of Content and Link references

![image](https://github.com/ray-x/mkdn.nvim/assets/1681295/15d0ca22-da99-4e6f-a016-7f24a90354b8)
