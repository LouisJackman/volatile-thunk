title: To Secure Systems of the Future, We must Rethink our Notions of "Environment" and "Operating System"
date: 2019-02-10 12:00
tags: operating systems, appsec, security, environments, emacs
---
Language runtimes, operating systems, and software that provides a whole
working environment occasionally find themselves in conflict, blurring their
security responsibilities. On one end of the scale there are superficial similarities
like Rust's borrow checker trying to implement OS' memory safety but statically
at compile time rather than at runtime; on the other end there are Erlang/OTP and
Emacs which are effectively creating whole new operating systems bar the
hardware abstraction layer.

Sadly, a lot of these systems are not designed to be operating systems but are
treated as such by their users. Emacs is supposed to be a text editor but often
becomes the environment in which its users live, but it's poorly suited for that
role as its text editor origins means it doesn't contain even basic security
features that people expect of modern OSes like process isolation. A syntax
highlighting package can start intercepting password entry functions in
SSH-utilising packages like TRAMP.

Perhaps the computing industry as a whole needs to look at this overlap and have
an discussion about what layers should be providing security features like
isolation and permission checks, and which ones are solely for evaluating
already-trusted inputs.

It seems environments, operating systems, and language runtimes have intertangled
definitions and unclear responsibilities. I hope for a more clearly defined set
of layers.

## The Hardware

This one is self-explanatory. It's what realises our abstract programs, what
physically gets things done.

## HAL, the Hardware Abstraction Layer

Completely subsuming hardware abstraction layers into the definition of
an operating system is unhelpful. An OS provides a HAL but also often provide
unrelated features like GUI toolkits; compacting these layers into one entity
doesn't help discussion of security responsibilities.

## The Environment

Rather than just calling this the "OS", let's clearly distinguish it from the
HAL. It's the set of building blocks of the environment in which the user will
work even if it's mostly hidden behind UIs. It's the filesystems, the process
management, the local user account management, the ACLs, and more. A Lisp
machine and a Linux box will have a very different set of abstractions, but they
serve the same purpose: a hardware-agnostic set of abstractions for a
computation environment.

This environment needs to provide clear, robust, and comprehensive security
mechanisms. User accounts should be isolated, the datastore of choice (primarily
the hierarchal filesystem on popular environments today) should have access
controls, and processes need to be isolatable. It can ask the HAL to use
the underlying hardware to provide a second layer of enforcement of these
constraints but it shouldn't _completely_ delgate to it.

If it is sufficiently confident in its security layers, it is possible to
disable the secondary runtime checks in the underlying platforms to gain a
performance boost at the expense of security-by-layers. Contrary to what many
security engineers claim, tradeoffs like this can be a perfectly reasonable.
Security engineering isn't about acheiving absolute security but is instead an
economic tradeoff between security the other aspects of a system.

Again, why should an environment pay twice for a security constraint it is
already sure it implements properly?

A bonus point about making a clear distinction by splitting the definition of an
operating system into the HAL and the environment is the clarification that
such environments don't necessarily need a HAL as they can nest within other
environments, but that _the security mechanisms must still be enforced_.  As
mentioned previously, Emacs and other similar current environments fail at this.

## The User Interface

There isn't much to say about this except that the UI should not implement
security constraints but delegate to the environment, and should take care to
visualise and present these constraints in a way that is useful to the expected
user of the platform.

Providing security controls in a way that is easily digestable to the average
user is a topic out of scope for this post; needless to say, Linux is a prime
example of how _not_ to do this. iOS and Qubes OS are better examples.

## Rethinking Environment Layers and their Security Responsibilities

Rethinking the layers that make up an OS lays bare the ambiguities about which
layers should be handling what, and whether layers should be duplicating runtime
security checks from layers underneath.

Is the performance cost worth the benefits of security-in-layers, or is it an
unnecessary performance hit caused by environments not implementing security in
a sufficiently clear and robust way that they are willing to depend solely on it
and not delegate to lower levels?

Don't look at me, I have no idea. I've only just managed to formulate the
question, let alone one of the many right answers.

