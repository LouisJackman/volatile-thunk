title: Skipping Expensive Security Checks with JIT Compilation
date: 2019-02-02 12:00
tags: plt, appsec, security, webassembly
---
For all of the proclamations about using C for "performance reasons", its lack
of safety has inflicted performance penalties on contemporary systems that must
be paid by programs written in all other languages.

Blaming C for this is unfair though. The real culprit is machine code
still being the primary delivery format format for executables on mainstream
operating systems. They might alter some addresses and put their own executable
format header on top, but even with all of the OS-specific executable format
additions, a significant amount of distributed executable code is still machine
code provided directly to the CPU.

The delivery format therefore assumes the lowest common denominator of modern
computing: the [Von Neumann
architecture](https://en.wikipedia.org/wiki/Von_Neumann_architecture) with
plenty of CPU architecture edgecases, such as the massive complexity and legacy
of the x86 instruction set.

## The Problem with Machine Code as a Distributed Application Artefact

The CPU and OS must assume that the code doesn't properly split procedure
stackframes and data stored on the stack, allowing them to mingle in the same
space. They must assume that the source language is sufficiently under-specified
as to allow user-created buffer overflow to overwrite otherwise unrelated
variables and potentially tamper with control flow. They must assume that the
source language has no notion of safe data primitives that the rest of the
program is built on top of; the worst-case scenario of raw memory addresses being
conjured out of thin air and dereferenced must be anticipated.

Historically OSes and CPUs have allowed such behaviour, reasoning that it is
the job of the programmer to check their code does not misbehave and the role
of the user to ensure only trusted programs run on their OS. This view, still
unfortunately held by some of the "old guard" across various computing
communities, has thankfully waned in recent decades.

Memory protection is ubiquitous in modern operating systems, aided by support in
underlying CPUs such as the x86's memory protection. Operating systems have also
added W^X (write XOR execute), a.k.a. DEP (data execution prevention) support to
stop memory corruption allowing the writing of new code and its subsequent
execution in running processes, an attack that allow sliding nefarious behaviour
into the security context of a trusted running process. Other examples include
stack canaries for detecting stack corruption, randomising addresses to
frustrate exploit reproducability via ASLR (address space layout randomisation),
and even updating compilers or rewriting code as it executes to frustrate
control flow attacks and return-oriented programming.

While not fixing all memory safety problems of C programs, which is practically
impossible, they do an admirable job at frustrating adversaries, eliminating
whole subcatagories of memory safety attacks, and most importantly isolating a
compromised process from serving as a pivoting point to attack the rest of the
system.

---

This isn't a free lunch though. Most of these mitigations incur runtime
performance costs. Even more costs pile up if such mitigations are revealed to
[not actually
work](https://en.wikipedia.org/wiki/Meltdown_(security_vulnerability)) and then
need to be implemented again in higher levels.

All of this poses a question: why should other languages pay these performance
costs due to the failings of C and other languages lacking memory safety? If,
say Lisp, only gives out access to objects by reference thereby making it
impossible for one process to arbitrarily grab data of another process, why
should it pay the cost for memory corruption runtime mitigations underneath?

The technical reason is that Lisp Machines and Java bytecode-executing CPUs
never took off, so today's safe language implementations run atop general
purpose OSes. The final code that _actually runs_ such as the Lisp interpreter
or a Java virtual machine written in C++, is native code for the underlying
machine. This native code, as far as the CPU and OS are aware, can potentially
have memory corruption bugs and myriad other problems, so they assume the worst
and apply all of their runtime protections. They cannot just take the
process' word that it is derived from a memory-safe source.  This also applies
to other memory safe languages that use implementations atop general-purpose
OSes, such as the CPython, and .NET.

Putting Rust aside for a moment, most memory-safe languages incur runtime costs
to ensure memory safety, such as forcing all objects through forced automatic
memory management i.e. garbage collection. They then must pay another cost
again, in the memory protection layer of the OS, to verify something _they have
already checked_.

Is it possible for a system to only run safe languages and remove the runtime
checks that are otherwise necessary? Even if it is possible, it the resulting
system desirable?

## Mandating Safe Languages to Eliminate Some OS and CPU Runtime Checks

We can assume that language-specific hardware will not take the computing world
by storm in the foreseeable future. Even very successful language runtimes such
as the Java Virtual Machine gave up trying to work on custom-built
hardware. The Java community's dream of CPUs with microcode that executed JVM
bytecode directly en masse didn't materialise.

How can general purpose OSes know that executables were written in memory-safe
source languages and safely take their word for it? A declaration that, pinky
promise, they won't accidentally (or otherwise) corrupt memory?

Allowing executables to self-declare their safety is clearly a security
nightmare; far too many C developers think they're the "special few" who can
write secure code, and it would allow adversaries to just put such declarations
in nefarious executables. Let's cross this approach off right away.

The approach of whitelisting "allowed" executables is clearly insecure too and
won't scale. How does the OS know whether an executable is "allowed"? Is being
cryptographically signed by a known developer, iOS app-style, enough to take
such declarations seriously? Of course not. If the OS only receives the native
code and nothing else, it is right to assume the worst and apply all runtime
memory protections.

What if an OS had a built-in set of compilers of known memory safe languages,
and compiled them on the fly, mandating the source language as the only form of
distributable executable the OS would "run"? This is essentially what AOT
compilation in .NET is doing: taking a memory-safe intermediate language and
compiling to machine-code ahead of time (putting aside .NET's support for opt-in
unsafe code).

The JIT or AOT compilation step is necessary because modern hardware is general
purpose and won't execute popular language bytecode formats natively. Blocking
_direct_ execution of compiled code is also necessary since the OS must run
sources itself through known-memory-safe language compilers or interpreters to
ensure memory corruption cannot occur in the resulting executables.

---

The problem more broadly is that the fewer constraints applied to
outside-controlled inputs such as executable code by third-party developers,
the fewer assumptions that can be made by the environment into which it is
loaded. When basic assumptions like memory safety cannot be made the
environment must compensate with runtime checks or risk compromise.

This is why designers of environments like language VMs or OSes must be careful
about relaxing constraints on the "apps" or "languages" running on top. Some
platform's like Apple's iOS have done respectable jobs of this.

## An Alternative

How would a system that solves this work? The compilers and interpreters would
need to be fixed and trusted; allowing arbitrary ones would allow compiling or
interpreting languages lacking memory safety, circumventing the protection.
There would also need to be environment primitives that can be written without
such guarentees, to allow bootstrapping the environment and providing the
low-level building blocks.

The user would download an "app", a bundle of language source files, and execute
it. The OS would then detect that it is a new "app" and compile it to machine
code, probably caching the results somewhere. That cache has to be internal to
the environment and not accessible by the user, as it is caching raw executables
which, if modified and then reexecuted, can bypass memory safety.

These compilers probably wouldn't be for high-level languages like Rust, but
could be. It seems more likely that languages would target memory-safe
intermediate languages formats like WebAssembly or JVM bytecode, for which a
compiler or interpreter would exist in the OS.

It could be argued that this approach violates the security-in-layers approach
of security engineering. If a bug were found in Rust's borrow checker that
allowed bypassing safe mode, it would be game over. (Let's assume a Rust
compiler in this environment would only load apps whose Rust sources banned
unsafe code and whitelisted standard libraries that had `unsafe`
implementations.) Perhaps the aforementioned runtime checks are still necessary
for that reason: the memory safety of the environment becomes the weakest link
of all memory-safe language compilers supported by the environment. Most
environments would probably keep their amount of compilers small and
auditable. Many might even opt for just one immediate language and support
no others.

---

We just basically described a web browser executing WebAssembly, but with the
hypothetical modification in that the browser is now implemented on the "bare
metal" and bypassing existing OS and CPU protections directly. Gary Bernhardt
made a "haha, only serious" contribution to this topic regarding JavaScript in
his excellent "The Birth and Death of JavaScript" talk [many years
ago](https://www.destroyallsoftware.com/talks/the-birth-and-death-of-javascript).

The inevitable performance vs security-in-layers tradeoff this conversation
brings up will be discussed more in my [next
article](https://volatilethunk.com/posts/2019/02/10/to-secure-systems-of-the-future-we-must-rethink-our-notions-of-environment-and-operating-system/post.html).
