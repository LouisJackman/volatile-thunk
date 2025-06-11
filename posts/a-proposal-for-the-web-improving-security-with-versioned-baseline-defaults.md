title: A Proposal for the Web: Improving Security with Versioned Baseline Defaults
date: 2019-10-01 12:00
tags: html, javascript, http, security, appsec, css
---
The importance of sane defaults in software is too often overlooked by
technical people. Users routinely witness the benefits of them, albeit rarely
consciously.  Providing a sensible default for a customisable option is the
difference between a configuration being secure per usual versus being an
explicitly-enabled anomaly toggled on solely by enthusiasts.

Web developers use software to produce artefacts, like users in many other
domains, but rather than options tweaked by button presses or dial dragging,
they configure “options” with HTML elements, HTTP headers, JavaScript APIs, and
CSS features.

## Maintaining Compatibility

The web has evolved since the ‘90s and has admirably maintained an impressive
degree of backwards-compatibility throughout. This puts it in that rare category
of software, the Unix-like operating systems and Lisps of the world, the few
digital tools that build atop a fundamental philosophy and accrue evolutionary
changes over time without routinely reworking the foundations. These tools put
the others and their ecosystems to shame; Node.js libraries, for example, are
lucky to go for three years without going through a set of sweeping changes that
break user’s code.

Such compatibility does however come at a cost. The POSIX filesystem standard
that evolved from Unix leaves modern security as an afterthought; a global
filesystem with a root protected primarily by ACLs, access control lists, isn’t
secure enough for most users. More modern operating systems are breaking POSIX
compatibility by providing isolated persistent datastores for each “app” or
providing access via granted capabilities rather than giving carte blanche over
the whole filesystem and hoping the ACLs and other controls like chroot jails
are tight enough.

The web has a similar conundrum. Changing the default behaviour to improve the
security of webpages (or more likely _webapps_ these days) will break existing
pages that used to work just fine, but is it really acceptable in this age to
allow JavaScript access to session cookies by default or to allow embedding the
page within others unless stated otherwise?

## Declaring which Set of Defaults to Use

There are many ways in which to change the defaults of the modern web to improve
security. HTTP headers could fallback to secure values if omitted, HTML elements
could adopt new default behaviours such as `iframe`s sandboxing _unless_ a
`nosandbox` attribute is specified, and JavaScript’s global objects could be
made mostly immutable to prevent nefarious monkey-patching by a loaded script
whose integrity has been compromised.

To keep this proposal focussed, let’s stick to new HTTP header defaults
initially. As headers are loaded before other content, it could be expanded to
the other areas at a later date.

A new header must be added to either the HTTP 1.1 or 2.0 response to trigger
this feature. Messing around with the HTTP protocols themselves would create too
many problems whereas adding new headers is a safe operation in all browsers
today, especially if they’re rolled out with an `X-` prefix during the proposal
phase. Using a header also means it’s propagated across conversions between HTTP
1.1 and HTTP 2 which often done in cloud-based loadbalancers.

This new header will be special. Its presence will change how other headers are
parsed, meaning browsers will have to hold off on acting upon other header
values until this header is either found or can be ruled out due to its absense.
Parsing headers is presumably not a performance bottleneck in modern browsers
but this should be considered by those more knowledgable in that area.

Assume the header is called `X-Baseline-Defaults-Version` with values like
`1.0`. There are plenty of names that would suit it and the numeric versioning
scheme could be one of many such as basic single-number versioning or even full
semantic versioning. This is bikeshedding; so long as different baseline
defaults can be versioned and therefore distinguished, it’ll work towards the
goal.

Consider this hypothetical HTTP response:

```
HTTP 1.1 https://volatilethunk.com/index.html
Content-Type: text/html
Set-Cookie: session=foobar

<h1>The Forum</h1>

<form action="post">
  <label>Subject<input name="subject"></label>
  <label>Post<input name="post"></label>
  <input type="submit">
</form>
```

Running an automated scan by OWASP ZAP, Nikto, or Burp Suite yields the usual
suspects: a cookie not set to `HttpOnly`, `SameSite`, and `Secure`, potentially
XSS’ed scripts allowed inline due to the lack of a content security policy,
being embedded into a frame of an untrusted site is tolerated, content type
sniffing is tolerated in older browsers, URLs are leaked via the `Referer` field
to other websites, there’s no feature policy restricting the site to features it
actually needs to use, and probably more.

Let’s fix the first five by adding some headers via our web server:

```
HTTP 1.1 https://volatilethunk.com/index.html
Content-Type: text/html
Content-Security-Policy: default-src: 'self'
Set-Cookie: session=foobar; Secure; HttpOnly; SameSite=strict
X-Frame-Options: deny
X-Content-Type-Options: nosniff
Referrer-Policy: same-origin

<h1>The Forum</h1>

<form action="post">
  <label>Subject<input name="subject"></label>
  <label>Post<input name="post"></label>
  <input type="submit">
</form>
```

The list of the recommended HTTP headers has grown over time. For the majority
of sites that should use them, web developers must “just know” what they are and
remember to add them or use a framework that does it for them. A well written
website can end up with half a dozen or so just to turn on the recommended
security mechanisms of the web. They’re too easy to forget and increase the
barrier to entry to creating secure sites by adding to the myriad tricks that
web developers must “just know”.

If it's decided that at least the first five additions should be default for new
webpages unless explicitly stated otherwise, the new proposal looks like this:

```
HTTP 1.1 https://volatilethunk.com/index.html
Content-Type: text/html
Set-Cookie: session=foobar
X-Baseline-Defaults-Version: 2

<h1>The Forum</h1>

<form action="post">
  <label>Subject<input name="subject"></label>
  <label>Post<input name="post"></label>
  <input type="submit">
</form>
```

Rather than explaining to developers every security feature they should enable
for new sites, guidelines can just write: “remember to use version 2 in the
`X-Baseline-Defaults-Version` header”. Only when those developers _must_
relax those security constraints do they need to learn about them. The more
secure options become the default state of affairs and out of the minds of
developers until they really need to dial them down.

Increasing of security on existing pages a more robust. Rather than sprinkling
security-related headers across the pages, one line can be added to bump up the
baseline defaults to a newer version and then options can be explicitly relaxed
if necessary to keep existing functionality working.  Both methods are valid
however, developers can use either one to improve security by approaching it
from two different sides: gradually adding security versus adding all of it
and then relaxing the new constraints as necessary.

## The Proposed Version 1.0 Defaults

Thankfully, most HTTP headers provide explicit values for the existing default
settings if otherwise left unspecified. These can be used to relax the
constraints of new baseline defaults. Here’s what the baseline could set the new
default values to:

```
|Header Name            |Proposed New Default              |
|-----------------------|----------------------------------|
|Set-Cookie             |SameSite=Strict; HttpOnly; Secure |
|Referrer-Policy        |same-origin                       |
|Content-Security-Policy|font-src: '*'; frame-src: '*';    |
|                       |media-src: '*';                   |
|                       |default-src: 'self';              |
|                       |sandbox allow-forms allow-scripts;|
|                       |form-action: 'self'               |
|Feature-Policy         |ambient-light-sensor 'none';      |
|                       |autoplay 'none';                  |
|                       |accelerometer 'none';             |
|                       |camera 'none';                    |
|                       |display-capture 'none';           |
|                       |document-domain 'none';           |
|                       |encrypted-media 'none';           |
|                       |fullscreen 'none';                |
|                       |geolocation 'none';               |
|                       |gyroscope 'none';                 |
|                       |microphone 'none';                |
|                       |midi 'none';                      |
|                       |payment 'none';                   |
|                       |picture-in-picture 'none';        |
|                       |speaker 'none';                   |
|                       |sync-xhr 'none';                  |
|                       |usb 'none';                       |
|                       |wake-lock 'none';                 |
|                       |webauthn 'none';                  |
|                       |vr 'none'                         |
|X-Content-Type-Options |nosniff                           |
|X-Frame-Options        |deny                              |
|X-XSS-Protection       |1; mode=block                     |
```

## Notes on Some Headers

The proposed defaults are designed to be usable in most contexts while fixing
the most egregious issues and to give the most "bang for your buck" without
diverging _too_ far from the web's fundaments.

The `Set-Cookie` value only changes the default flags added to user cookies when
they are not stated explicitly; it isn't replacing the whole header value when
no cookies are set.

Referrer policy `same-origin` stops leaking user history to third-party pages
while still allowing pages to know whether they have come from an internal page.

The proposed `Content-Security-Policy` value keeps basic resources, such as
images and fonts, loadable from remote locations in order to keep the majority
of the resource loads of the common web intact while blocking third party
scripts by default. Even this will be quite a breaking change as a default,
given the amount of sites using third party tracking scripts like Google
Analytics.

The content security policy also specifies a sandbox, which are no longer
limited to `iframe`s but can now be specified for top-level pages too. This one
allows forms and scripts but not more intrusive features like pop-up windows
(which most browsers block by default anyway).

Feature policies need exhaustive lists for a reason: so that the web standards
bodies like WHATWG can add new restrictions at a later date without breaking
compatibility. That's presumably why there isn't an option for blocking all
features. The proposed new default opts out of the more specialised features,
but a complex webapp will be expected to toggle some of these back on,
one-by-one.

`X-Content-Type-Options` and `X-XSS-Protection` could be omitted. The reality
is that they're designed to work around counter-intuitive behaviour or enable
antiquated protections in older browsers, neither of which apply to newer
browsers. A browser new enough to support this proposal won't have these
problems.

`X-Frame-Options` is set to `deny` because allowing a page to be embedded is
usually a niche requirement, usually only suitable for pages that have been
explicitly designed for it such as social media widgets.

`Cross-Origin-Resource-Policy` could be toggled to `same-site` as a new default.
Whilst this would make sense, it would also break a fundamental assumption that
sites have been able to make since the '90s: that at least basic assets like
images can be loaded from other domains. It was omitted.

`Strict-Transport-Security` is a worthy contender for HTTPS pages, but who would
decide on a good common `max-age` value?

`Content-Type` could default to UTF-8 for the character sets, but that seems to
be in the realm of _modern_ default values rather than _secure_ default values
per se.

## Conclusion

The goal of this proposal isn't to aid web framework authors or established
companies with equally established webapp codebases. They will have both the
resources and the knowledge to add sensible default header values over time as
they are released and refined by the standards organisations.

It is instead aimed at new developers wanting to use learn and use standard web
technologies. Let's give them a single header to remember to add:
`X-Baseline-Defaults-Version`. With that one "neat trick" to remember, a whole
raft of sensible security defaults can be toggled on by default, out of sight
and out of mind, guiding new developers towards writing secure web applications
from the beginning.

By versioning baselines of defaults for parts of the web like default HTTP
header values, we acknowledge that the web is an evolving platform whose
changing direction often surprises even its more seasoned users. Sometimes we
need to reflect on a few years worth of recently added features and ask
ourselves whether the web's current defaults reflect the most idiomatic, simple,
robust, and secure way of using them both as a whole and in conjunction with
existing features.

