title: WebAssembly: a Security Engineer's Review
date: 2018-11-18 12:00
tags: security, plt, web
---
WebAssembly is an assembly dialect for an abstract computer, a bytecode format
that runs on any device implementing a compatible runtime according to [the
WebAssembly specifications](https://webassembly.github.io/spec/core/index.html).
It seems suspiciously similar to the write-once, run-anywhere promises of Sun
Microsystem's marketing videos about Java in the late '90s and early 2000s.

Does it sandbox better than [Java's virtual
machine](https://docs.oracle.com/javase/specs/jvms/se7/html/index.html)? Does
introducing an assembly-like language to the web open security holes not
possible within JavaScript runtimes? Does it create new opportunities for
obfuscation, making it harder to audit what runs within our web browsers?

---

It's encouraging to find that WebAssembly was clearly written with a strong PLT
(programming language theory) focus, so the sort of holes that occur due to a
lack of formalism will hopefully be thin on the ground. The specifications use
pseudo-formalistic notation, strictly define the interoperation between the
WebAssembly semantics and its host via an "embedder", and don't just shrug at
every edge case and say "we don't know, the implementor can implement whatever
performant behaviour they like here".

On this solid foundation rests a set of design decisions that shoot down some
typical native code exploit vectors. The instruction and data stacks are
separate, one not being able to corrupt the other. Both can only be controlled
indirectly and must pass static verification before the runtime will execute it.
Writing beyond the end of a buffer to overwrite the return address to change the
execution path does not work, and nor will a large range of similar attacks
based on control flow being manipulated by unanticipated data manipulation.

WebAssembly, [like many macro
assemblers](https://docs.microsoft.com/en-gb/cpp/assembler/masm/directives-reference?view=vs-2017),
understands functions natively. Unlike macro assemblers, it understands them
semantically beyond just `CALL`, `RET` and some syntactical sugar for handling
stack frames and saving registers.  WebAssembly only gives access to the
declared parameters it was expecting to be pushed and will statically validate
that the amount of elements left on the stack when leaving the function matches
how many results it claims to return (which currently can be only zero or one).

There is no direct register manipulation, and the abstract machine is solely
stack-based, whose stack operations are implicit as opposed to providing
explicit operations like `push` or `pop`. The data stack's implicit
manipulations are presumably translated into register stores and loads by JIT
compilers. This makes sense, as efficient register allocation has been a solved
problem in computer science for quite some time.

```
(func $add-two-numbers (param $x i32) (param $y i32) (result i32)
  load_local $x
  load_local $y
  i32.add)
```

---

While those decisions make sense for creating a safe, portable, optimisable VM,
the result is something that doesn't really feel like an assembly dialect. It
feels more comparible to the Java Virtual Machine. That said, the key difference
between WebAssembly and higher-level VMs like the JVM or .NET is that it doesn't
understand any data operation more sophisticated than moving around CPU
register-sized values. It doesn't have a view on how to group data together like
a C `struct`, as it delegates that decision to the source language.

It can create what it terms a `memory` or get one from the embedder and refer to
elements in it by index. This is how languages with direct memory management
like C work under WebAssembly; their entire memory space is represented by a
large `memory` slab allocated at the start. This means attacks that involve
manipulating offsets into heap-allocated memory to gain unauthorised access to
unrelated data are _not_ prevented. Attacks like Heartbleed that exploited
unvalidated input bounds into a custom ring buffer allocater would not be
prevented by WebAssembly.

---

Source languages will be the primary way of using WebAssembly. Like JVM
bytecode, it isn't designed to be written in directly. Unlike JVM bytecode, it
must support a far wider range of memory models than just Java's. That's why it
has no concept of default memory allocators, memory models, [how dynamic
dispatch is implemented](https://en.cppreference.com/w/cpp/language/virtual),
and especially not garbage collection. This is why WebAssembly just gives
programs a big slab of indexable memory and then calls it a day. One exception
is function pointers, which it will not allow in `memory`s. Instead, function
pointers can only be stored as opaque references in something WebAssembly calls
a `table`. This was a smart move to avoid function-pointer overwriting to open
the door again to malign data manipulation changing control flow.

Its frugal memory model is necessary for WebAssembly to be a target for native
languages like C, C++, and Rust. These languages might not agree how to do
`struct` alignment, dynamic dispatch, or how to allocate memory. If WebAssembly
had an optional garbage collector, which variant would it implement? If it chose
a mark and sweep collector, how could [a language expecting deterministic
destruction](https://perldoc.perl.org/perlobj.html#Destructors) use it?

WebAssembly has a secure foundation for core execution semantics, but for target
portability cannot hold opinions on higher-level features.  This means each
language will need to compile these features into the executable.
Vulnerabilities or oversights in the language features' implementations will
then be present in the WebAssembly targets too. This isn't a regression over
other targets of the language, but it does increase the attack surface in the
browser by adding additional complexity specific to the source language. By
stepping down from JavaScript to WebAssembly, we move from the browser's
ubiquitous high-level language to its ubiquitous low-level language.

This means features are being reimplemented in WebAssembly executables
that used to be consistent across all webapps. For example, we used to only need
to understand JavaScript's prototypal object system. Now someone analysing a
webapp for vulnerabilities must know the edge cases of the object system of all
source languages used for the app. Vulnerability-prone language conventions and
common APIs that [used to exist outside of the web
ecosystem](https://arp242.net/weblog/yaml_probably_not_so_great_after_all.html)
can now exist inside, if the entire stack is ported over to WebAssembly.

---

WebAssembly's lower-level semantics could make it a more lucrative target for
stealing CPU time on users' devices, e.g. cryptocurrency mining. This isn't a
strong point however, as JavaScript can already be written in a
highly-performant manner as to make this already viable, using dialects like
[asm.js](http://asmjs.org).

There is a one-to-one mapping between WebAssembly executables and the
[WebAssembly text format](https://webassembly.org/docs/text-format/), which
browsers' developer tools can convert between on demand. While this bridges some
of the gap between comprehending WebAssembly and minified JavaScript,
WebAssembly will be harder to reverse engineer and generally understand simply
because it's using a lower-level set of building blocks for programs. Source
languages like [Go](https://github.com/golang/go/wiki/WebAssembly) also bundle
large runtimes with WebAssembly executables, making them even harder to
decipher.

Programs in the web browser being immediately readable was a battle lost long
ago, starting when JavaScript minifiers and bundlers became popular.  The era of
seeing readable JavaScript source code by just clicking "View Source" has sadly
long since passed. WebAssembly is yet another step in obfuscating web-delivered
code further.

---

WebAssembly's text format is curious. It isn't just a direct mapping of
WebAssembly opcodes to English words; it contains abbreviations, shorthands, and
syntactical sugar. Despite being ostensibly a target language, some effort has
been made into making it pleasant to write. This means viewing the text format
of an executable can yield different results depending on how much syntactical
sugar and conveniences one opts into. For example, the WebAssembly example above
can also be written like this, making it almost resemble Lisp:

```
(func $add-two-numbers (param $x i32) (param $y i32) (result i32)
  (i32.add (load_local $x)
           (load_local $y)))
```

This theoretically makes it more pleasant to drop down into WebAssembly from a
source language to optimise something tightly. It isn't clear if, for example,
[C++'s `asm` keyword](https://en.cppreference.com/w/cpp/language/asm) will
eventually support inline WebAssembly when using it as a target on some
compilers.

---

A WebAssembly program's dealings with the outside world are determined by its
[embedder](https://webassembly.github.io/spec/core/appendix/embedding.html) and
host, so the security model will match that. Although WebAssembly was originally
designed to be embedded in web browsers, it can be [embedded in other
contexts](https://github.com/go-interpreter/wagon) too. Browsers remain its
defacto environment though, so the browser's security model is the one most
WebAssembly programs will be written against.

This already puts it on stronger footing than native programs or even the JVM,
the latter of which had its security sandboxing abandoned by developers. Running
Java programs within a locked-down sandbox has become a niche use case rather
than the norm, meaning they should be treated the same as native applications
for the most part.

---

All in all, WebAssembly is a solid attempt at creating a portable, secure VM for
executing code from a wide range of memory models, object layouts, and
paradigms. By not siding with a particular model of computation like the JVM
does, WebAssembly becomes not just a viable target for memory-safe, class-based,
object-oriented languages, but also for C, Haskell, Factor, and everything in
between. While having a well defined model for managing memory and grouping data
together would have frustrated attacks like those that manipulate indices into
the heap, it would also have significantly reduced the range of source languages
that could use it.

A universal, CPU-portable abstract machine like this is what the JVM couldn't
be, what minified JavaScript was pushed towards but shouldn't be, and what the C
abstract machine unsuitably became. There is not a "C abstract machine" beyond
the C language's specifications of how its executables should run, but combining
that with some informal agreements like ABIs for non-mangled symbols on
various platforms allowed it to become the lingua franca of direct, non-RPC
cross-language communication. It's how a natively-written function in CPython
can invoke a function exported from Node.js's V8, for example.

This is a poor state of affairs given that this abstract machine has no concept
of even protecting return addresses in stackframes from nefarious manipulation.
WebAssembly could become a more secure replacement for this in some higher-level
domains, albeit with [quite a bit more
work](https://hacks.mozilla.org/2018/10/webassemblys-post-mvp-future/).

However, users have been trained over the years not to install random
applications, yet will happily browse to the sketchiest of websites. And why
shouldn't they? The browser was supposed to be a secure environment for viewing
untrusted remote documents after all. As browser manufacturers pile more
capabilities into browsers, including WebAssembly, the reasonable expectation
of a simple, water-tight sandbox will become increasingly violated.

Once browsers become so complex that they become infeasible to secure, what
secure, sandboxed, remote document-viewing standard will come along to replace
it? I sincerely hope Google's walled garden of AMP is not the answer the web
community comes to.

