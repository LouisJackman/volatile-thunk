title: Syntax Highlighting and Remote Code Execution: Why Developers are an Easy Target
date: 2018-08-25 12:00
tags: security, development environments, editors, ides
---

We chastise our relatives for installing unheard-of apps onto their phones, yet
we execute thousands upon thousands of lines of untrusted code on our laptops
every time we run `npm install` or update our text editor plugins.

At least that dodgy Candy Crush clone is running in an iOS or Android sandbox.
What about that Visual Studio Code extension so many just installed because
that Rockstar Developer on Twitter recommended it with a muscle-flexing emojii?
Did they check it didn't invoke
[`fs.readFile`](https://nodejs.org/api/fs.html#fs_fs_readfile_path_options_callback)
against their SSH keys and use the standard [`http`
module](https://nodejs.org/api/http.html) to upload them to the Maltese mafia?

Of course we didn't; we never do. Perhaps we should lay off patronising our
relatives about their seven browser toolbars until we get our own house in
order.

My only defense against someone compromising my machine via a text editor
plugin is VimScript being so horrible that even the most dedicated adversary
would throw their laptop out of the window before completing a successful
exploit.

***

Let's assess the extent of the problem through the setup process of a new
developer.

They install their OS of choice along with a package manager. Assuming Homebrew
on macOS, that already means any compromise of GitHub or any one of the Homebrew
developers leads to RCE over countless developers' machines. The encouragement
to update frequently means even a short window of compromise will hit many
users.

An editor or IDE is installed: VSCode, Atom, Sublime, IntelliJ, PyCharm, Vim.
They pile on the plugins for the tech stacks they use: better autocomplete for
Go; the Redux plugin that heavily-clapped Medium post mentioned; the ESLint
plugin brought up at the last JS meetup.

Installing them is easy. Auditing them is harder. Worst of all, isolating them
from sensitive data on the rest of your computer is far more difficult than it
should be.

***

We're suspicious of piracy websites with nefarious scripts despite their running
within a sandboxed browser, yet we happily install random Homebrew recipes that
lead to arbitrary Ruby code running under current user privileges. Still, at
least Homebrew recipes are usually small and easy to audit. A bad actor
uploading nefarious software to Homebrew's GitHub would hopefully be quickly
spotted.

Editor plugins and software libraries are another matter entirely.

Install software packages via the likes of `npm` and `pip`, and a large tree of
subdependencies is resolved. That expands the authors of the dependency code
running on our machine from dozens to hundreds or thousands. That's thousands of
developers with varying incentives, security postures, knowledge of secure
programming, and even ethics.

The attack surface for exploiting your development environment went from
just your machine to the lowest common denominator of your machine, the
machines of those thousands of developers, and all third parties in between.

The credentials of an author behind a popular library like JavaScript's
`lodash` or Python's `requests` being stolen [is a serious
possibility](https://twitter.com/kennethreitz/status/869408310998552576); it
has been attempted before with [varying degrees of
success](https://eslint.org/blog/2018/07/postmortem-for-malicious-package-publishes).
Even a couple of hours passing before the compromised asset is withdrawn would
lead to compromised libraries being baked into innumerable Docker images, being
fixed in package lock files, and being pushed to production environments all
over the world.

ESLint was compromised with the subtlety of a drunkard brawling outside a
British town centre at 2am, brazenly `eval`ing content from Pastebin.  While I
applaud the quick responses of the teams backing these compromised OSS projects,
a job they do for free in their spare time lest we forget, what does it say
about the impact of a sophisticated, stealthy compromise from an adversary worth
their salt?

What about one that doesn't force push over the version control history,
doesn't lock out other developers from accounts, just subtly modifying a
pending commit with an obfuscated vulnerability? Remember that OpenSSH [was
compromised](https://www.exploit-db.com/exploits/21314/) by nothing more than
an off-by-one error. Are we confident the developer community would find it
quickly, or would it sit around uncovered for years like Heartbleed?

***

Text editors and IDEs are another area we developers must be frank about. It has
all of the problems of libraries but with additional nuances. Most editors have
no proper isolation for their plugins. If a new ELisp package is loaded into
Emacs, that code can do anything under current user privileges including running
`(call-process "rm" nil nil nil "-fr" "/home")` or `fset`ing the password entry
function of ELisp to replace it with a version that sends off its passwords to
a remote server. These Emacs-specific example can be replicated in any modern
editor like Visual Studio Code, Atom, or Brackets.

That said, Emacs is especially vulnerable because, unlike most other editors,
its users tend to use it as a hardware agnostic "operating system" too. This
would be fine except for the fact that the Lisp Machine model that inspires
Emacs has no understanding of modern security: everything is mutable, allowing
any package to overwrite or intercept code in any other package. There's no
process isolation or access control. That syntax highlighting package you just
downloaded has the ability to overwrite parts of TRAMP to inject SSH commands
into the remote servers you log in to and tamper with emails you write in GNUS.

(I lament the lack of a modern, secure, GUI-first Lisp Machine-inspired
development environment. That will be the focus of a future post.)

***

With companies pushing agile development and DevOps, it's increasingly likely
that developers have keys to the kingdom or at least some important parts of it.
The move towards smaller teams with full ownership over their microservices
means compromising one developer could easily could lead to gaining access to
datastores with personally identifiable information.

Software developers have an increasingly large red target painted on their
backs. The attack surface is growing as we turn to ever-growing piles of mostly
unaudited packages, libraries, and plugins for developing. The assumption that
non-technical staff must follow security guidelines but technical staff "already
know this stuff so needn't bother" has never been more dated.
