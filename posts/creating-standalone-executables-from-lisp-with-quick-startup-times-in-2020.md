title: Creating Standalone Executables from Lisp with Quick Startup Times in 2020
date: 2020-12-06 12:00
tags: clojure, lisp
---
Like Smalltalk, Lisp has historically lived in a world unto itself. Code is
added and amended within a live environment, causing it to evolve over long
sessions. Occasionally these sessions are snapshotted into images. However,
mainstream computing went a different route, making Lisp integrate poorly into
the modern computing landscape.

Software development journeys nowadays use short-lived, isolated tasks composed
together from static artefacts. Unix programs are composed in the shell for
one-shot usages, artefacts are baked with compiled languages, and servers run
from transient Kubernetes pods that die at any point according the whim of the
cluster cloud's autoscaling policy.

How can we [beat the averages](http://www.paulgraham.com/avg.html) while
producing artefacts that fit into the contemporary computing environments of
this decade? I'll assume you have a basic curiosity of Lisp and won't be
frightened off by [the parentheses](https://xkcd.com/297/).

## The Importance of Quick, Standalone Executables

How can Lisp be made more amenable to such environments? Creating standalone
executables with a quick startup time is an important step. Keeping environments
running in the background and connecting to them is a common counter-proposal
from Lisp advocates. The community that surrounds
[Clojure](https://clojure.org/), a Lisp dialect that runs on the Java Virtual
Machine, often raise this solution. Just run a REPL as a daemon and keep it
running for long periods of time. Ignore the problems of unintentionally accrued
state, despite programming in an ostensibly functional language. This solution
isn't so much an actual solution as an excuse for its (historically) bad startup
times.

The Clojure community seem to have realised this, improving startup times and
refining the command-line tooling support with its standard `clj` tool.
[Racket](https://racket-lang.org/) can also produce native executables, as can
Common Lisp implementations such as [SBCL](http://www.sbcl.org/).

Let's look at a specific approach for creating good ol' command-line tools for
Linux and macOS specically in the Lisp dialect Clojure. Let's assume the consumer
of said tool has no interest in Lisp and just wants to drop an executable into
their `PATH` and run it. This is why DevOps personnel give a sigh of relief
when they see a tool written in Go. They know it translates to an executable
they drop onto their system with no further complications. Nobody wants to deal
your language's ecosystem concerns just to run a tool. Take note, Node.js and
Python. Dealing with obscure npm and pip breakages is hardly the highlight of a
developer's day who just wants to run your tool rather than getting knee-deep in
debugging it.

## Introducing: GraalVM Native Images

Escaping the Java ecosystem has been an objective of some Clojure fans. They see
it as a "ball and chain", to borrow Steve Job's criticism of Java. This
represents a larger split in the Clojure ecosystem: those who see it as a
refreshingly modern Lisp with an unfortunate dependency on the Java platform on
one side, and those who see its integration with the Java as one of its greatest
selling points on the other.

One narrative is that once its symbiotic relationship with the JVM is
deprioritised in its wider ecosystem, it can use other implementations to better
target the domain of tools that expect a quick startup and no dependencies.
Ironically, this narrative has been turned on its head with recent developments;
the best attempt at that end-result has come from inside the Java ecosystem, not
outside.

[GraalVM](https://www.graalvm.org/) has been a hot topic in the Java community.
It has a lot of capabilities, but let's focus on its _native imaging_ feature.
It allows Java applications to perform ahead-of-time compilation after shaking
out the unnecessary dependencies, emitting a standalone executable. Bundled with
that executable is a subset of the JVM needed to run the application. This is
conceptually similar to how Go embeds its runtime into built images. Java
applications cover anything targeting the Java platform, which means Clojure and
other Lisps targetting the JVM.

The Java platform historically focusses on just-in-time compilation. To support
ahead-of-time compilation, GraalVM puts some restrictions on Java applications.
The [_substrate
VM_](https://www.graalvm.org/reference-manual/native-image/SubstrateVM/) has
purposely-designed restrictions accordingly. Clojure itself has recently become
more amenble to these restrictions, as well as improving startup time in
general.

This means Clojure with GraalVM does a substantially better job than some other
Lisps at creating executables. Dumping a whole image of a live Lisp system --
the traditional way of generating standalone executables in Lisp dialects -- is
a suboptimal technique for producing compact artefacts. A process designed for
ahead-of-time compilation with an aggressing shaking-out of unused dependencies
produces tangibly better results. That said, tree-shaking has been attempted in
the Common Lisp ecosystem too. [Roswell](https://github.com/roswell/roswell), a
Common Lisp development environment management tool, offers tree-shaking before
building into native excutables. Schemes can produce small executables,
specifically when being embedded into native codebases written in languages like
C, owing to how small the language is.

Disk space is an obvious metric for this for assessing how effective unsed
dependencies are being shaken out. A "hello world" Clojure program produces a
11MB executable for me. The SBCL equivalent is orders of magnitude larger,
although Roswell's tree-shaker gets it down to about 15MB for my most recent
"hello world" attempt. 11MB is arguably 10MB too large for "hello world", but it
seems within the bounds of acceptability in 2020. Executables around 100MB
really aren't, which are sadly common for modern image-snapshotting approaches.
The startup time is also in Clojure's favour compared to other dynamic
languages, countering an accumulated bad reputation in that area.

Let's retrace my steps. How did I arrive at this 11MB executable with a
competitive startup time?

For those not familiar with Clojure, let's create the basic Hello World project
step by step.

## Setting Up Clojure & GraalVM

[Install Clojure](https://clojure.org/guides/getting_started) if you haven't
already. Clojure itself works just fine on Windows, but getting it, GraalVM, and
Clojure-friendly editors working together on that OS is an exercise in endless
toe-stubbing. Proceed at your own peril; I got close but gave up. It works great
in [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install-win10) though,
and works as well as you'd expect on native Linux and macOS. After installation,
`clj` and other tools should be on your `PATH` after restarting your shell.

That's enough to get small scripts working:-

```shell
$ echo '(println "Hello, world!")' >main.clj
$ clj -M main.clj
Hello, world!
```

Scripts that need an interpreter installed are all well and good, but what about
producing executables?

Getting GraalVM installed is necessary for anything running on the JVM to be
natively imaged, Clojure or otherwise. Install it using the instructions on
[their site](https://www.graalvm.org/downloads/).

Unpack that archive somewhere handy. Assuming you put it in `~/graalvm`, add its
programs to your `PATH` and export a new environment variable `GRAALVM_HOME`
with it. In short, add this to your shell's configuration:

```shell
export GRAALVM_HOME="$HOME/graalvm"
export PATH="$PATH:$GRAALVM_HOME/bin"
```

A future version or different target OS might use a full installer instead, in
which case you’ll need to hunt down that directory for yourself.

Assuming GraalVM programs like `gu` are now on your `PATH`, grab its
native-image component:-

```shell
gu install native-image
```

Now the sysadmin [yak-shaving](https://en.wiktionary.org/wiki/yak_shaving) is
over, let's move to the more Lispy yak-shaving.

## Creating a Basic Project with deps.edn

There are multiple Clojure build tools out there such as
[Leiningen](https://leiningen.org/) and
[boot](https://github.com/boot-clj/boot), but they will be avoided in favour of
the relatively new standard Clojure support for project definitions. This new
way, termed `deps.edn`, works out of the box for modern versions of Clojure.

First, let's create the project directory and scaffold some basic files and
directories.

```shell
$ mkdir test-project
$ cd test-project
$ mkdir -p classes src/test-project
$ touch deps.edn
```

`deps.edn` describes the project, whereas `src` contains the Clojure source files
for the project. `classes` is needed for building, but can be ignored for now.

Fill in the `deps.edn` file with this:-

```clojure
{:paths ["src" "classes"]
 :deps {org.clojure/clojure {:mvn/version "1.10.2-alpha4"}}
 :aliases {:native-image
           {:main-opts ["-m clj.native-image test-project.core"
                        "--initialize-at-build-time"
                        ;; optional native image name override
                        "-H:Name=test-project"]
            :jvm-opts ["-Dclojure.compiler.direct-linking=true"]
            :extra-deps {clj.native-image/clj.native-image
                         {:git/url "https://github.com/taylorwood/clj.native-image.git"
                          :sha "7708e7fd4572459c81f6a6b8e44c96f41cdd92d4"}}}}}
```

[EDN](https://github.com/edn-format/edn) is a data format similar to JSON and is
commonplace in the Clojure ecosystem. It's more expressive than JSON but less
well-known. It's a subset of Clojure, so there's no redundency of knowledge to
learning the syntax. Like JSON, `{}`s are key-value pairs and `[]`s are sequences.
Keys are usually denoted with so-called "keywords" prefixed with a colon rather
than JSON's standard of using strings, and you can also drop the commas. EDN can
use non-keywords for keys too. Split words in an identifier using hyphens rather
than `camelCase`; this is known as `lisp-case` or `kebab-case`.

Congratulations; if you're completely new to Clojure, you've already learned a
vast amount of the language's syntax from this EDN snippet. Yet another perk of
homoiconocity.

The `:paths` entry is a common affair for Clojure projects, telling Clojure
where to look for files. `:deps` lists Clojure 1.10.2 Alpha 4 as a dependency.
While Clojure being a dependency is self-evident in a deps.edn file within a
Clojure project, the version is spelled out explicitly. It also makes clear that
created artefacts, such as uberjars, need to bundle Clojure along in order to
run the program.

Why an alpha release? I had problems producing native images with 1.10.1. I
discovered that the hard way so that you don't need to. Let's hope 1.10.2 is
released soon so that a stable release can be used. For what it's worth, an
alpha release in Clojure land is still far more stable than most "stable"
libraries in Python or JavaScript. Clojure is generally slow-moving and
mercifully free of a [cascade of attention-deficit
teenagers](https://www.jwz.org/doc/cadt.html).

So far the fields have been about Clojure projects in general. The final big
one, `:aliases`, is used here to utilise GraalVM's native imaging. This is using
the third party package `clj.native-image`, which can be found [on
GitHub](https://github.com/taylorwood/clj.native-image). This `deps.edn`
fragment was copied-and-pasted from [the project's
README](https://github.com/taylorwood/clj.native-image/blob/master/README.md#usage)
and tweaked for this use case.

Of note are:-

* The SHA sum `7708e7fd4572459c81f6a6b8e44c96f41cdd92d4` representing the
  version of `clj.native-image` to use. This git hash is used in the README but
  is actually quite out of date. Try with a later version! There are also
  release version tags, which are likely better to depend on for a "proper"
  project.
* The flags passed to GraalVM, such as `--initialize-at-build-time`, needed to
  successfully build Clojure projects. Also, the `-m` flag taking the
  entrypoint, and a `-H:Name` flag stating the name of the executable to create.
  Entrypoints will be discussed in a moment.
* A flag being passed to Clojure to trigger direct linking, which we want for
  native image generation: `-Dclojure.compiler.direct-linking=true`.

Clojure's ecosystem will hopefully adopt common values as defaults for this,
making this fragment simpler for most cases. For now, it's all needed.

Let's get to the crux of the program. It's a smidge more complex than "Hello,
World!". Put this in the new file `src/test-project/core.clj`:-

```clojure
(ns test-project.core
  (:gen-class))

(defn f [x]
  (when (pos? x)
    (println x)
    (recur (dec x))))

(defn -main [& args]
  (f 10))
```

In case you're new to Clojure, here's a summary:-

* `ns` declares the namespace, which is `test-project.core` here. Note that
  `test-project.core` mirrors the `src/test-project/core.clj` path.
* `defn -main` defines a function called main. As anyone with a passing
  familiarity with the Java platform will know, a main method within a class is
  the entrypoint.
* `:gen-class` generates a Java class from this namespace, which is necessary for
  that JVM entrypoint.
* The function `f` declared with the aforementioned `defn` is a toy countdown
  utility just to demonstrate that basic Clojure is working. Due to a JVM
  restriction, Clojure can't do proper tail calls. It has recur for a lot of
  cases you'd normally use tail calls.

The `gen-class` and `main` function dance is only needed once for a whole
project, not per file. If we wanted that much boilerplate per file, we'd just
use Java.

Finally, let's get the result we've been waiting for.

```shell
$ clojure -A:native-image
```

Assuming all went well, you'll see output like this without errors:-

```
[app:1988]    classlist:   3,954.70 ms,  1.19 GB
[app:1988]        (cap):   1,303.82 ms,  1.19 GB
[app:1988]        setup:   3,011.25 ms,  1.19 GB
[app:1988]     (clinit):     209.35 ms,  1.70 GB
[app:1988]   (typeflow):   6,374.83 ms,  1.70 GB
[app:1988]    (objects):   5,493.76 ms,  1.70 GB
[app:1988]   (features):     385.26 ms,  1.70 GB
[app:1988]     analysis:  12,786.73 ms,  1.70 GB
[app:1988]     universe:     576.30 ms,  1.70 GB
[app:1988]      (parse):   1,447.65 ms,  1.70 GB
[app:1988]     (inline):   1,481.76 ms,  2.25 GB
[app:1988]    (compile):  10,148.21 ms,  3.20 GB
[app:1988]      compile:  13,780.23 ms,  3.20 GB
[app:1988]        image:   1,467.49 ms,  3.20 GB
[app:1988]        write:     297.72 ms,  3.20 GB
[app:1988]      [total]:  36,101.59 ms,  3.20 GB
```

That scary-looking 3.20GB presumably refers to memory used and not the generated
executable size. `du` confirms that, reporting a comparatively-svelte 11MB size.

```shell
$ du -h test-project
11M     test-project
```

Off it goes to the races:-

```shell
$ ./test-project
10
9
8
7
6
5
4
3
2
1
```

It isn't quite as simple as a `go build`, is it? Also, this takes enough time that
you'd only run it for generating releases, meaning you have to stick to an
interactive REPL while developing -- although that's certainly no burden. This is
all true, but the vast majority of those steps were setting up a new project and
getting the right tools to hand. Once it's working, a project can rebuild with
just a `clojure -A:native-image`, and new projects need only copy across the
correct `deps.edn` configuration to get the same capability.

Besides, you don’t need to write `if err != nil {` anymore, so let’s call it a
draw.

Ah, but what about Clojure's dreaded startup performance?

```shell
$ time ./test-project
10
9
8
7
6
5
4
3
2
1

real    0m0.004s
user    0m0.004s
sys     0m0.000s
```

Nevermind. Someone wanting to grab a quick, handy tool from a GitHub releases
page won't mind throwing that into a complex shell pipeline. It's probably
quicker than whatever other languages are already in that pipeline. To wit:

```shell
$ cat >main.py <<EOF
def f(x):
    if 0 < x:
        print(x)
        f(x - 1)

f(10)
EOF
$ time python3 main.py
10
9
8
7
6
5
4
3
2
1

real    0m0.018s
user    0m0.009s
sys     0m0.009s
```

## What Does This Mean?

Emitting standalone executables with a quick startup opens Lisp up to the world
of DevOps tooling, handy command-line pipes à la `jq`, and more.

I'd recommend advertising such tools as being "native, standalone executables".
If you don't mention that explicitly on the project README, readers might spot
the use of Clojure and get nightmares about dealing with JVM `CLASSPATH` woes or
needing to install a Java runtime.

Winning hearts and minds, etc.

## A Side-Note about Other Lisps

_Lisp dialects have been able to do this since dinosaurs roamed the land_.
Producing native, standalone executables is not new. As mentioned at the start,
SBCL and Racket can both do this. However, Clojure integrates with a mainstream
platform (Java) and can use a technology that focuses more on AOT compilation
than just tree-shaking followed by image-snapshotting. That makes it a
compelling choice, even with the many equally-compelling alternatives out there
for Lisp.

Could I document those too? Yes, but this article is too long already.

Do I want to get into a which-Lisp-should-I-use debate? No. Just pick one.
Clojure is as good a choice as any.

Alternatively, you can use Common Lisp if you enjoy dealing with obscurist
naming conventions stemming from a political back-and-forth between MacLispers
or Interlispers in the '80s, or if you enjoy listening to how "neo-Lisps like
Clojure and Janet are not true Lisps". Interestingly, similar criticisms were
made about Common Lisp back in the day due to "unLispy" design choices like
keyword arguments, lexical scoping from Scheme, or missing
[fexprs](https://en.wikipedia.org/wiki/Fexpr).

If you don't want AOT-compiled standalone executables, but instead a Lisp
excellent at being embedded and for scripting, perhaps
[Janet](https://janet-lang.org/) is what you're looking for.

