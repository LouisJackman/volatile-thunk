title: Timing Attacks: Why being Efficient can Leak Information
date: 2018-07-29 12:00
tags: security, appsec, timing attacks
---
Writing secure programs is often just about learning how to avoid pitfalls and common mistakes. However, it sometimes
involves working against the fundamentals that programmers are taught from an early stage. For example, writing the
most efficient code to perform a specific task can leak information to adversaries.

Performance concerns have begotten some of the most impressively convoluted hacks in computing history such as
[Doom's infamous square root floating point hack](https://en.wikipedia.org/wiki/Fast_inverse_square_root):

```c
i = * ( long * ) &y; // evil floating point bit level hacking
i = 0x5f3759df - ( i >> 1 ); // what the fuck?
```

It's a constant theme across many subdomains of software development from embedded programs written in C, to Python
scripts driving high-level computations for biologists. The performance concerns are focused at different levels of
abstraction throughout but all seek the same: the machine taking less time and power to get the same result at the
level of required precision.

***

The time taken to compute some data is one of its pieces of metadata. For a domain of data, the data computable
within a specific window of time is usually a subset. Whether that's a problem depends on a few variables: how
sensitive the data is, whether an adversary can accurately observe the time taken to compute it, and how useful that
observation is at ascertaining the underlying data.

Put another way, the time taken to compute something is potentially a side channel attack that narrows down the
otherwise hidden data.

Take a hypothetical so-far unbroken cipher used by a cryptosystem. Plaintext documents are submitted to it via HTTPS.
Assume the adversary only sees the communication "metadata" like times. If they only see the ciphertext result, it's
safe, but what can they do with those communication times?

An obvious case is larger documents taking longer to encrypt than smaller ones. Observing multiple documents allows
mapping time taken to the relative document size. That isn't useful for the adversary unless they have a several
plaintext candidates, one of which is the leaked one, and they use the leaked size information to narrow it down.

A less obvious case is the different times to encrypt documents of the same size but with different content. Modern
ciphers make this damn difficult precisely because they are designed to avoid timing attacks, often by using
constant-time operations.

***

What about operations which don't involve cryptography but straightforward equality checking? Most algorithm's like
C's `strcmp` or `==` used with strings in JavaScript and Python just iterate through the two strings, returning
prematurely if a character mismatch is detected. That means the longer the request takes, the closer the guesses are,
allowing an adversary to narrow it down.

```c
// The GNU Standard C Library's implementation of `strcmp`.

int
strcmp (p1, p2)
    const char *p1;
    const char *p2;
{
    register const unsigned char *s1 = (const unsigned char *) p1;
    register const unsigned char *s2 = (const unsigned char *) p2;
    unsigned char c1, c2;

    do
    {
        c1 = (unsigned char) *s1++;
        c2 = (unsigned char) *s2++;
        if (c1 == '\0')
            return c1 - c2;
    }
    while (c1 == c2);

    return c1 - c2;
}
```

Such an attack is usually not viable though. For most strings of a reasonable length like IDs or passphrases, such
checks are a microscopic performance detail that will be drowned out by noise like the network latency, server OS
process scheduling, and the webapp's garbage collection. It might be theoretically possible if a great many request
times are averaged out and the adversary can make almost unlimited attempts repeatedly, but that usually isn't the
case for most modern authentication systems.

For places where constant time operations are needed, how are they written?

To start with, the amount of times a procedure can loop should be fixed regardless of input. A string comparison
might remove the premature return in favour of a `found` boolean flag and won't finish looping until a fixed amount
of iterations through the string are complete.

```java
public static boolean equals(CharSequence xs, CharSequence ys, int minElementChecks) {
    int result = 0;
    int xsLength = xs.length();
    int ysLength = ys.length();
    for (int n = max(xsLength, max(ysLength, max(minElementChecks, 1))) - 1; 0 <= n; --n) {
        int x = (n < xsLength) ? xs.charAt(n) : -1;
        int y = (n < ysLength) ? ys.charAt(n) : -1;
        result |= (x ^ y);
    }
    return result == 0;
}
```

In fact, this problem can be generalised from loops to varying jumps in code. "Short-circuting" is the behaviour in
almost all modern programming languages that ensures a second boolean isn't evaluated if the first automatically
rules it out. It can cause varying jumps depending on the input data. If two booleans are used in an `if` and
combined with a `||`, the second operation won't be run at all if the first passes. So if it takes a lot longer to
reject a condition than average, an adversary could work out that the first condition passed, allowing them to narrow
it down. This could be used for tricks like user enumeration.

This often results in algorithms using various workarounds like dropping NOP operations into unexpected places, using
bitwise operations to avoid short-circuiting, and pretending all input data is the same length for the purposes of
iteration.

***

Ultimately, when writing higher level applications like webapps, we shouldn't worry too much about these kinds of
timing attacks except for the most glaring of cases. Differences in timings will often be drowned out by other
"performance noise" or will deal with data complex enough to make it infeasible to derive it from the time taken.
Worrying about timing attacks in all algorithms could quickly drive a developer to insanity. Focus on areas dealing
with particularly sensitive data that can be more easily derived from timing and leave it at that.

That said, the lower levels of computer architecture are encountering similar problems with far reaching
consequences. Modern CPUs have features like multi-level shared caches, concurrent execution within single cores, and
branch prediction. These features can take different amounts of time to complete their operations depending on the
data passed in, such as what is stored in the caches.

I'll leave you with this example of Spectre in C on [Exploit DB](https://www.exploit-db.com), using timing attacks to
derive data from CPU caches: [https://www.exploit-db.com/exploits/43427/](https://www.exploit-db.com/exploits/43427/)
