title: The Distinct Niches of Go & Rust
date: 2019-04-18 12:00
tags: plt, golang, rust
---
Few debates in technology are more tribal and devoid of impartial logic than
programming language choices, but what happens when two languages are pitted
against each other despite not particularly overlapping?

Go and Rust find themselves often compared. Perhaps it's due to the similar time
at which they became well known, the fact they both bucked the 2000s trend
of running on language virtual machines or transpiling and instead compiling
directly to native code, or their targeting of application development in niches
already covered well by C++.

However time has seen the perception of them grow apart, being seen as belonging
to different areas and solving different problems. A shared similarity between
them is that they were a response to the problems of common languages in the
same way that those languages were a response to their predecessors.

## The Failed Promises of Language Virtual Machines

C++ for application development had serious problems that made it ripe for
disruption. Although direct memory management is important for systems
programming, it was increasingly seen as an unnecessary burden for applications
development throughout the 2000s. Hardware sped up, garbage collection
technology improved, and the stereotype of hardware agnostic runtimes like .NET
and Java having bad performance waned.

In this environment it became increasingly difficult to justify segfaults,
convoluted build tools, rebuilding the same source for several hardware
architectures, and using anachronistic holdovers from the 1970s like header
files.  Object oriented programming was the new software architecture du jour and
the appetite grew for languages that used it as their native paradigm from the
ground up.

Java and later C# arose from this frustration. They offered memory safety, well
defined access to threads, portable bytecode that could target several hardware
architectures transparently, and modern languages with cleaned up semantics.
They sold themselves as having native object orientation from the ground up, as
much as Smalltalk developers might disagree with their claim. They purported to
serve as language agnostic runtimes, offering more portability guarantees than
informal C ABIs.

Given these promises, why are services increasingly turning to technologies like
Go and Rust in preference to these virtual machine-based languages?

Rust actually doesn't compete as much with them as Go does. Rust's competitive
turf is more in the domain of development that doggedly stuck with C++ while
application development began to migrate away from it, primarily systems
development.

Go itself increasingly competes with these technologies though. It can be
oversimplified to a few points: the consolidation of hardware architectures,
discontent with object oriented programming, the problems of multithreading
becoming more apparent, and the slowing down of hardware speed ups over recent
years.

Most developers for backend code target the x86-64 instruction set (a.k.a
AMD64), while most client code targets ARM. In practice they don't "target"
anything since it's mostly invisible; frontend JavaScript hardly exposes the
underlying architecture and .NET and OpenJDK don't expose too many oddities
of their underlying server hardware. The benefit of portability afforded to
developers by portable bytecode formats is not as important as it once was.

Limitations of object oriented programming became apparent, not because it's a
bad paradigm but because for many years the industry treated it as a silver
bullet to solve all of their woes rather than as just another tool.  Needless to
say this dream did not materialise. Several parts of Gang of Four-inspired OOP,
such as concrete inheritence and a loss of focus on data representation, are now
seen by many as fatal missteps that took the industry backwards.

Java offered support for native threading in a portable way, which was a fresh
idea at its time. While this was a good step for the industry, allowing us to
understand the importance of well defined memory models in the face of
concurrency, it turned out that exposing operating system threads in such a
direct fashion exposes frustratingly low-level, error-prone details to
developers such as memory fences and atomicity of data manipulation.

Moore's law didn't materialise to the degree that was expected by many, meaning
the cost of garbage collection, just in time compilation, and reflection wasn't
offset as far as expected.

Language VMs never really managed to replace the C ABI as the lingua franca for
cross language communication; the JVM must still go via one of the many
informally-specified C ABIs to communicate directly with CPython or Node.js.

In the same way that the virtual machine languages Java and C# addressed the
problems of their predecessors, so did the next generation of languages.

## The Revenge of Natively Compiled Languages

When Go came onto the scene, it promised more usable concurrency primitives,
direct native compilation with statically linked libraries, more direct control
over memory layout and addressing, a less dogmatic approach to organising code,
and a lightweight programming model provided by modern PLT advancements like
type inference and the cleaning up of two decades of legacy language baggage.

When Java and C# developers were knee-deep in thread pools, executor services,
callback hell and resolving the friction between asynchronous and synchronous
APIs, Rob Pike gave a compelling talk that showed how Go can strip concurrency
back to the model programmers had in their head: concurrent operations running at
the same time, tasks that were allowed to just wait for things like socket reads
without needing to `await` anything, and a focus on "sharing memory by
communicating rather than communicating by sharing memory". Developers saw this
as an antidote to synchronised blocks, critical regions, thread pooling, and
complex composition of asynchronous operations. That isn't to say it removed the
need for those constructs, but that it deemphasised them for simple cases.

At the time of sprawling build tooling complexity like Ant, Gradle, "Maven shade
uberjars", competing .NET runtimes on Windows devices, and client-side Java
generally not taking off as expected, producing a single executable with
statically linked executables was an easy sell. When most Java code on the 2010s
was running on AMD64 Linux, an additional layer such as the JVM in between the
code and the underlying platform became less of a useful portability layer and
more of a distraction and a potential failure point due to the law of leaky
abstraction.

## Meanwhile, Rust Chips Away at Development that Never Left C++

While Go continues to serve as an alternative to the virtual machine languages
Java and C#, Rust carved out a rather different niche. Coming from the
frustration at writing browser code in C++, Rust tries to solve its problems
without layering in excessive abstractions that render it unable to serve in the
same domain as C++. Garbage collection, reflection, and excessive dynamic
dispatch don't lend themselves well to systems development, so Rust had to avoid
them for the same reasons as C++.

Rust sought to raise the level of abstraction above C++ to reduce the cognitive
burden for developers, but to do so in the compiler rather than the runtime. To
that end, Rust adoped more refined compiled-away nicities like generics and
lambdas, elegant notations for existing runtime conventions like using sum types
rather than manually discriminated unions, and a more expression-based syntax.
The crown jewel of Rust is its borrow checker, inspired by the likes of Cyclone,
which allow it to advertise memory safety without mandating garbage collection.
This is Rust's "killer app". While C++ is a multi-pardigm language with decades
of history and support for many paradigms, Rust looks like an ML dialect geared
towards systems programming with an interesting but efficient memory management
strategy. It's more focussed, providing an OCaml-like language melded with a
more rigid form of C.

Due to this, Rust has something C++ and especially D never had: a clear, simple
narrative from the very start about the areas it targets and how it expects its
developers to do it. It doesn't aid developers in using the paradigm they're
most comfortable with: it tells them to use functional and procedural
programming, specifically an efficient intersection of the two focussed on
zero-cost compile-time abstractions, or to otherwise hit the highway and use
something else.

One of the reasons Rust could so quickly match C++'s performance is due to LLVM,
the Low Level Virtual Machine. Contrary to its name, it isn't really a virtual
machine as most expect. Its "virtual machine" is a language agnostic low level
representation that languages like C++ and Rust can target, which then turns
into efficient machine code independent of the source language. This allowed
Rust to quickly piggy-back off many deep C++ optimisations that had been
embedded into LLVM over the years to be benefit the C++ compiler Clang.

## The Costs and Benefits of Runtimes

For Rust and Go, the best point of comparison is their runtimes. Nothing else so
clearly distinguishes their different target domains. Go's larger runtime,
especially its garbage collection and automatic management of blocking system
calls and kernel threads, makes it clear that it's competing with C# and Java
and not with the über optimised native code that makes up browser engines,
operating systems, and embedded systems. While that might not have been the
intent of their designers, it's how it played out.

It's worth detouring for a moment to point out that operating systems _can_ be
written in languages with large, helpful runtimes. Various Lisp dialects and
Oberon are testement to that. However the perception is that such work is done
in languages without large runtimes, and that perception is enough to give
languages like Rust, C++, and C an edge in those areas.

The lack of a large runtime gives Rust the edge over Go in these areas, but
also gives Go the edge over Rust in the pursuit of replacing C# and Java for
application development, especially web services. The borrow checker is a
wonderful piece of technology, but is that a cognitive burden application
developers should deal with when they could just delegate to a garbage
collector?  Is Rust's lack of a large runtime really worth needing to manually
manage asynchronosity for blocking system calls across an entire application?

## The Twain Shall Coincide for the Foreseeable Future

This article could have detailed the fundamentally different approaches to PLT,
programming language theory, taken by the two languages. A modern systems ML
dialect with a formalised RAII model verses the spiritual successor to Alef most
at home within a Plan 9 system. The very different approaches taken between
pragmatic systems engineers steeped in Unix heritage and the programming
language theorists working on a browser engine who wielded a strong
understanding of functional programming.  While there's an interesting future
article about that, this isn't it.

The runtimes themselves are enough to guarantee that the languages will have
substantially different niches for the foreseeable future. There will be a cross
over to be sure, the no man's land in which the fanboys and fangirls of both can
scrap, but they will mostly serve different areas with distinction.

Do you want your blocking system calls and memory managed automatically or not?
That one question can usually be answered trivially when considering the domain
in which you're working, and it'll spell out which one you should use.

