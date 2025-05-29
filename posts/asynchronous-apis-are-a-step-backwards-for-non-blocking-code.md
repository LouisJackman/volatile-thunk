title: Asynchronous APIs are a Step Backwards for Non-Blocking Code
date: 2018-03-22 12:00
tags: concurrency, plt
---
`async` and `await` are must-have features of modern programming languages, yet
they represent the industry's doubling-down on a clumsy, error-prone, and
hard-to-debug mechanism for managing non-blocking IO. Rather than managing
non-blocking IO in their runtimes transparently, they instead chose to force
them into the forefront of the developer's mind like manual memory management.

Asynchronous APIs are often sold as a positive feature of newer frameworks and
libraries yet usually means littering code with `async/await` or promises,
waving goodbye to comprehensible stacktraces, and dividing the technology stack
into two incompatible parts: the old blocking libraries and the new non-blocking
ones.

***

Pausing execution while waiting for something to return a value is seen as
_blocking_ but is actually being _synchronous_. While non-blocking asynchronous
code is encouraged and the industry increasingly discourages blocking
synchronous code, many developers forget about the _synchronous non-blocking_
approach. This might be because so few language runtimes support it, such as
Erlang, Go, and Haskell's GHC. The three big runtimes don’t support it: web
browsers, the JVM, and .NET. They get more entrenched in the asynchronous
non-blocking approach over time.

Asynchronous APIs have many problems, such as:

* Discarding useful context like stacktraces because the program slices up its
  own linear execution flow to allow interleaving operations on the event loop.
* Making an unnecessary yet sharp distinction between blocking from external
  events like IO, and blocking from expensive computations. When built-in
  concurrency primitives heavily sold by a language only deal with one of them,
  it's likely developers won't think of
  [the other](https://www.owasp.org/index.php/Regular_expression_Denial_of_Service_-_ReDoS).
* Moving the decision of running a function in the background from its caller to
  its author, even though the author cannot possibly know all of the different
  contexts in which it'll be called.
* Using an asynchronous API cascades up the call stack, often to the topmost
  levels.  That causes backwards-incompatible changes to the returned values of
  every layer. That’s why, in the Java world, Spring made WebFlux separately
  from Spring MVC rather than just an update of Spring MVC.
* Inventing two different side-by-side languages for synchronous and
  asynchronous worlds. Consider Python 3: `for` vs `async for`, `def` vs `async
  def`, and `with` vs `async with`.  JavaScript has a similar problem.
*  Additional verbosity. Callback hell in Node.js codebases is a good example,
   but even promises don't solve this: `resp = http.get()` vs
   `http.get().then(resp => {`. Even with `async`/`await` those are keywords we
   didn't need to type out before.

Asynchronous APIs hamper abstraction yet developers are enamoured with them.
Here are some of the points that come up.

> Asynchronous APIs force code to be architectually non-blocking and performant
> from the ground up.

Asynchronosity forces asynchronous APIs but it doesn't encourage performant
design. The transformation from synchronous to asynchronous is an entirely
mechanistic transformation. If it wasn't, `async`/`await` wouldn't work.

Asynchronous APIs mandate a greater cognitive overhead for developers due to
the aforementioned reasons. The time they spend making code asynchronous is
time they could otherwise spend on architectural performance concerns.

> Asynchronous code helps avoid the nightmare of threads, such as non-atomic
> operations, critical regions, and race conditions.

This is the problem of shared resources across concurrent tasks, which is
orthogonal to asynchronosity and parallelism. Asynchronous tasks can race
promises that manipulate shared state, which opens itself up to race
conditions. Of course, this can also happen with synchronous APIs too.

Threads open up developers to the painful world of CPU caching and memory
fences, it's true. However, this still requires sharing of mutable resources,
which has its own share of problems in non-threaded code. Developers are
thankfully moving away from shared memory and towards messaging and queuing.
Synchronous non-blocking tasks exist that don't expose low-level threading
details, such as Erlang’s processes or Haskell’s green threads.

Systems that have neither threads nor a lightweight threading solution like
Erlang's restrict themselves from a lot of fine-grained parallelism tricks,
which exclude them from certain domains. For example, Node.js's `cluster` module
is restricted to coarse parallelism. Most languages with asynchronous APIs, such
as Java, C#, and Python expose threads anyway, and usually force threading
concerns onto reasonably complex codebases.

To summarise, synchronous APIs don't mean direct thread manipulation, and most
asynchronous tech stacks foist threading concerns onto developers anyway.

> The alternative is OS threads, which perform badly.

Erlang processes, goroutines, and Haskell's green threads are not OS threads,
but they can utilise threads behind the scenes for parallelism.

Threads are too coarse-grained for concurrency, but are a great OS feature for
implementing low-level parallelism. Apache and early Java attempts at
concurrency made the mistake of using them for concurrency and paid the price
by getting a reputation of not scaling, with the
[C10k problem](http://www.kegel.com/c10k.html) many years ago helping to bring
the problem to light.

Threads are an implementation detail of parallelism in modern technology
stacks. To dwell on them when considering asynchronous and synchronous API
design is mistaken.

> Promises are monads. If we had proper do-notation in mainstream languages
> they'd be the cleanest way of managing non-blocking IO.

Even the language most synonymous with monads, Haskell, provides runtime
support for non-blocking synchronous IO without forcing users through async
monads. One of their fast HTTP servers,
[Warp](http://www.aosabook.org/en/posa/warp.html), takes advantage of this.

`async`/`await` are essentially the do-notation specialised to the async
"monad", so they inherit all of their problems despite being a more general
abstraction.

> Asynchronisity is required for our event-driven system.

Interpreting events as many callbacks that can be triggered at any time sounds
inherently asynchronous, but what about seeing it as an infinite stream of
events that a single waiting task dispatches in a loop? Wait, isn't that what
`epoll` and `kqueue` fundamentally do, the foundations of asynchronous systems
like Node.js?

Events are inherently concurrent but they don't necessitate an asynchronous
API. In fact, triggering callbacks ad hoc rules out many powerful tools of
abstraction that are available with the streaming model.

The goal of projects like [ReactiveX](http://reactivex.io/) and Java's
[Reactor](https://projectreactor.io/) is to turn ad hoc events into such
organised streams. Of course, it's a lot easier just to iterate over a stream
with a synchronous API and wait for results as they come in. When non-blocking
is supported directly by a language, this roughly performs in the same way yet
doesn't lead to the horribly mangled stacktraces and duplication of existing
language constructs that occurs in reactive programming libraries.

For example, if Java had lightweight tasks, Reactor would be unnecessary as
developers could use `java.util.Stream` even for results that blocked due to
operations like network calls.

> My application can't afford lightweight processes or goroutines.

If your application can afford garbage collection and dynamic dispatch for
polymorphism, it can probably afford a lightweight task runtime too.

Like garbage collection it's ultimately trading off a bit of performance, in
this case memory, to make programming less error-prone and more robust.

If you're programming in Java or C# you're almost certainly already working on
a problem for which a lightweight task system has perfectly acceptable
performance. This is even more true for JavaScript and Python.

If you're working in C, C++, or Rust, then you possibly _are_ working in a
domain in which a lightweight task runtime is prohibitive.

***

*Like manual memory management, explicitly asynchronous APIs should reside
solely in the realm of systems and high-performance programming.*

We don't hesitate to reach for a garbage collector when developing high-level
applications, so why is the industry so keen on manually managing non-blocking
IO?
