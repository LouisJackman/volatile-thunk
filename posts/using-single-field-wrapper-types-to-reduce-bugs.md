title: Using Single-Field Wrapper Types to Reduce Bugs
date: 2019-08-19 12:00
tags: plt, java, types
---
Structuring and grouping data with types is only part of the correctness
guarantees that type checking offers; "newtypes", sometimes known as "wrapper
types" in Domain-Driven Development circles, is another important component.

Type checking is increasingly becoming the norm in software development.
Across many companies, JavaScript projects are being migrated to TypeScript, and
Objective-C to Swift. Even a bulwark of dynamic typing, Python, has ceded to the
importance of type checking in codebases once they surpass a certain size,
adding type checking in 3.5.

Before discussing single-field wrapper types, let's recap basic type annotations
for those more comfortable with languages without them. It involves annotating
code with the expected types for values such as parameters. Such types
include numbers, strings, booleans, arrays, maps, and custom composite groupings
of other types.

---

Nothing so far will be news to advocates of type checking. What might be new to
even seasoned developers of type-checked languages is the notion of a "newtype"
or a "wrapper type" in which there is only one field in the type:

```java
class Email {
    public String email;

    public Email(String email) {
        this.email = email;
    }
}
```

They might wonder about the point of this; an email address is a string, so why
not use that directly rather than wrapping it in a type that bundles no other
fields with it?

Static typing communities such as Haskell's and Go's have embraced this pattern
with features like `newtype`:

```haskell
newtype Email = Email String
```

A key advantages of this feature is that all usages of that value must
explicitly acknowledge that it is an email before extracting the underlying
string field.

This creates self-documenting code. Consider this method header:

```java
public void addUser(Email email, UserName userName) {
```

That arguably isn’t much more descriptive than using `String`s directly, but
look at the difference between these two callers, using a hypothetical web
framework to provide values from a HTTP request:

```java
String email = request.params.get("email").orElseThrow();
String userName = request.params.get("userName").orElseThrow();

// Using that API as it would normally be defined:
addUser(userName, email);

// Alternatively, using the "wrapper-type" style instead:
addUser(new UserName(userName), new Email(email));
```

Both of those calls have a bug in that they accidentally swap the parameters,
but only the second one blocks it at compile time.

---

There’s a bonus point too: a reduced need for keyword arguments, which is
especially useful for languages like JavaScript or Java that have weak or
non-existent support for them.

Consider this method header:

```java
public void copyFile(Path source, Path destination) {
```

When seeing it called, developers will often lookup the API documentation to
work out which way around the source and destination go. Wrapping those paths in
wrapper types makes it more obvious:

```java
copyFile(
    new CopySource(Paths.get("/home/user/Desktop/a.txt")),
    new CopyDestination(Paths.get("/home/user/Desktop/b.txt"))
)
```

Languages like Swift arguably make a lot of this unnecessary with keyword
arguments:

```swift
copyFile("/home/user/Desktop/a.txt", to: "/home/user/Desktop/b.txt")
```

This doesn't entirely eliminate the use of wrapper types though. Firstly,
wrapper types can be contained within other composite types like `struct`ures or
Java POJOs and maintain the benefits regardless of from where those fields are
eventually extracted. Secondly, the keyword syntax works very well with
functions simple enough to use DSL-like conventions such as prepositions and
gerunds e.g. "to", "from", and "using", but wrapper types seem to work better
with more complex parameter lists.

---

Even putting aside type annotations, there is a way of using dynamic wrapper
objects in languages like JavaScript to get a subset of the benefits:

```javascript
copyFile({from: "/home/user/Desktop/a.txt", to: "/home/user/Desktop/b.txt"})
```

It’s debatable whether this is emulating wrapper types or keyword arguments;
it’s doing both due to JavaScript’s "ex nihlo" types, its ability to conjure
objects out of thin air rather than instantiating classes.

It’s a type which is wrapping more primitive types, strings, but is also a
strong convention in the JS community for emulating keyword arguments, in which
the instantiation of the ex nihlo object is really just a workaround to get a
passable syntax for it. As all of the arguments are contained within a single
type rather than a separate type for each, it’s really more of an emulation of
keyword arguments than wrapper types.

Some languages like Kotlin and Scala, as well as the aforementioned Haskell,
make wrapper types easy to create; Java not so much. [Project
Lombok](https://projectlombok.org) makes this easier, but sacrifices simplicity
as it adds code instrumentation to your Java project. Code instrumentation
outside of languages specifically designed for it, like Lisp, is usually fraught
with edge cases. Thankfully, the developers of Java are refining a feature
called ["record types"](https://openjdk.java.net/jeps/8222777) which will make
the definition of wrapper types more svelte without relying on code
instrumentation. Until then, Java developers must choose between excessive code
or instrumentation.

---

I will use domain types for my own projects in which I’m writing something more
substantial than a quick script. Languages that have strong support for keyword
arguments make their usage less necessary, but can still be useful for complex
parameter lists and storing items in composite types such as `struct`s and
POJOs.

Adopting type checking is a multiphase process: first typing primitive parameter
types, then grouping data together in composite types, allowing types to become
the "gravity" for your program’s overall design, and now using wrapper types for
even single primitive types. There are plenty of other tricks to increase
reliability with type checkers, but those will be for another article. Thanks
for reading.
