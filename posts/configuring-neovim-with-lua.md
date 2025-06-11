title: Using Neovim and Configuring it with Lua
date: 2021-10-10 12:00
draft: false
tags: vim, neovim, lua, editor, editors
---
Neovim is a fork of Vim created in 2015. It strove to split the text editing
engine from the UI, to add features then missing from Vim such as embedded
terminals and asynchronous operations, and to allow configuration in
[Lua](https://www.lua.org/) rather than the baroque and Vim-specific [VimL aka
VimScript](https://en.wikipedia.org/wiki/Vim_(text_editor)#Vim_script).

As of [the 0.5 release](https://github.com/neovim/neovim/releases/tag/v0.5.0),
it has delivered on these goals. An ecosystem of third party UIs has flourished,
the new features were implemented and saw usage, and it can now be configured
entirely in Lua. Later releases such as
[0.8](https://github.com/neovim/neovim/releases/tag/v0.8.0) have added even more
nicities.

![By Jason Long, neovim, CC BY 3.0](https://upload.wikimedia.org/wikipedia/commons/4/4f/Neovim-logo.svg)

Why use a fork of Vim rather than the plethora of other editors out there? I've
given my reasons [in the previous
article](https://volatilethunk.com/posts/2021/10/09/a-brief-history-of-text-editors-from-vi-and-emacs-to-intellij-and-visual-studio-code/post.html#choosing-an-editor),
but to summarise: it depends on just a terminal as opposed to a whole web
browser engine like Visual Studio code; it has ergonomic keybindings owing to
its modal editor origins; its UI/engine split lets third parties develop UIs
independently; it comes from POSIX vi, allowing core sysadmin skills to be
reused in one's primary editor; and modifying it can be done with _immediate
hackability_ rather than only formally loaded extensions with boilerplate.

I'll document the process for configuring Neovim with Lua, and try to assume the
reader hasn't extensive familiarity with the vi family of editors. That
said, this is a guide for _configuring_ Neovim, not how to use the vi family of
editors on a day-to-day basis.

## A (Far too Short) Crash Course in Neovim

In case you're unfamiliar with the vi family of editors, of which Neovim is a
member, there are
[numerous](https://superuser.com/questions/246487/how-to-use-vimtutor)
[places to start](https://vim-adventures.com/).

The fundamentals are:

- Neovim runs in a terminal by default. That means its program, `nvim`, must be
  in your `PATH` if you got it directly from the GitHub release. Once its there,
  invoke it by entering `nvim`. Pass in file paths as arguments to open them
  directly.
- Neovim (and Vim and vi) run in "modes". Each mode has a different set of
  keyboard shortcuts, which they call "keybindings".
- You start in "normal" mode. Keys perform operations rather than being inserted
  into the document. For example, `dd` deletes the current line rather than
  typing `dd` into the current position in the document.
- To insert characters, you switch into a different mode, one called "insert
  mode". You can do this from normal mode by typing `i`.
- Finished inserting text? Press the escape key to flip back from insert mode to
  normal mode.
- More complex commands can be entered using "command mode". To move to it from
  command mode, type a colon.
- Like insert mode, one can switch back to normal mode using the escape key.
- From command mode, you can quit the editor by invoking the `quit` command.
  Once in command mode, just type the command you wish to invoke and press enter
  once done.
- All commands can be abbreviated; for example, few will type out `write` to
  write the file out or `quit` to quit Neovim. Instead, abbreviations can be
  used when they aren't ambiguous, e.g. `q` for `quit` and `w` for `write`.
  [Quitting is especially useful to
  know](https://stackoverflow.blog/2017/05/23/stack-overflow-helping-one-million-developers-exit-vim/).

This is the fundamental reason why vi-based editors are so ergonomic and
efficient: complex operations can be typed in a dedicated mode, meaning they
don't need complex combinations of modifier keys.

## In Praise of Lua

Is an editor truly to praise when it chooses Lua as its primary extension
language? A language infamous for defaulting to global variables and using
1-based indices for arrays, no less. Where are its classes? Why doesn't it have
built-in language support for namespaces?

On the contrary, I've come to believe it's a language that punches well above
its weight.

### Compactness Delivered with an Approachable Syntax

It's a _small_ language. In an era when almost every mainstream programming
language suffers from language committees adding constant features for the sake
of it, a small language that just stays the same is a blessing from a previous
era.  It's compact enough to keep in your head. Even the additions post 5.1 --
which [LuaJIT](https://luajit.org/) sticks to -- have been conservative.

Its syntax is simple. It has an ALGOL-style syntax using English keywords.
Despite the clear benefits of Lisp, its esoteric syntax is off-putting to
experienced developers and newcomers alike. And unlike Python, it hasn't added
so many unnecessary features that its word-heavy syntax has become a Python-like
word soup. Modern C-style languages tend to accumulate edge cases as they graft
increasing features [atop a core syntax not designed for
it](https://volatilethunk.com/posts/2019/01/11/lambda-syntax-in-mainstream-programming-languages/post.html).

### Simplicity in Scoping and Encapsulation

Apart from making variables global by default, its scoping system is
refreshingly simple. Unlike JavaScript, there's no [scope
hoisting](https://www.adequatelygood.com/JavaScript-Scoping-and-Hoisting.html)
or [temporal dead
zones](https://jsrocks.org/2015/01/temporal-dead-zone-tdz-demystified) to worry
about. It also differs from Kotlin, Java, and Swift in that there isn't a
laundry list of scope-altering features such as classes, structs, namespaces,
and statics. There's Scheme-like lexical scope (whose captured variables in a
closure can be modified by the [closure's
`fenv`](http://lua-users.org/wiki/EnvironmentsTutorial)), and there are tables
including one representing global variables. When one Lua snippet `require`s a
Lua file, the file can `return` a table of module entries at the end,
importing one module into the other without resorting to global variables.

Its metatables are flexible and powerful enough to implement most object
systems, reflection mechanisms, namespaces, and proxies. It's a single unified
data structure used ubiquitously across Lua. As opposed to JavaScript, the
language hasn't fell victim to committees constantly throwing in new features
that its built-in data structures can already provide.

### DSLs

Part of Lua's heritage rests in data configuration languages, which it
demonstrates with its concise data definitions. The syntactical sugar on top is
simple: tables and strings passed to functions can drop the parentheses; colons
can be used to pass implicit `self`s to functions stored in tables (i.e.
methods); and tables can drop square brackets and quotation marks from simple
string keys.

![By Alexandre Nakonechnyj (Graphic design) and Lua team (PostScript code) - svg from PostScript Source (see below) created from Lumu, Public Domain](https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/Lua-Logo.svg/720px-Lua-Logo.svg.png)

A few select pieces of well-targeted syntactical sugar make for a more elegant
language than those trying to hard-code in new syntax for every desired
feature.

### Concurrency

The asymmetric coroutine feature of Lua lets it to do concurrency without
littering code with `async`, `await`, `yield`, or `suspend` keywords at every
layer of the callstack. As editor extensions get increasingly complicated and
dependent on outside processes such as LSP servers, this is useful for
editor extensions.

This capability is [already being used
extensively](https://github.com/nvim-lua/plenary.nvim#plenaryasync) in the
Neovim Lua package ecosystem.

### Performance

LuaJIT is an impressively quick language implementation. While modern JavaScript
engines may surpass it, the same cannot be said for the de facto implementations
of Python and Ruby.

It is a target for other languages such as
[Teal](https://github.com/teal-language/tl) and
[Fennel](https://fennel-lang.org/), likely due to Lua's reach and LuaJIT's
renown performance.

## Configuring Neovim with Lua

Lua's website describes the language in depth. As Neovim uses LuaJIT, you should
check [the 5.1 reference](https://www.lua.org/manual/5.1/).

To configure Neovim, the first step is to ensure you have at least version 0.8. If
you're downloading from somewhere that traditionally has older versions of
software, such as Debian's repositories, double-check. If in doubt, get [the
latest stable GitHub release](https://github.com/neovim/neovim/releases).

Once you have installed that version, you can drop our new `init.lua`
configuration file in a few possible locations. Neovim respects the [XDG
specifications](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html),
so let's go for `~/.config/nvim/init.lua`.

### Global Options

Let's take a look at an example of some basic options:

```lua
local opt = vim.opt

opt.backup = false
opt.cursorline = true
opt.expandtab = true
opt.hidden = true
opt.hlsearch = true
opt.incsearch = true
opt.number = true
opt.path:append '**'
opt.scrolloff = 5
opt.shiftwidth = 4
opt.smartcase = true
opt.smartindent = true
opt.softtabstop = 4
opt.swapfile = false
opt.tabstop = 4
opt.textwidth = 80
opt.wildmenu = true
opt.wrap = true
opt.writebackup = false
```

`vim.opt` is a Lua table that stores global options, similar to the JSON-backed
properties in Visual Studio Code. In traditional Vi or Vim you'd set these like
`set nobackup` or `set tabstop=4`.

As a [metatable](https://www.lua.org/pil/13.html) it can do useful things such
as take array assignments for certain multi-value options or support appending
with method calls like `append`.

For those not used to the vi editor family, some of the option names may seem a
old fashioned, e.g. "shiftwidth". These can be researched individually; when
you're comfortable with what they do, the structure of the above snippet can be
followed to configure them. For example, `expandtab` determines whether spaces
or hard tabs are used for indenting, and `cursorline` enables highlighting on
the whole current line.

Some features are not exposed as options. For example, changing the colour
scheme is actually a command instead: `colorscheme blue`. You can tab-complete
in command mode, so tab after `colorscheme ` to see what other color schemes
come out of the box aside from `blue`. You can add third party colour schemes
alongside the preincluded ones.

Neovim documents [each of these
options](https://neovim.io/doc/user/quickref.html#option-list), to be browsed at
your leisure.

### Keyboard Shortcuts

Older editors tend to call keyboard shortcuts _keybindings_.

Neovim inherited Vim's notion of a "leader key". It means a single keybinding to
preface our own. It's similar to Emac's idea of non-standard keybindings being
prefixed with `C-x`. Vim's is more ergonomic; because Vim is modal, it means
modifier-less keys such as Space can be used as the leader key, opening up
combinations such as `Space-v` for, say, splitting a window vertically. It's
easy to hit with a thumb, and no pinky strain for modifier keys.

Let's define the leader key as space.

```lua
vim.g.mapleader = ' '
```

`vim.g` represents Vim's global variables. These are understood by the editor
itself rather than Lua -- Lua has its own notion of global variables. They are
also readable in command mode and VimL via a `g:` prefix, e.g. `:echo
g:mapleader`. `mapleader` is a global Vim variable that defines the current
leader key.

Let's now set some convenient keybindings to allow the likes of splitting the
window with just space followed by `v` when in normal mode:

```lua
local set = vim.keymap.set

set('n', '<leader>h', '<c-w>h')
set('n', '<leader>j', '<c-w>j')
set('n', '<leader>k', '<c-w>k')
set('n', '<leader>l', '<c-w>l')
set('n', '<leader>v', '<c-w>v')
set('n', '<leader>s', '<c-w>s')
set('n', '<leader>c', '<c-w>c')
set('n', '<leader>o', '<c-w>o')
```

Voilà! Now all of our window-splitting and navigation can be done with two
keystrokes each, one of which is usually under our thumb.

### Packages

To go beyond basic editing, we'll want some packages. Neovim can use most of
Vim's packages, bar a handful of very new ones that take advantage of Vim 9
exclusive features. But why would we use Neovim just to use packages written in
VimL? Thankfully, packages written primarily in Lua cover most of what we need:-

- [`packer.nvim`](https://github.com/wbthomason/packer.nvim): improved package
  management built atop Neovim's built-in package manager. We'll use this to
  install the remaining packages.
- [`nvim-tree.lua`](https://github.com/kyazdani42/nvim-tree.lua): a file
  explorer tree on the left-side of the editor.
- [`gitsigns.nvim`](https://github.com/lewis6991/gitsigns.nvim): markings on the
  left side for git additions, modifications, and removals.
- [`nvim-dap`](https://github.com/mfussenegger/nvim-dap) and
  [`nvim-dap-ui`](https://github.com/rcarriga/nvim-dap-ui): Debugger Adapter
  Protocol to provide integration with debuggers.
- [`telescope.nvim`](https://github.com/nvim-telescope/telescope.nvim): filter
  and select from a set of providers e.g. buffers, the filesystem, and ripgrep
  results. In plain English: a fuzzy finder for files and a nice UI for finding
  items among files.
- [`nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig): integrate with
  Language Server Protocol servers for your tech stacks of choice, table stakes
  for modern editors and IDEs unless they have enough clout to reimplement
  parsers for everything in-house such as Jetbrains.
- [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter):
  semantic understanding of code structure rather than crappy old 100%
  regexp-based systems. Provides modern, accurate syntax highlighting among
  other things.
- [`nvim-scrollview`](https://github.com/dstein64/nvim-scrollview): a scrollbar,
  but even in a terminal.
- [`barbar.nvim`](https://github.com/romgrk/barbar.nvim): modern tabs, even in a
  terminal.
- [`LuaSnip`](https://github.com/L3MON4D3/LuaSnip): a code snippets system.
- [`nvim-cmp`](https://github.com/hrsh7th/nvim-cmp) and
  [`cmp-nvim-lsp`](https://github.com/hrsh7th/cmp-nvim-lsp): autocompletion,
  integrated with LSP.
- [`lualine.nvim`](https://github.com/hoob3rt/lualine.nvim): a useful status
  line at the bottom of the editor.
- [`nvim-minimap`](https://github.com/rinx/nvim-minimap): a Sublime Text- and
  Code-style minimap, but it tucks itself into a corner rather than taking over
  a whole side of the screen.
- [`kommentary`](https://github.com/b3nj5m1n/kommentary): comment current lines,
  but with awareness provided by the likes of `treesitter`.
- [`neogit`](https://github.com/TimUntersberger/neogit): perform git operations
  easily directly from the editor. A shameless clone of Emac's `magit` mode,
  but why not? `magit` is superb, so it's the _right_ plugin to clone.

First, install `packer.nvim` to get enhanced package management.

```sh
git clone \
    --depth 1 \
    https://github.com/wbthomason/packer.nvim \
    "$HOME"/.local/share/nvim/site/pack/packer/start/packer.nvim
```

Declare the packages you're interested in. The declaration look like this:

```lua
local packages = {
  {
    'wbthomason/packer.nvim',
  },
  {
    'arcticicestudio/nord-vim',

    config = function()
      vim.cmd.colorscheme 'nord'
    end,
  },
}
```

Each package declaration is a Lua table, i.e. wrapped with braces. The first
string in the package is its name which states from where on GitHub to pull it;
use a full repository URI for non-GitHub git repositories.

A `config` function in a package configures the package after it has been
loaded.

Finally, configure packer and point it to your packages declaration:

```lua
vim.cmd.packadd 'packer.nvim'

local packer = require 'packer'

packer.init {
  git = { clone_timeout = 60 * 5 }
}

packer.use(packages)  -- Define `packages`
```

Plugin developers sometimes commit breaking changes. To avoid them, you can pin
commits and tags in the declaration:

```lua
local packages = {
  {
    'wbthomason/packer.nvim',
    commit = '3f950aeed3bd908e33fd59643e8f3be05b719df6',
  },
  {
    'arcticicestudio/nord-vim',
    commit = '8d8b9bf86bbc715a055b54cb53f0643fd664caa4',

    config = function()
      vim.cmd.colorscheme 'nord'
    end,
  },
}
```

Save the configuration using the `write` command, whose abbreviation is `w`.
Reload the configuration in the current editor with the command `source
$MYVIMRC`.  Finally, run the `PackerSync` command and the packages will be
pulled down and installed.

Unlike Visual Studio Code, many extensions need explicit initialisation code.
Sometimes it's a basic `setup` call like this:

```lua
{
  'lewis6991/gitsigns.nvim',
  version = 'v0.2',

  config = function()
    require 'gitsigns'.setup()
  end,
},
```

Other times, more complex configuration will be passed to the `setup`
function which will be documented in the extension's README:

```lua
{
  'nvim-treesitter/nvim-treesitter',
  commit = '34de06d4e8fc46090325dcaa3e8d74e295dd8ef1',

  config = function()
    require 'nvim-treesitter.configs'.setup {
      context_commentstring = {
        enable = true,
      },
    }
  end,
},
```

Once you know how to configure options and install packages in Neovim, combined
with knowing how to use vi family editors day-to-day, everything else is a
search engine query away. Of particular note are `autogroups` which allow
configuration specific to languages, e.g. using spaces to indent _except_ for
Go.

### Putting it All Together

My complete Neovim configuration [can be found on my GitLab
account](https://gitlab.com/louis.jackman/neovim-config).
It's part of a Dockerfile, meaning you can jump straight into it with Docker
using `docker run -it --rm -v "$PWD":/home/user/workspace
registry.gitlab.com/louis.jackman/dockerfiles/base-dev:0.0.23`.

Once Neovim is set up, it possesses all the features of a modern editor.
It's performant, has a decent extension language, supports LSP, is immediately
hackable, has ergonomic keybindings, runs over SSH and in a TTY attached to a
container, and roots its keybindings in the ubiquitous POSIX vi standard. Add to
that a growing ecosystem of fancy third party GUIs. Unlike modern Vim, its
ecosystem focuses on using one language well rather than using external
integrations written in anything under the sun from Python to Node.js and even
Deno.

If you'd like to keep up with Neovim, follow its [news](https://neovim.io/news/)
and [development](https://github.com/neovim/neovim).

