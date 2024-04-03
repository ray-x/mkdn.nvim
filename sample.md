---
title: a sample markdown file
slug: a-sample-markdown-file
summary: a sample markdown file for testing the plugin
date: 2024-03-01
publishDate: 2024-04-01
tags: [foo, bar]
series:
toc: false
draft: true
type: post
---

# Top heading

## Sample Heading

This is a sample markdown file for testing the plugin.

## Sample Subheading

This is a sample subheading. with #tagname #markdown

reference [[sample]] pointing to the same file. ^37066d

The url for this plugin is [mkdn.nvim](https://www.github.com/ray-x/mkdn.nvim)

### heading lvl 3

[A Vim Note-Taking System &middot; caerul](https://caerul.net/post/a-vim-notetaking-system/)

[Blog post editing, part 2 |Michael Welford](https://its.mw/posts/blog-post-editing-2/)

URL jump example: [GitHub: Let’s build from here · GitHub](https://github.com/)

A wiki page url [[README]] can be handle by marksman and [README](README.md)

[[sample#Sample Heading2]]

[[sample#^37066d]]

Link to [[README#Search]]

## Sample Heading2

Sample text for heading 2

### TODO

- [ ] Task 1
- [ ] Task 2

## Code blocks

sample python

```python
def hello():
    print("Hello, World!")
```

- primary key：

## sql code block

```sql
create table department2(
    id int primary key,
    name varchar(20),
    comment varchar(100)
    );

create table department3(
    id int,
    name varchar(20),
    comment varchar(100),
    constraint pk_name primary key(id);
```

- second key:

  ```sh
  foo()
  {
      :
  }
  ```
