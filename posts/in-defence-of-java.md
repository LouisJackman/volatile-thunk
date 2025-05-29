title: In Defence of Java
date: 2019-12-08 12:00
tags: languages, plt, java
---
Is Java a stagnant, stale programming language, sustained only by its flagship
position on one of the more popular language runtimes? It's increasingly
believed by many software engineers. If only Java would accrue new features as
quickly as C#, they opine, or just step aside entirely and allow Kotlin to
become the new defacto JVM language.

I'm unconvinced, and this article explains why.

## Introduction

Programming languages these days seem to mostly fit into two camps: mainstream
languages accumulating features quickly to follow software development trends,
or niche academic languages that prioritise theoretical purity at the expense of
staying niche. JavaScript and Python constantly add new features via staged
proposals and PEPs respectively, while minimal languages such as Scheme,
Smalltalk, and Tcl remain nestled contently outside of mainstream programming
software engineering conversation.

Java stands outside of both camps, a mainstream, popular language that
nevertheless hasn't succumbed to the churn of endless new features. Let's
discuss the important link this has with programming language _coherency_.

When discussing coherent programming language design, it's important to concede
that many languages with much purer designs, such as Kernel Lisp, Newspeak,
Urbit's Hoon, and Self, haven't yet taken the software development world by
storm.  My comparisons will therefore remain within the arena of well-adopted
languages that were not so divergent from the norm as to hinder mainstream
adoption.

Let's instead focus on the modern popular languages: JavaScript and its typed
cousin TypeScript, C#, Java, Python, Ruby, Kotlin, Swift, and Go.

This defence of Java is really a broader plea for convervativeness in
programming language theory that still respects expressive power.

## The Backlash to Cleverness

The term "Java" conjures bad memories for many developers, likely the
overwrought abstractions of JavaBeans, Spring runtime-based dependency
injection, J2EE "active objects", lengthy XML configurations, deep inheritence
hierarchies, and tastelessly- and blindly-applied Gang of Four design patterns.

When given overarching ideologies, software engineers can often try to fit all
solutions into it. Unlike engineering with concrete, girders, and plastics,
software is transcribed ideas rather than the combining of limited physical
resources. That makes it especially vulnerable to over-abstraction and what Joel
Spolsky termed ["architecture
astronautism"](https://www.joelonsoftware.com/2001/04/21/dont-let-architecture-astronauts-scare-you/).

A major failure of the last two decades of mainstream software engineering is
understanding the benefits of abstraction without fully understanding its costs.
Abstractions can be a force multiplier for developers so long as they don't have
too many leaky abstractions, but every layer is another that must be understood
and debugged if it fails.

DirectX, OpenGL, and Vulkan are examples of abstractions that work well.  They
expose details of the underlying layers though implementation bugs and other
oddities that any videogame engine developer will be able to elaborate on, but
the industry surely wouldn't voluntarily return to the era of writing custom
integration code with every popular range of graphics card. These are examples
of abstractions whose benefits greatly offset the cost of an additional layer to
debug.

Java's Spring Framework is an example of the opposite, an abstraction whose
costs at least rivals, if not eclipses, the benefits it brings. This might be a
controversial statement for its fans, but consider these Faustian bargains it
wagers with developers who use it:

* Annotation- or XML-based dependency injection, trading compile-time safety for
  runtime failures on initialisation. This undermines one of the selling points
  of Java over dynamic languages, that more errors are caught by the compiler
  rather than in runtime potentially on production.
* SpEL, the Spring Expression Language, trading off the benefits of consistently
  using your single choice of language on the JVM, likely Java or Kotlin, for an
  increase in expressive power that was only a tangible gain in the pre-Java 8
  era. Now you must learn _another_ language, specifically a slow one
  interpreted from Java strings. Even if your project doesn't use it directly,
  its presence in Spring means you might encounter it in old projects, in
  Spring-compatible libraries you use and want to dissect, or in Spring
  documentation.
* The ubiquity of listeners and handlers, trading simple control flow and
  predicable behaviour for myriad action-at-a-distance, likely worsening the
  larger the project into which you are parachuted. Most points at which control
  flow yields back to Spring can now potentially trigger a listener or handler
  installed by a previous engineer as quick fix for an inscrutable problem four
  years ago, and that's made even harder to reason about when those handlers are
  for exceptions.
* Aspect-oriented programming based on dynamic proxies or code instrumentation.
  While it reduces the need to explicitly mention cross-cutting concerns at
  every relevant layer, control flow becomes obscured, interceptions weaved in
  and out of the callstack. These can then only be understood by reading
  declarations in DSLs from AspectJ or Spring AOP, using its own terminology
  such as "pointcuts".
* Configuration with multiple levels of default overrides. Overridding
  configuration values in the developer's preferred layer is then easier, but at
  the expense of making it harder to ascertain where a particular configuration
  value is defined or overridden. What was once a default constant used to
  default environment variables or command line arguments is now smeared across
  layers of YAML configuration, default values in SpEL, and environment
  variables extracted using DSL placeholders embedded into configuration
  language strings.

Spring is a cautionary tale that makes the _costs_ of abstraction as clear as
the benefits.

The backlash against such complexity has been the growth of tools that bask in
simplicity, but then prescribe a very opinionated view of said simplicity as the
One True Simplicity that other ecosystems simply haven't yet become enlightened
to.

For example, Go's designers reject algebraic data types in order to keep the
language simple, making a nil-avoiding `Option` type unfeasible, yet allows
`nil`s to be assigned to many types of variable. This is done in the name of
simplicity, yet it complicates code that can no longer assume an interface or
pointer value contain a usable interface value or a pointer to a valid value.

Another tradeoff includes its dragging of its feet on supporting generics but
then rolling out its own synchronised map type, `sync.Map`, requiring runtime
type casting to put values in and pull values out. This contradicts one of the
original design rationales of Go, that static typing ultimately makes reasoning
about codebases simpler despite the initial overhead for the developer.

These decisions aren't wrong per se, just tradeoffs. Go's designers have written
[extensive, thoughtful pieces](https://blog.golang.org/why-generics) on the
tradeoffs of features like generics and their various potential implementations.
The problem is that, despite the nuanced positions of some of its creators, the
broader Go community do not position them as difficult tradeoffs but instead as
a pursuit of a single vision of simplicity that mere "white collar" developers
using other languages do not yet understand.

One of the early presentations about Go in its first wave of publicity mentioned
that most junior Googlers would be better suited to Go precisely because it
isn't a "sophisticated language".

It might have a point. Similar arguments are made against Lisp macros, that
while experienced developers can produce tasteful, expressive abstractions with
them, the majority of developers possess too high a likelihood of screwing it up
and pointing that expressive power straight at their foot and pulling the
trigger.

There is, however, a fatal flaw with this reasoning: crippling expressive power
to remove footguns increases _initial ease of use_ but decreases _simplicity_.
This is something that Rich Hickey, the creator of Clojure, [seems to understand
more than most language designers](https://www.youtube.com/watch?v=34_L7t7fD_U).

## Lacking Expressiveness Trades Simplicity for Ease-of-Use

Decreasing simplicity across the layers of our systems for a small, fixed
increase in programming language ease-of-use is a decision that, given its
impact on systems of the future, must be dissected in greater detail.

Some Java developers, upon seeing usages of the proposed lambdas in the
then-upcoming Java 8, complained that it was less simple than the traditional
way of solving the same problem:

```java
List<Person> people = Arrays.asList(
    new Person("Tom", "Smith", true),
    new Person("Emma", "Clark", false)
);

List<Person> activePre8 = new ArrayList<>();
for (Person person : people) {
    if (person.isActive()) {
        active.add(person);
    }
}

List<Person> activePost7 = people
        .stream()
        .filter(Person::isActive)
        .collect(Collectors.toList());
```

For loops were better understood in the Java ecosystem as was the pattern of
adding to a collection in a loop rather than "collecting" into one from a
stream. By this interpretation it was simpler. The new way used opaque methods
that were not well understood and new concepts like "streams" and "collectors".

In truth, these complaints were not about simplicity but instead the
ease-of-use for those used to established Java conventions. The complaint about
the streaming hiding the loop iteration could also be used against Java 5's
enhanced for loops, that it unnecessarily hides the incrementing index.  In
fact, why have loops at all? They just obscure the comparisons and conditional
jumps in the JVM bytecode.

If instead, simplicity is interpreted as the amount a developer must track in
their mind to complete an operation, these abstractions atop comparisons and
conditional jumps simplify rather than complicate the filtering into a list; a
stream doesn't even require the developer to spell out iteration constructs. The
developer only cares that the list is _somehow_ filtered, the implementation be
damned.

Simplicity cannot be defined easily. Is it simpler to have fewer concepts for
the developer to track, fewer operations for the physical hardware to perform,
or the fewest new things to learn for those already familiar with the status
quo?

I'd argue that simplicity in software is represented by having the fewest
moving parts for a developer to track, being orthogonal, being a foundation for
new features without creating inherent leakages of abstraction,
and not encouraging intractible amounts of computation for hardware
to solve beyond what's expected for the problem.

How well does the Java 5 enhanced for loop honour this? New types can be
integrated with it by implementing the `Iterable` interface, but it doesn't
scale up beyond abstracting linear, synchronous iteration. It doesn't lead to
intractible amounts of computation, instead compiling to roughly what we'd
expect if the iterating loop were written out manually. It only applies to
iteration and not anything outside of it.

What about concise lambdas? Any so-called SAM type can use them, that is, types
with a _Single Abstract Method_. That makes them amenable to implementing new
features, as it works with a fundamental notion of the language. It scales up
well beyond a particular use case; while it can supersede the enhanced for loop
with the `Collection::forEach` method, it can also implement any other API that
befits lambdas including synchronous iteration, asynchronous iteration, monadic
composition, event handlers, countless functional patterns, Smalltalk-style
"block consuming" APIs, and more. It leads to somewhat intractible amounts of
computation, depending on whether Java decides to compile it as a vanilla
anonymous inner class method call or a `invokedynamic` invocation, but still has
constant-time performance characteristics.

According to that definition of simplicity, lambdas are a _simpler_ feature than
enhanced for loops, especially as they supersede enhanced for loops with
`forEach` calls.

Adding a generalised collection-iterating loop, like early Java and Go from its
initial release, improves ease of use as there's an immediately accessible
language construct that makes a particular operation easier. Adding a
generalised construct for abstraction, like modern Java's lambdas, improves
simplicity as there is a more expressive building block for new abstractions.

Many languages like Go and Python have focussed on ease-of-use features, small
additions that make specific patterns easier. Modern Java from, say, version 5
has instead focussed more on simplicity of abstraction. While Go considers new
special-case shortcuts for handling return values specifically of the `error`
type and Python adds `async`/`await` to smooth out the usage and definition of
asynchronous APIs, Java has instead focussed on fundamental building blocks of
abstraction: lightweight threads to reduce the need for asynchronous APIs, value
types like Go to encourage reasoning about small bags of data without identity,
and a module system that allows bounding reflection which is otherwise an
obstacle to performance and static reasoning of code.

This is why I think Java's design is more coherent than many other mainstream
languages today: that focus on simplicity of abstraction and orthogonality over
direct ease of use.

## Why Orthogonality is Important

Orthogonality allows language features to be considered independently of other
features. Using one orthogonal feature does not necessitate dragging in others
that don't directly solve the user's problem.

Non-orthogonal features compose poorly with other features. The additional
feature to which they are tied could interfere with their being part of a larger
composition.

Class-based object oriented programming provides several features such as
polymorphism, encapsulation, and code reuse. Sadly, they are unorthogonal. Using
just one of those features requires dragging in all of the others even if they
are a poor match for the problem.

Classes provide dynamic dispatch, a useful mechanism for working out which
behaviour to use at runtime depending on the runtime-detected subtype of an
object instance. This mechanism comes in two flavours: single-dispatch and
multiple-dispatch. Without multiple-dispatch, workarounds like the visitor
pattern become necessary. In fact, many of the techniques in the "Gang of Four"
are just working around such missing language features.

Classes tie polymorphism to implicit "this" parameters on methods, meaning
single-dispatch becomes inevitable. The limitations of the class-based view of
methods ends up weakening a feature that _should_ be standalone: polymorphism
via dynamic dispatch.

Common Lisp and Clojure instead provide polymorphism as a standalone feature.
Not only can a program dynamically dispatch on a single `this` object, but it
can dispatch on any number of parameters. Clojure goes a step further than
Common Lisp, allowing parameters to trivially dispatch even on non-type
conditionals. At this point it is a dynamic condition system that allows
greater modularity, easier extending, and less nesting than just `if`s and
`switch`es.

It's clear, then, that a lack of orthogonality can cast a fog over a developer's
thought process, leading to their shaping of solutions around frameworks of
thought like OOP rather than using small, simple abstractions to directly solve
a problem.

A lack of orthogonality also hinders backwards-compatible language updates.
Updating a language feature, whether it's tweaking the syntax or overhauling the
semantics, is more likely to break when it is entangled with several other
unrelated features.

Java is class-based, so its original '90s inception is guilty of the
aforementioned problem of tying polymorphism, encapsulation, and code reuse
together into a single mechanism. Its newer features are quite orthogonal
though, and it deserves credit for creating new features with greater
orthogonality than many of its contemporaries.

Many languages could map and filter sequences long before Java, such as
JavaScript and Ruby, but their versions were not orthogonal: they were tied to
non-concurrent execution, eager evaluation and dumping each stage of results
wholly in memory, and only made sense on finite, linear sequences.

By contrast, Java took streaming as a concept and detached it from the
underlying data structure being streamed. This is not a remotely new concept;
functional languages have done this for decades prior, and even mainstream
languages like Perl adopted this strategy in their ecosystems from books like
Higher Order Perl.

Having detached streaming from the underlying data structure type, they also
took the idea of collecting a stream into a concrete result when finished,
unmooring it from any real concrete representation until being realised. This
meant it could also deal with infinite streams so long as the final collection
produced something finite, Haskell-style.

Finally, Java did something quite rare in mainstream languages. It based the
generation of streaming results on what it called "spliterators", meaning that a
streaming implementation was allowed to divide-and-conquer the streaming across
multiple threads transparently and with ease.

C# and Haskell have comparable features, but it is a step up over other
languages like Python, Ruby, Perl, and JavaScript.

## How Programming Language Ecosystems become Echo Chambers

Why, if orthogonality is so important, does it come up so little in
conversations with developers about additions they want to see in future
versions of their language of choice?

The simple answer can be summarised by a well known line attributed to Henry
Ford (with little evidence): "If I had asked people what they wanted, they would
have said faster horses". To be less trite, developers perhaps know the benefit
of new features without fully understanding the costs of adding them. These
costs aren't just paid for the language implementers, but also by developers
themselves down the line.

This is why Anders Heljsberg pointed out that all new C# feature proposals
start with minus points upon being proposed.

Any new feature is something all developers using the language must know once it
is implemented. Even if they personally don't use it, they will inevitably need
to comprehend code that does. If that feature lacks orthogonality, it can also
disrupt the developer's understanding of an existing feature they already
understood. If a feature is rushed, it might need to be reimplemented again in
the future, either replacing the old version and breaking compatibility or
living along side the old version. This is likely how C# ended up with three
overlapping ways of passing code around by value: delegates, anonymous
delegates, and lambdas.

New features will usually be a tradeoff between academic concerns and just
"getting it done" so developers can start using it sooner. Pressure on
programming language designers is arguably trading off too much of the former
for the latter.

Language design for a mainstream language must respect the academic theory work
but also be tempered by real world experience. Prescribing feature from academic
ivory towers without real world studies creates flaws, as does designing by
committee or adding features haphazardly based on how many developers "thumbed
up" an issue on a language's issue tracker.

Giving up this balance to appease a vocal minority of developers risks creating
an echo chamber ecosystem while the silent majority of its developers become
increasingly confused at its endless new features. Java has thankfully managed
to avoid this.

## Hosted Languages and Standalone Languages

Features can be refined, polished, and added in an orthogonal, tasteful manner,
yet still not work due to a lack of runtime support. Not all language features
can be compiled away; compiling Go or Erlang to JVM bytecode would be difficult
due to their support for lightweight, preemptive multitasking. (Go's is
theoretically cooperative, but it's close enough for most domains.)

Adding a new looping construct to a JVM language is simple because all loops
compile down to conditional jumps regardless. Adding a new concurrency
model, undelimited continuations, or stronger encapsulation guarantees requires
changes to the underlying Java Virtual Machine. No amount of compilation
trickery can work around this.

This is why Kotlin's coroutines are oversold and not as revolutionary as some
believe: they are little more than compile-time magic that still exposes all of
the problems of asynchronous APIs, such as cascading changes from single line
alterations, in Kotlin's case needing to sprinkle `suspend` all the way down the
callstack's methods because just one method wanted to migrate from blocking to
non-blocking.

When Java eventually added lambdas built atop the aforementioned SAM types,
Scala's ecosystem was temporarily broken because it had its own definition of
lambdas atop the JVM. When a language chooses to use another language's runtime,
it saves the effort creating a runtime but at the cost of needing to align a
language to a runtime geared towards running another different, potentially
diverging, language. Clojure still can't offer tail call elimination or a Common
Lisp-style condition system for the same reason.

Some targets, such as LLVM or WebAssembly, are low-level enough and make so few
assumptions about their source languages that almost any language could feasibly
be compiled to them. This comes at the cost of the language needing to define
its own runtime, its own garbage collector, its own lightweight task runtime,
and more.

If a language wants to leverage an existing runtime's optimisations and
implementation, targeting another language's runtime and accepting the
mismatch might be an acceptable cost.

If a language instead wants to reduce the amount of mismatches and use a runtime
that's truly moulded to the language, it must define its own. Java did this, and
can therefore make decisions that keep Java and the JVM working in unison. Other
JVM languages do not have this benefit. This is why the rollout of Java 8
lambdas went more smoothly for Java than other JVM languages. This tradeoff is
likely to repeat itself once Project Loom releases lightweight threads for the
JVM and Kotlin ends up splitting its own ecosystem between coroutine-based
non-blocking and Loom-based non-blocking.

The choices here seem to be:

* Define your own runtime like Java did with the JVM.
* Target low-level "platforms" such as LLVM or WebAssembly that don't prescribe
  too many expectations to your source language, and bundle your own runtime
  with the resulting executable.
* Host your language in other runtimes, such as Clojure on the JVM and
  JavaScript runtimes, in exchange for removing language features that can't be
  compiled away on all runtimes that don't support it natively.

The first and the second have some overlap, as bundling a runtime with a
resulting executable isn't that far from running your code on a preinstalled
runtime. Technologies like GraalVM and C#'s Native AOT compiler blur the lines.

The third approach is problematic but is understandable for some languages given
its benefits. But Java won't suffer such problems simply because it owns
its own runtime.

## Surface Syntax and Programming Language Sales Pitches

Does the average developer care about these ruminations when looking at an
exciting new language trending on sites like Hacker News? No. They care about
how easy it makes throwing together a HTTP request or a command line utility.

This point seems to have been grasped by the Python community more than many
others. While other languages extol the virtues of their type systems or
"purity" of their programming models, Python just gives some definitions of
well-known functions like factorial on the main page and then provides
documentation about how to complete common tasks, such as making HTTP requests
or putting together a GUI.

Python's flimsy concurrency and parallelism model makes it likely they'll need
to migrate to another language in the future if they use it as a base for their
startup, but that isn't clear to them until much later. It hardly matters
though; by the time a startup is large enough and has enough resources to
justify a rewrite into another language, it's likely already succeeded.

Those theoretical concerns do become important for larger companies as they need
to scale though; Twitter started doing new work on the JVM rather than Ruby for
good reasons.

Java has improved surface-level details for  solving easy yet common problems.
Java 9 introduced a REPL, and other new features like type inference and lambdas
have made the surface syntax look more notationally elegant for solving quick
problems. Reading a file, filtering lines, and formatting the result used to
involve a mess of various IO and buffering classes. Now it's just streaming over
the results of `Files#lines` and collecting the result.

It turns out that building a more elegant surface syntax atop a solid foundation
is easier than solidifying an crumbly foundation underneath an elegant surface
syntax.  Adding syntactical sugar is mostly additive if done right, but
reworking foundations will break existing code and will eventually make a
language unrecognisable. Python, especially CPython, has painted itself into a
corner from which it cannot escape. Java, by contrast, has spent time building a
castle atop concrete rather than sand and can now start adding nicities.

(To specifically understand CPython's problems, research into how it does
parallelism, how ubiquitous mutability of even fundamental program structure
kills performance, and how it guarantees compatibility of tricks that thwart
optimisations, such as allowing local variables in parent stackframes to be
modified by callees through dynamic stack-walking.)

## Slow, Coherent Growth versus "Agile" Accumulation of Features

As software development adopts churn from fad-driven cycles, it loses sight of
foundational CS ideas that allows certain technologies to stand the test of time
while others need to be rewritten after just a few years of inception. Unix, the
web, and the JVM have survived decades and will likely survive more albeit
with some tweaks. Most technologies come and fade away just enough to make
an apperance on various technology enthusiast news aggregators but not
enough to make a dent in the grand scheme of things.

Accruing features at a rapid pace can mask shaky foundations. The illusion of
progress obscures poorly thought-out foundation ideas of a technology.

JavaScript countered criticisms from mainstream developers by throwing
prototypal object-oriented programming under a bus in favour of class-based.
While the latter is merely syntactical sugar for the former in ES6, the broader
effect is normalising the class-based paradigm for new development. This is an
example of having solid foundations but then choosing to ignore them to get more
of those aforementioned "thumbs up from mainstream developers on language GitHub
issues".  JavaScript now accrues more static features in its class features that
directly contradict the dynamic nature of prototypes, such as `super` being
statically resolved from a class's `extends` clause rather than the prototype
chain. The increased incoherence this brings will add more landmines even though
so much of the JavaScript ecosystem is already moving away from classes.
Functional components and hooks in React instead opt for other aspects of the
language.

Java is class-based and never diverged from that. Furthermore, it built lambdas
in a way that integrated smoothly with class-based OOP. By not diverging from
the language's foundations but instead embracing them, the language will
maintain coherency for longer.

Java's focus on implementing features slowly, coherently, and by a small team of
experts rather than by committee is resulting in a better language. By contrast,
JavaScript seems to have become much harder to reason about these days than the
subset of ES5 that Douglas Crockford termed the "Good Parts".

## Why Java Will, and Should, Continue to Thrive for Years to Come

Sandboxing didn't really work, ubiquitous reflection and the ability to
dynamically revert accessibility and finality modifiers on fields was a mistake,
and the lack of value types was a thorn in the runtime's side. Put those aside,
and the JVM is a technology that has really stood the test of time. The
stack-based VM with portable bytecode worked well, and the solidification of the
memory model in the face of concurrency in Java 5 gave it a permanent advantage
over runtimes that pretended fine-grained task-based parallelism didn't exist,
like MRI Ruby, CPython, and Node.js.

Its type system weathered criticism for verbosity in the Noughties and came out
of the other end as _developers' preferred approach_, albeit with more type
inference now in the mix. The ecosystems of JavaScript, Python, and even Ruby
have begrudgingly admitted that full dynamic typing has maintainability problems
in larger codebases. They don't state this explicitly of course, but their
actions speak louder than words: TypeScript is becoming almost a defacto source
language for JavaScript and companies are rapidly adopting the Python `typing`
module for new projects.

Java will continue to succeed because it coupled conservativeness of programming
language theory with a respect for expressive power. It doesn't accrue features
just to appease, yet fits new feature smoothly into the existing foundations
when it does. It doesn't add excessively-overlapping features, yet respects the
developer enough to give them powerful new abstractions once in a while.

Let's stop chasing shininess in computing and let's instead focus on refining
the existing, long-serving tools with solid foundations. Build on the shoulders
of giants.

