title: A Brief History of Text Editors: from Vi to Visual Studio Code
date: 2021-10-09 12:00
tags: vim, neovim, lua, viml, vimscript, editor, editors
---
Despite the proclamations from visual software design tool advocates in the
'90s, simple text has remained the mainstay of code manipulation for software
engineers. The humble text editor has accordingly retained its status as one of
the key tools for a modern technologist, ranking alongside the anachronistic
terminal and the not-so-humble web browser.

Historically, line-based editors such as
[`ed`](https://en.wikipedia.org/wiki/Ed_(text_editor)) allowed basic interactive
text manipulation. They were finicky enough that "real-time" editors were
invented, a phrase still used by [Emacs](https://www.gnu.org/software/emacs/) to
advertise itself today. Modern developers take for granted the ability to modify
a document in real time as it is displayed in front of them, which is a leap
forward in usability from what came before.

Throughout the late '90s and early Noughties basic UI conventions became more
consistent, such as the keyboard shortcuts for copying and pasting text.
Integrated Development Environments (_IDEs_) became more popular, normalising
tools that had a greater in-built semantic understanding of code and also of
larger-scale structure in sprawling codebases.

The last decade has blurred the line between basic text editors and IDEs. IDE
UIs have become more lightweight. They have more immediate flexibility.
Traditional editors have accrued both built-in and optional additions that move
them closer to IDE functionality. Meanwhile, the definition of IDE has evolved:
while basic auto-complete and syntax highlighting sufficed in the early
Noughties, deep semantic understanding of various languages and extensive
automated refactoring support became table stakes due to the likes of
[IntelliJ](https://www.jetbrains.com/idea/).

Let's detour into the earliest editors still in use today and compare them to
contemporary offerings.

## Early Real-Time Editors

[Vi](https://en.wikipedia.org/wiki/Vi) and Emacs predate the era of more
standardised keyboard shortcuts and UI fundamentals. Where is Control-C or
Command-C for copying text? What is Vi's "insert mode" and why is it necessary?
Why does Emacs talk about "kill rings" and "the meta key"?

![The ADM-3A, whose keyboard inspired Vi - By Chris Jacobs - Own work, CC BY-SA 3.0](https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Adm3aimage.jpg/730px-Adm3aimage.jpg)

Vi and Emacs represent a fork in the road of computing evolution that other
tools didn't take. That means both needlessly different conventions from what
developers are used to, but also a gold mine of text-editing concepts that were
left untapped by modern editors.

### Archaic yet Composable Keybindings

Standardising on the likes of Control-C for copying and Control-Z for undoing
was a boon for UI consistency but cemented artificial constraints; if we
allocate Control-X for cutting the current selection, how do we add new "nouns"
to that "verb" without violating the user's UI expectations? We might want to
cut whole paragraphs or just inside the current pair of HTML tags. Users don't
expect additional keystrokes before the Control-X, nor do they expect a delay
afterwards in which they use a follow up key to select a "noun".

Vi and Emacs both have _composability_ of keybindings that goes beyond most
other editors. At the start of a line, Emacs can delete the line with Control-k.
Or rather, to use Emacs parlance, a user can kill the line with C-k. However,
the user can prefix it with Alt-4 to delete the rest of the current line and
three more lines ahead too. Vi refines such key composability into an art form:
`3dd` to delete three lines; `c}` to delete until the end of the paragraph and
activate "insert mode"; and `y2i(` to copy all text inside the set of
parentheses outside of the current set.

Vi and Emacs don't throw text into the void upon deletion. They "cut" text by
default and move it onto a growing stack of deleted text fragments that can be
summoned back at will. Emacs calls it a "kill ring", vim the "delete registers".
Keystrokes such as `"7p` can then paste the 8th last cut item (counting from 0)
back into the current document. Control-V can't work for this as it has no
standardised way of selecting _which_ old cut selection the user wants to bring
back, never mind "named registers" by which vi and Emacs can cut text into any
storage location with a dedicated name.

There are half-hearted attempts to better support more standard shortcuts in the
older editors, such as Emacs's `cua-mode` or Vim's "easy mode", but they've
never been made default or embraced in later versions.

## Extension Languages: Emacs Lisp & VimL

Apart from composable yet now-unfamiliar keyboard shortcuts, another feature
stands out in Emacs: [an _immediately accessible and powerful_ extension
language](https://en.wikipedia.org/wiki/Emacs_Lisp) from day one, at least in
the case of GNU Emacs. Vi didn't have this but one of its descendants,
[Vim](https://www.vim.org/), added one: [VimL (aka
VimScript)](https://en.wikipedia.org/wiki/Vim_(text_editor)#Vim_script).

Early editors usually didn't provide means of extension from within beyond
modifying its own source code and recompiling. Emacs and Vim were somewhat
unique in that regard. Later editors did provide similar capabilities: Sublime
text allows extensions in Python, and IDEs such as Eclipse provide plugin
systems.

![The Space-cadet keyboard that influenced the design of Emacs - By Retro-Computing Society of Rhode Island - Own work, CC BY-SA 3.0](https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Space-cadet.jpg/1280px-Space-cadet.jpg)

Even with the growing popularity of such IDE plugin systems, Vim and Emacs stood
out for the _immediacy_ of their extension languages.  Eclipse would need a
Java-based plugin to be compiled and loaded into the IDE, whereas Emacs would
allow custom Lisp to be fed into the current environment with nothing more than
an `Alt-:`. IDEs often bifurcate capabilities into powerful built-in features
and limited features exposed to plugins; meanwhile, Emacs allowed any
user-defined Lisp to modify and "advise" even the deepest ELisp code in the
bowels of the system.

VimL doesn't go so deep. More of the C core is off-limits to VimL than ELisp in
Emacs, which is partially due to more of Emacs being written in ELisp to start
with. However, VimScript still possesses that immediacy.

## The Modern Contender: Visual Studio Code

Modern editors edge closer to Vim and Emacs, carrying more accessible extension
languages. Atom jump-started the popularity of
[Electron](https://www.electronjs.org/), formally "atom-shell", popularised the
idea of running editors on web technology, and allowed extensions in JavaScript
with fewer formalities.

Visual Studio Code took Atom's concepts and packaged them up in a more complete
user interface with fewer performance problems. While Atom eventually addressed
some of its biggest performance woes, the perception had already been set in
stone; Visual Studio Code emerged as the successor of the two.

![Atom, a strong influence on Visual Studio Code, and populariser of Electron upon which Code is based - By GitHub - Attached with Ticket:2019102510008114, MIT](https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Atom_screenshot_v1.41.0.png/1207px-Atom_screenshot_v1.41.0.png)

Code, as Visual Studio Code is more idiomatically known, does have more
bureaucracy for loading in custom code. It needs declared extensions rather than
something as immediate as Emac's `Alt-:`. However, it got several things right
that Vim and Emacs did not: it uses a mainstream language for extensions; it
isolates extensions in separate processes to force asynchronous operations and
to enforce isolation from the editor core; and it has a culture of pressuring
extension authors to make their extensions "just work" rather than requiring
snippets of code to be pasted into a configuration file.

Its extensions don't block the UI because they mostly cannot: they're not
running in the same thread as the UI. There are perks of letting extensions,
or "modes" in Emacs parlance, modify everything in the editor. Yet, Emacs
extensions can perform dangerous tasks like tampering with core editor
functions on a whim.

The culture surrounding Vim and Emacs has normalised the dropping of random
snippets of ELisp or VimL into editor configuration files to set up extensions.
This raises the bar beyond Code, which has aggressively sought to
"auto-configure" extensions as much as possible.

A developer of the last decade, even a senior, is more likely to be familiar
with JavaScript and TypeScript than ELisp or VimL. Even if they are willing to
learn a new language, it's not an effort they're spending _solely_ on their
editor: JavaScript is ubiquitous outside of Code.

While ELisp is a well-designed language -- it is a Lisp dialect, after all --
VimL isn't so much. It has organically grown from vi's command mode and
accrued some questionable characteristics en route.

## Choosing an Editor

With myriad editors to choose, how does a technologist decide? While I can't
speak for others, I can detail my decision-making process that led to the editor
I use today.

### Emacs's Problems

If ELisp is a decent language, why not use Emacs and call it a day? After all,
it has powerful modes such as [`magit`](https://magit.vc/) and
[`org-mode`](https://orgmode.org/). ELisp now has native compilation and lexical
scoping. The package manager has been around for a while and is well supported.
Lisp macros are a sublime programming tool, which ELisp supports via its
MacLisp/CL-style unhygienic
[`defmacro`](https://www.gnu.org/software/emacs/manual/html_node/elisp/Defining-Macros.html).

Yet there are problems:-

- The keybindings require holding too many modifier keys, increasing strain on
  the wrists.
- The keybindings don't use modern standards such as Visual Studio Code's, but
  also aren't encoded in ubiquitous standards like Vi keybindings being in the
  POSIX standard.
- An insufficiently composable vocabulary for dealing with text. Basic
  composability exists: `Ctrl-U` can be used as a "universal argument" to shift
  a keybinding into an alternative mode, and numbers such as `Alt-10` can be
  used to repeat operations several times. Yet it simply has nothing on Vim
  which possesses an entire verb/noun vocabulary. Do you know the noun for
  inside a HTML tag (`it`)? What about the verb for deletion (`d`)? Then you
  already know how to delete everything inside the current tag (`dit`).
- ELisp is not used anywhere outside of Emacs. That means accumulated knowledge
  about ELisp is inapplicable anywhere else.
- There's no architectural distinction between the editor core and UIs. New GUIs
  essentially must be created in the main Emacs repository itself.
- `evil-mode` emulates the better keybindings from Vim, but integrating it into
  every mode you use is an endless game of whack-a-mole. Perhaps there are
  `evil` packages for each mode you use. Maybe something like `evil-everywhere`
  covers it.  However, these approaches never have 100% coverage; you need to be
  conscious of switching back to Emacs keybindings when you encounter an area
  that was missed.
- Unlike Code, extensions often don't work out of the box and need too much
  ELisp configuration to get basic features working. This is more of a cultural
  problem than a technical one.
- Antiquated terminology that increases the barrier for new developers: yanking
  rather than copying; killing rather than deleting; meta rather than alt; and
  keybinding rather than keyboard shortcut. Unlike Vi, these terms are not
  codified in an influential standard like POSIX with which operation types
  should already be familiar.

### Visual Studio Code's Problems

An editor with modern conventions, bold technical choices such as isolating
extensions properly, and bolstered by a lively ecosystem. Why isn't it the
obvious choice?

- It's entirely dependent on web technology. The modern web stack is such a
  behemoth that no individual can stay abreast of its architecture. Its
  implementations became a monoculture, with the demise of Edge's own rendering
  engine and the decreasing market share of Firefox. I wouldn't base a program
  as focused as a text editor on it. By contrast, Vim and Emacs only need a
  terminal, but also support GUIs if desired. Being able to run those editors
  over SSH or in a container with an attached TTY is useful.
- A lack of immediacy for its extensions. In Emacs, one can insert arbitrary
  ELisp code with `Alt-:`. With `Alt-X ielm Enter`, one can jump straight into a
  REPL and start hacking away at the editor. This is a far cry from Code, whose
  extension need more ceremony.
- JavaScript. Unlike many developers, I don't meme about how much I dislike
  JavaScript. I actually like it as a result of reading Douglas Crockford's
  works over the years. However, it is becoming a design-by-committee language
  that is piling in feature after feature. It's so far from the minimal
  macro-less Scheme-in-ALGOL-clothing that ECMAScript 3rd and 5th edition got
  close to. Keeping up with JavaScript is now a long-term commitment.

### Vim's Problems

It has ergonomic keybindings, supports running within just a terminal, and has
stood the test of time. However, it has its own insurmountable problems.

- Like Emacs, its keybindings aren't standard. Unlike Emacs, they're offset by
  both ergonomics and being encoded in the POSIX vi standard, meaning operation
  types should be familiar with them due to ubiquity.
- VimL is baroque, aged, and haphazard. Even if it were a language that evolved
  elegantly like ELisp, one can still not transfer gained knowledge about it
  outside of the editor.
- The future direction is making an incompatible Vim 9 dialect of VimL rather
  than embedding a proper language. The problem will get worse, not better.
- A weak separation between the UI and the editor core. It comes with various
  GUIs in the form of GVim. They're built in and there isn't a well-established
  culture of using a standard protocol between the editor core and the UI. As
  such, there are fewer third party GUIs that can evolve independently.
- A general lack of boldness in designing new features. Vim added asynchronous
  operations, channels to communicate between them, and an embedded terminal.
  But this was only done after Neovim had already beaten Vim to it.
- Similar to Emacs, it has a culture of extensions needing configuration
  snippets to get the basics working, rather than just working out of the box.
- Questionable technical decisions being made by leadership. See this [GitHub
  thread in which they justify keeping dodgy crypto in the editor
  core](https://www.gnu.org/software/emacs/manual/html_node/elisp/Defining-Macros.html).

## Settling on Neovim

[Neovim](https://neovim.io/) is a fork of Vim that appeared in 2015. Recently it
released version 0.5.

Put succinctly, Neovim 0.5 fixes enough flaws in Vim to make it the most
compelling choice for me in 2021. Unlike Vim, it uses a well-designed language
that is usable outside of its ecosystem: [Lua](https://www.lua.org/). It has
created a decent separation between its core and UIs, creating a blossoming
ecosystem of third party GUIs such as
[nvim-gtk](https://github.com/daa84/neovim-gtk). It has shown boldness in
pushing things forward, such as building in LSP support and supporting full
configuration with a non-VimL language.

Another development of the 0.5 release was the ability to configure even more
with Lua. Lua can now be used for all configuration -- bar a few inline Lua
strings containing VimL needed for some holdouts such as `autogroup`s. LSP is
built in, avoiding frameworks like `coc` that want to bring an
entire Node.js runtime into the picture.

For a while I stuck with plugins that were compatible with both Vim 8 and
Neovim. Now I've now gone all in on Neovim with a Lua configuration and
a collection of Lua-only plugins.

## The Future of Text Editors

Putting aside my own text editor decisions of the present, what does the future
of text editing look like?

Text editors will likely gain more awareness of isolated development
environments, to aid both [security of development
environments](https://volatilethunk.com/posts/2018/08/25/syntax-highlighting-and-remote-code-execution-why-developers-are-an-easy-target/post.html)
and general project environment reproducibility. [Visual Studio Code is leading
the way here](https://code.visualstudio.com/docs/remote/containers); its team
aren't the first to think of such an approach, but they're making it
_accessible_.

Emerging libre text editors continue to explore the perks of modal editing,
including [Kakoune](https://kakoune.org/), [Helix](https://kakoune.org/), and
[vis](https://sr.ht/~martanne/vis/). While Vim's modal editing is ergonomic,
it's ultimately rooted in '70s keybindings from Vi. Can technologists refine the
modal editing paradigm for the 21st century?

![A Smalltalk variant showing code being modified visually rather than as lines of text - By Marcel Taeumel - https://squeak.org/, CC BY 4.0](https://upload.wikimedia.org/wikipedia/commons/1/1d/Squeak_51_morphic_interface_screenshot.png)

The gap between local and remote editing will blur, likely driven by the ability
to easily run web-based technologies both locally and on a remote server. Again,
Code leads here: Microsoft is pushing [remote Code instances along their GitHub
product](https://devblogs.microsoft.com/visualstudio/introducing-visual-studio-codespaces/).
Such environments are less hassle than configuring a local environment from
scratch. They let a company more easily apply mandatory security controls and
Data Loss Prevention. Sadly, this will likely lead to a reduction in software
engineers choosing local tools according to personal taste. How can new editors
and subsequent text-editing paradigms emerge in a world when companies force
pre-configured remote text editors onto engineers?

There has been a growth in tools that inspect languages via ASTs.
Auto-formatters that reparse the AST to emit normalised versions are now the
norm. Language ecosystems increasingly provide tools such as [.NET's
Roslyn](https://docs.microsoft.com/en-gb/dotnet/csharp/roslyn-sdk/) or
[tree-sitter](https://tree-sitter.github.io/tree-sitter/) that understand
programming languages as nodes to rearrange rather than as opaque blob of UTF-8
text. Editors will follow this approach. Perhaps the Smalltalkers' dream of
moving beyond plaintext representation for code will occur gradually, with the
underlying text increasingly becoming just a serialisation layer for text
editors to load before providing a more semantic view of the structure.

Here's hoping that Neovim's Lua plugin ecosystem can keep up with these seismic
changes in text editing over the next decade, otherwise I'll have to waste time
acclimating to yet another new editor.

