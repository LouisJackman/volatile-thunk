# Volatile Thunk – Louis Jackman's Website

[![pipeline status](https://gitlab.com/louis.jackman/volatile-thunk/badges/master/pipeline.svg)](https://gitlab.com/louis.jackman/volatile-thunk/-/commits/master)

My website, using static page generation via
[Haunt](https://dthompson.us/projects/haunt.html).

## Posts

Posts are put in `posts`, named after their titles. They are written in
Markdown, and have metadata at the start like this:

```
title: A Proposal for the Web: Improving Security with Versioned Baseline Defaults
date: 2019-10-01 12:00
tags: html, javascript, http, security, appsec, css
---
The importance of sane defaults in software is too often overlooked by
technical people. Users routinely witness the benefits of them, albeit rarely
consciously.  Providing a sensible default for a customisable option is the
difference between a configuration being secure per usual versus being an
explicitly-enabled anomaly toggled on solely by enthusiasts.
```

## Pages

Pages are put in `pages`. Their names are their titles, snake-cased. They
appear as subpages on the main navigation menu rather than as articles. They
are otherwise written using a similar mechanism as posts.

## Publish

The blog can be published with `aws s3 sync 'site/' 's3://volatilethunk.com'
--delete`. This requires the `aws` command.
