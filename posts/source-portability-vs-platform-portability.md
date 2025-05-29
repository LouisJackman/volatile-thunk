title: Source Portability vs Platform Portability
date: 2020-04-08 12:00
tags: clojure, c, java, web, plt
---
Avoiding vendor lock-in is one of the first concerns raised when proposing a new
technology at a company, and portability has subsequently become table stakes
for new programming languages. Not all forms of portability are the same
though, which has real consequences.

By adopting portable technologies, a company can more easily hedge its bets,
keeping the door open to changing cloud providers, operating systems, and
hardware architectures. Such changes are therefore made solely based on the
benefits and drawbacks for the company rather than due to lock ins removing
options from the table.

Or so the narrative goes. How many cloud provider migrations actually end up
being successfully pulled off _and_ end up saving money, enough to offset the
migration cost? And what benefit is OS portability on the server when Linux has
already become the OS lingua franca of modern technology services?

Regardless of the benefits of portability being overhyped for some
other technological solutions, the portability of common programming languages
is taken advantage of constantly and is something we take for granted. One of
the first questions levelled at new programming language projects is how
portable they are; language that can't, say, work on Windows, [are eventually
requested to do so by the
community](https://github.com/crystal-lang/crystal/issues/26).

## Why do Engineers Desire Programming Language Portability?

What makes developers desire portabilility to the point of making it a defacto
requirement of new languages? Programming languages are tools for expressing
problems, yes, but they also [shepard users towards a particular way of
expressing
computation](https://nibblestew.blogspot.com/2020/03/its-not-what-programming-languages-do.html).
If a developer's mindset is particularly amenable to that way, their
programming thought process _becomes increasingly dependent on using that
language_.

At that point, a developer considers it easier to choose a portable language
than to learn whole new programming paradigms and memorise new programming
language APIs for just migrating to a new OS or hardware architecture.

## What is "Portability" Anyway?

In the heyday of Sun Microsystem's Java marketing, a common catchphrase was
"Write Once, Run Everywhere". The sarcastic responses to this such as "Write
Once, Debug Everywhere" illustrates that portability is tricky.

Java, Unix, and the web are all seen as portable from various angles. Java the
language is compiled to a hardware-agnostic bytecode and this is run by Java
runtimes that exist for all major desktop and server OSes. Unix is standardised
in POSIX, which quite presumptiously terms itself the "Portable Operating
System Interface" and prescribes a very specific view of OSes that might be
objectionable to users of other OSes e.g. Plan 9, Oberon, VMS, or Windows. The
web takes a similar approach to Java, interpreting hardware-agnostic artefacts
and having itself being implemented across many platforms. The gap between
Java and the web has become even smaller with [the popularisation of
WebAssembly](https://volatilethunk.com/posts/2018/11/18/webassembly-a-security-engineers-review/post.html).

Weren't C and C++ also advertised as portable though? What gave Java such a
zealous advertising point here? Many portable platforms were implemented in C
and C++ themselves, the Java Virtual Machine and web browsers being prominant
examples.

Portability doesn't just mean one thing. It depends on _which_ component of a
technology is portable, and in which layer of portability it rests. A Windows
application that only runs on Windows is still portable by some definitions if
it can be cross-compiled from x86 to ARM. Is _everything_ portable if they can
be theoretically be run in hypervisors virtualising different chipsets to the
host? If not, do we draw a line at hypervisor-based virtual machines and not
programming language virtual machines? If so, why?

I've noticed that the clearest dividing line in portability is that between
_portable platforms_ and _portable source code_.

## Portable Platforms

**Examples: the Web, Java, .NET, Erlang/OTP**

When writing code for a portable platform, the code isn't itself portable. It's
tied to the platform. The platform itself, however, is portable.

These platforms often become the lowest common denominator of their targets,
making it inconvenient to take the fullest advantage of a specific system's
capabilities. However, there is less likely to be code that is conditionally
compiled for each underlying platform, giving fewer possibilities to debug.

The abstractions presented by these portable platforms remove the need to
understand each underlying system. Joel Spolsky's [Law of Leaky
Abstractions](https://www.joelonsoftware.com/2002/11/11/the-law-of-leaky-abstractions/)
indicates where this can go wrong. Once something fails in the lower-levels,
the developers who are dependent on the platform's abstractions are helpless.

Portable platforms are more likely to present a view of computation that is
misaligned with what's underneath, creating impedance mismatches.

They give the opportunity to target one paradigm well rather than several
poorly. A developer can master the DOM in browsers to maximise performance and
then target all underlying platforms with similar performance and stability
characteristics, or instead spread their learnings across the varying UI
toolkit paradigms of each platform, doing each with a divided understanding.

Sure, that Electron app might be sluggish, but if that same developer team with
the same amount of resources split their focus across UIKit on iOS, Android's
UI framework, Windows API on Windows, and GTK on Linux, would it _really_ be
consistently quicker and equally reliable across all of those platforms?

## Source Code Portability

**Examples: C, C++, Rust, Clojure**

Languages favouring source code portability seek to be compiled to multiple
underlying platforms. They are _directly_ portable rather than relying entirely
on a single platform to grant its portability.

Clojure is a complicated case. It is compilable to multiple platforms, but its
best supported targets are portable platforms: Clojure on the JVM and
Clojurescript in browsers. This is a design decision made on purpose; it
advertises its preference for host language VMs.

These languages are themselves portable but the libraries they often call out
to are often not. For example, C is one of the most portable languages ever
created, yet so much of the code written in it is dependent on specific
platforms. In a paradoxical way, the fact it can be so dependent on so many
specific platforms is actually a product of its portability.

As these languages don't prescribe a single platform's paradigm, instead
opening the door to integration with as many platforms as possible, they are
less capable of creating consistent, far-reaching portable APIs that insulate
the users from the underlying system. That's why these languages tend to have
smaller standard libraries. You needn't go for long in Clojure or Rust before
you have to start reaching for native libraries from the OS or the JVM, or
alternatively utilise third party portable wrapper libraries that others have
written.

To make semantics consistent, they often define an "abstract machine". This is
to ensure consistency in how the language acts when compiled to various
platforms with differing behaviours. C cheats here by handwaving a lot of
behaviours as _undefined_.

If an abstract machine becomes so strictly defined that each behaviour can be
depended upon on a wide range of targetted systems, then it itself is on the
way to becoming a dependable, portable platform and thus a [target for other
languages...](https://nim-lang.org/) At this point a language can transision
partially from a portable source language to a portable platform, or somewhere
in between.

## Hybrids

**Examples: Python, Ruby, Perl, Go**

What if a language's source code is directly portable, can access native,
underlying platform features eaily, yet still relies on bulky runtimes catered
to that specific language to insulate users from the underlying platform for
accomplishing at least simple tasks? These dependent runtimes might even be
external to the produced artefacts, such as Python, Ruby, and Perl, making them
closer to a portable platform like the JVM. They aren't really the same though,
for reasons I'll explain.

Python allows [accessing blatantly OS-dependent features like
`fork`](https://volatilethunk.com/posts/2018/02/12/unix-parallelism-and-concurrency-processes-and-signalling/post.html),
yet tries to hide away the underlying platform with a large runtime when it
can. These runtimes are large enough to become target platforms for other
languages, and the languages themselves often have [alternative
runtimes](https://en.wikipedia.org/wiki/IronRuby) such as Python being compiled
to the JVM via [Jython](https://www.jython.org/).

A key difference between a hybrid language and one with source code portability
is that former bundles or depends upon its own runtime, whereas the latter
delegates most of the work to one of many target platforms. Clojure might rely
on a garbage collector and runtime reflection, but it doesn't implement those
itself. It just mandates those features for its target platforms.

A cynic could argue that hybrid languages are the worst of both worlds. They
have neither the insulating effect of a grand unifying platform such as JVM,
nor the complete source portability of languages like C or Rust. (Such a
language can't just be cross-compiled to a new target; they must port whole
runtimes over too.) Real-world Python, for example, is heavily tied to CPython
semantics. This means it cannot realistically be compiled to another
non-CPython platform in many cases, yet still suffers the cost of non-portable
assumptions frequently [rising to the surface even in standard
libraries](https://docs.python.org/3/howto/curses.html).

Yet Go strikes a more useful balance between being cross-compilable to many
platforms, producing artefacts that work without dependencies, yet still has a
sophisticated runtime that acts as a portable platform between the user and the
underlying system for certain aspects like concurrency and non-blocking IO.

I will happily take flak from the Python community by stating that Go clearly
utilitised its hybrid portability model more effectively than Python. It
managed to do so while producing more portable artefacts that bundle the
runtime rather than requiring it to be installed on the user's machine, and the
runtime handles more useful work for the developers such as managing
non-blocking IO automatically.

## The Blurred Lines Inbetween

These are rough categorisations, mere back-of-a-napkin approximations. For
example, is Clojure's dependency on host VM runtimes really so different from
Python's effective dependency on the CPython runtime if it can also be compiled
to the JVM? How different is the C abstract machine from the JVM, exactly? Can
we reasonably draw a firm line between them when C++'s portable threading model
was inspired so heavily by Java's?

If we think about this too much, we might recall this snippet of wisdom
courtesy of Perl's manpages: all languages are interpreted, it's just a matter
of which level is doing the interpretation. Fully compiled languages are still
interpreted, they're just interpreted by the CPU rather than something higher
up.

My methodology for sorting the example languages isn't so much on technical
capability as community intent. Yes, Python can be cross-compiled to other
targets, but most of the ecosystem shows no interest in this and just sticks to
CPython. Clojure, by contrast, has had multiple first-class implementations for
a long time and has officially-blessed support for [cross-compiled portable
source code](https://clojure.org/guides/reader_conditionals).

Ruby bytecode is theoretically a target for other languages, but the community
isn't focussed on making it amenable as a target for other languages. The JVM
absolutely is however, adding major features primarily [for the benefit of
other languages targetting their
platform](https://docs.oracle.com/javase/8/docs/technotes/guides/vm/multiple-language-support.html#invokedynamic).

It's important when making such useful catagorisations to not get bogged down
in whether something _can_ be done. The more important question is whether
doing so is idiomatic, supported by the community, and works smoothly with
existing tooling and ecosystem assumptions.

## Which One?

Should we prefer platform portability or source code portability?

The answer is the same as many answers in computing: it depends.

Do you favour portability insofar as being able to dig deep into the
capabilities of each underlying system from the same codebase? Or do you favour
being able to free your mind from the concerns of every targetted system, being
able to centralise the design onto a single portable platform's paradigms and
traits?

Both yield positive economic benefits for a company depending on what it's
working on. Systems requiring deep integration into a system will benefit
primarily from source code portability, whereas systems that focus more on
solving a particular domain's problems in a way that can be acheived on common
hardware configurations and operating systems will benefit mostly from portable
platforms.

For example, an OS driver would be ill-suited for the JVM. To make such a
codebase useful is to tie it deep into the bowels of a specific platform, even
if various aspects of the code can be reused on different systems.

A CRUD app or a messaging backend would be able to take more advantage of a
single, portable platform. It wouldn't restrict capabilities since they likely
need only talk to a relational database or another language-agnostic datastore,
serve a web page, push messages to other services, and little else. Why not
simplify to a single portable platform in these cases?

## Be Careful of Claims of Portability

When languages advertise portability, check what sort of portability it's
offering. Choosing a language for one type of portability and getting another
leads to languages that a poorly suited to a domain. Python's portability is
very different from C's portability, both of which are also different from
Java's.

