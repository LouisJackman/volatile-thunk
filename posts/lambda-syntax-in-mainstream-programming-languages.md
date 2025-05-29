title: Lambda Syntax in Mainstream Programming Languages
date: 2019-01-11 12:00
tags: plt, parsing, lambdas, lambda
---
Two features are ubiquitous in modern programming languages: C-style syntax and
lambda expressions. Here’s how they’ve evolved together over the decades and the
syntactical problems it has caused.

Even the most conservative of modern C-like languages, Java, got lambdas
eventually:

```java
var activated = accounts
        .stream()
        .filter(Account::isActivated)
        .map(account -> account.getName().trim())
        .collect(Collectors.toList());
```

---

Lambdas, like a lot of features of Lisp, were invented in a bygone era of
computing and ignored by mainstream programming languages for decades
before being adopted en mass in the turn of the 21st century. Garbage
collection had a similar journey and other Lisp features like support for
[multiphase code
evaluation](https://www.gnu.org/software/emacs/manual/html_node/elisp/Eval-During-Compile.html)
and [abstract syntax trees macros](http://www.paulgraham.com/onlisp.html) are on
a similar trajectory now.

While developers have slowly adopted to the semantic shifts offered by these
features, they remain stubborn about surface-level syntactical changes to
languages. Languages like Java and C# managed to sell automatic memory
management, lambdas, and other then-esoteric tools by packaging them up into a
C- and C++-like syntax.

> We were not out to win over the Lisp programmers; we were after the C++
> programmers. We managed to drag a lot of them about halfway to Lisp.
>
> -- Guy Steele, writing about the design of Java.

This is unfortunate as one of the powerful Lisp ideas that still hasn’t
entered the mainstream is the semantic power inherent in an aggressively
simplified syntax, one that makes [metaprogramming, especially
homoiconocity](https://letoverlambda.com), idiomatic and natural.

---

A consequence of the C-style syntax is parsing ambiguities stemming from the
use of many symbolic operators, precedence rules, and contextual switches in
parsing based on reserved keywords. It’s broadly their trading off of
consistency and orthogonality for syntactical sugar and shorthands.

Lambdas are a construct for which this is especially true.

Lambdas across mainstream languages often didn’t exist throughout the early
2000s and differed substantially from one another when they did. They often
had confusing semantics such an scope capturing not quite working as expected or
only working in overly-specialised contexts.

Python’s lambdas are crippled by being restricted to one expression. PHP took a
long time to get them, and required a baroque explicit capturing notation for
it. Java faked them with anonymous inner classes which, while fitting smoothly
into the surrounding class-based object-oriented paradigm, were too verbose. C#
eventually got a decent lambda notation but went through years of implementing
overly specialised forms of it in different guises such as _delegates_.

To give Perl and JavaScript credit, they got lambdas mostly right early on.
Also, once Java added lambdas in version 8, it was not only a concise syntax but
one fitted into the surrounding statically-typed class-based OOP paradigm well.

---

Unfortunately, the proliferation of lambdas in mainstream curly-brace languages
has led to undesirable trade-offs over the years.

Most mainstream languages went with the same approach: a parameter list
surrounded with parentheses, each parameter separated by a comma, followed by
either `=>` or `->`, finished with a code block. They usually provide two pieces
of syntactical sugar: dropping parentheses for single-parameter lambdas and
replacing the code block with a single expression directly after the arrow.

This approach has problems, which perhaps explains why newer languages like
Swift, Rust, and Kotlin didn’t copy the syntax.

For starters, what does this mean?

```javascript
const f = (x, y, z) => x + y + z;
```

Languages with a comma operator must parse a potentially limitless parameter
list before, only right at the end, working out whether it is the comma operator
evaluating multiple variables or a parameter list. Until it sees an arrow, it
can’t be sure and neither can a human reader.

Let’s assume most C-style languages created in the decade are smart enough to
drop the comma operator, doesn’t that fix the problem? Well, what does this
JavaScript snippet do?


```javascript
const f = ({ a, b: c }) => a + c;

```

Is this an object literal or a parameter list destructuring an object argument?
There’s no comma operator here, yet the parser must still chew through
potentially unlimited tokens before being able to finally work it out by seeing
the arrow.

---

Let’s take a quick detour into why this is actually a problem.

Firstly, if a computer can’t work out what it is by looking at the start of the
expression, neither can a human. There becomes a linear growth in time taken to
disambiguate the expression depending on how long the expression is.

Secondly, changing the interpretation of already-parsed tokens based on future
tokens frustrates the left-to-right flow of the language, requiring
outwards-from-centre reading to work out exact behaviour.

Finally, tooling such as syntax highlighting in editors have a greater
likelihood of parsing them correctly if it can unambiguously work out syntax
without unlimited lookahead.

---

Kotlin clearly understood this problem, opting to _start_ a lambda expression
with a distinguishing character:

```kotlin
{ x -> x * 2 }
```

This is clearly more verbose than a single-expression braceless lambda of
other languages like JavaScript:

```javascript
x => x * 2
```

Realising this, I can only assume Kotlin’s designers added syntactical sugar to
offset the additional verbosity:

```kotlin
{ it * 2 }
```

It uses an `it` implicit pronoun keyword to refer to a first parameter to avoid
spelling it out, but the more noteworthy point is that the arrow can be dropped
from lambdas that have no explicit parameters.

Destructuring in lambdas is a common feature in statically-typed functional
languages. Let’s see how it would hypothetically look if Kotlin went beyond
destructuring position "components" as it currently does and allowed
destructuring arbitrary named fields:

```kotlin
val printList = { List(head, rest) ->
    println(head)
    when (rest) {
        is List -> f(rest)
        is Nil -> println("Finished")
    }
}
```

What happens when the parser sees the first `List`? As arrows can be dropped, it
has no idea whether it's a zero-parameter lambda returning a `List` or a lambda
destructuring a list as a parameter. Like earlier examples it must just chew
through tokens, shrug at ambiguities, and work it all out later based on whether
it sees an arrow. This means Kotlin would have a few issues to resolve if it
ever wanted to add deeper destructuring support to its lambdas.

Kotlin has another problem with lambda syntactical sugar. Passing blocks to
methods like this is a common feature of mainstream languages with lambdas,
giving a less cluttered feel:

```kotlin
list.forEach({
    println(it)
})

list.forEach {
    println(it)
}
```

However, if syntax doubles up as both a legitimate start to an expression and
syntactical sugar, it will collide with implicit statement termination. That is
a feature common among new C-like languages to avoid requiring the developers to
write semicolons after every line.

For example, what does this mean?

```kotlin
object.method
{ x * 2 }
```

Is it invoking a zero-parameter method and then evaluating a lambda as a
separate expression, or is it passing a lambda to the method as a final
argument? It turns out that Kotlin parses it very differently from this:

```kotlin
object.method { x * 2 }
```

Program behaviour can drastically change based on whitespace like newlines even
though the code has the same sequence of tokens.  Kotlin is hardly unique in
this regard, most modern C-like languages have problems like this.

Enough probing Kotlin, let's take a look at a strange Swift edge case caused by
a similar feature:

```
$ swift
Welcome to Apple Swift version 4.2.1 (swiftlang-1000.11.42 clang-1000.11.45.1). Type :help for assistance.
  1> func f(g: () -> Void) -> Bool {
  2.     g()
  3.     return true
  4. }
  5> f { print("Hello!") }
Hello!
$R0: Bool = true
  7> if f { print("Hello!") } { print("It was true.") }
error: repl.swift:7:6: error: trailing closure requires parentheses for disambiguation in this context
if f { print("Hello!") } { print("It was true.") }
    ~^
    (g:                 )
```

How can Swift work out whether the first block is passed to `f` or whether `f`
is a standalone value and the block is for the truthful case? My guess is that
Swift works out that another block on the same line came straight afterwards,
and because standalone closures aren't allowed as standalone expressions in
Swift, it made a good guess as to the ambiguity's origin.

The point is that Swift can't know straight away by just looking at the start,
it must wade through an unknown number of tokens before it can make an informed
choice.

As a reminder, parsing that involves reinterpreting previous tokens based on
future ones isn't just a parser implementation complication, it makes languages
harder to read for humans and tooling alike.

---

All of these issues perhaps explain why functional languages went with a
slightly more verbose lambda syntax and often didn't provide special syntax when
passing them to functions:

```
% Erlang
fun(X) -> X * 2 end

-- Haskell
\x -> x * 2

(* OCaml *)
fun x -> x * 2
```

In these forms, destructuring just works, whitespace isn't needed to
disambiguate, and parsing ambiguities don't emerge.

---

Let's say that we _really_ want some syntactical sugar for lambdas in our C-like
language but want to also side-step the aforementioned problems. What is the
best approach to take?

The starting token must be unambiguous to avoid the problems of Java,
JavaScript, and C#. We also must not allow a shorthand for zero-parameter
lambdas that allows dropping tokens that unambiguously distinguish the first
parameter from a standalone expression. Following these rules, we can come up
with a lambda syntax like this:

```
-> x { x * 2 }

-> { println("Hello, world!") }
```

It's not particularly elegant when passed to other functions though. Compare
this hypothetical syntax with Java's lambdas:

```
forEach(list, -> x { x * 2 })
forEach(list, x -> x * 2)
```

Let's add in two pieces of syntactical sugar that don't break the constraints
that were laid out. The first one will be the introduction of the `it` keyword,
the Kotlin shorthand shown above that appeared many years prior as anaphoric
macros in Lisp. Let's also throw in the ability to pass a lambda
outside of calling parentheses.

```
forEach(list) -> {
    it * 2
}
```

By starting with an arrow, the problem of clashes with blocks being passed to
built-ins is also averted, avoiding Swift's issue. However, it still has
Kotlin's problem: the syntactical sugar for passing lambdas as final arguments
leads to an ambiguous parse. Kotlin solves this by changing how code is parsed
based on the presence of newlines, but is there a better way?

What if the `->` token signified _only_ the syntactical sugar and not a lambda
literal too? What if lambda literals couldn't be spelled out directly but
could be created by passing the block syntactical sugar to an identity function?

```
List(1, 2, 3)
    .map -> { it * 2 }
    .filter -> { (it % 2) == 0 }
    .forEach -> { println(`{it}`) }

T fn<T>(T x) {
    x
}

var f = fn -> { it * 2 }
var y = f(x)
println(`{y}`)
```

This makes standalone lambdas more verbose but most lambdas are passed directly
to other functions in practice. It solves most of the problems listed in this
article but at the expense of making lambdas less notationally elegant. It's but
one of many alternatives new C-style languages could choose.

---

Most mainstream languages have added ambiguities and edgecases to accomodate
cleaner lambda notations, but is the tradeoff worth it? Apparently they think
so. After all, how many developers are really going to pass a block-receiving
lambda as an `if` condition or expect a block on a different line from a call to
be passed into it?

Programming languages are full of tricky tradeoffs like this, often with no
correct answer. Keep this in mind when perusing the endless self-entitled GitHub
users creating issues against the implementation of their language of choice and
claming that "obviously" a feature should be added in a certain way, that they
"see no reason why not", and the mother of all programming language myths, that
"those who don't like the feature don't have to use it, and therefore won't be
affected by it".

