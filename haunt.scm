;;;;
;;;; # VolatileThunk
;;;;
;;;; Louis Jackman's personal website, generated via
;;;; [Haunt](https://dthompson.us/projects/haunt.html). Haunt runs atop the
;;;; [Scheme](https://en.wikipedia.org/wiki/Scheme_(programming_language))
;;;; dialect [GNU Guile](https://www.gnu.org/software/guile/).
;;;;
;;;; Only break from Haunt's defaults to align with path conventions of the
;;;; old website, to avoid breaking old links and to retain existing SEO
;;;; levels.
;;;;

(use-modules (srfi srfi-13)  ; Strings
             (srfi srfi-19)  ; Dates/Times

             (haunt artifact)
             (haunt asset)
             (haunt builder assets)
             (haunt builder atom)
             (haunt builder blog)
             (haunt builder flat-pages)
             (haunt builder redirects)
             (haunt builder rss)
             (haunt html)
             (haunt post)
             (haunt reader)
             (haunt reader commonmark)
             (haunt site))


(define site-title "VolatileThunk")
(define site-name (string-append site-title " — Louis Jackman's Website"))
(define author "Louis Jackman")
(define description "Louis Jackman's Website")
(define site-domain "volatilethunk.com")
(define site-url (string-append "https://" site-domain))
(define cv-path "/louis-jackman-cv.pdf")
(define static-source-path "static")
(define keywords '("louis"
                   "jackman"
                   "volatile"
                   "thunk"
                   "volatilethunk"
                   "articles"
                   "blog"
                   "cv"
                   "resume"))

;; Override Haunt's defaults for these cases to retain path-compatibility with
;; the previous website.
(define posts-prefix "/posts")
(define pages-prefix "/pages")
(define rss-path "index.xml")
(define static-dest-path ".")

(define index-path "/index.html")
(define posts-page "/posts.html")
(define about-page (string-append pages-prefix "/about.html"))
(define contact-page (string-append pages-prefix "/contact.html"))
(define github-page "https://github.com/LouisJackman")


(define (base-template body)
  `((doctype "html")
    (head
     (meta (@ (charset "utf-8")))
     (title ,site-name)
     (meta (@ (name "viewport")
              (content "width=device-width, initial-scale=1.0")))

     ;; W3C Metadata
     (meta (@ (name "description")
              (content ,description)))
     (meta (@ (name "keywords")
              (content ,(string-join keywords " "))))
     (meta (@ (name "author")
              (content ,author)))

     ;; schema.org Metadata
     (meta (@ (itemprop "name")
              (content ,site-name)))
     (meta (@ (itemprop "description")
              (content ,description)))

     ;; OpenGraph Metadata
     (meta (@ (property "og:title")
              (content ,site-name)))
     (meta (@ (property "og:description")
              (content ,description)))
     (meta (@ (property "og:type")
              (content "website")))
     (meta (@ (property "og:url")
              (content ,site-url)))

     (link (@ (rel "stylesheet")
              (type "text/css")
              (href "/style.css")))
     (link (@ (rel "alternate")
              (type "application/rss+xml")
              (href ,rss-path)))
     (link (@ (rel "alternate")
              (type "application/atom+xml")
              (href "/feed.xml"))))
    (body
     ,@body)))

(define (page-template body)
  (base-template
   `((header
      (a (@ (href ,index-path))
         (h1 ,site-title))
      (aside
       (p (em "Louis Jackman's Personal Website")))
      (nav
       (ul
        (li (h2 (a (@ (href ,about-page))
                   "About")))
        (li (h2 (a (@ (href ,contact-page))
                   "Contact")))
        (li (h2 (a (@ (href ,github-page))
                   "Projects")))
        (li (h2 (a (@ (href ,cv-path))
                   "CV / Résumé")))
        (li (h2 (a (@ (href ,posts-page))
                   "Articles"))))))
     (main
      ,body))))

(define (layout site title body)
  (page-template
   body))

(define* (post-template post #:key post-link)
  `(article
    (header
     (h2 ,(post-ref post 'title))
     (time ,(date->string* (post-date post)))
     (ul (@ (class "tags"))
          Tags:
          ,@(map (lambda (tag)
                   `(li ,tag))
                 (post-tags post))))
    ,(post-sxml post)))

(define (post-uri site post)
  (string-append posts-prefix
                 "/"
                 (site-post-slug site post)
                 ".html"))

(define (collection-template site title posts prefix)
  `(ul (@ (class "articles"))
    ,@(map (lambda (post)
             `(li (a (@ (href ,(post-uri site post)))
                     (h2 ,(post-ref post 'title)))
                  (time ,(date->string* (post-date post)))))
           posts)))

(define (volatile-thunk-theme)
  (theme #:name "volatilethunk"
         #:layout layout
         #:post-template post-template
         #:collection-template collection-template))

(define (static-page file-name body)
  (lambda (site posts)
    (serialized-artifact file-name
                         (base-template body)
                         sxml->html)))

(define (index-page)
  (static-page
   index-path
   `((header (a (@ (href ,index-path))
                (h1 ,site-title))
             (aside
              (p (em "Louis Jackman's Personal Website"))))
     (main (@ (class "landing-page"))
           (ul
            (li (h2 (a (@ (href ,about-page))
                       "About"))
                (p "Aside from a Product Security Manager in London, who am I?"))
            (li (h2 (a (@ (href ,contact-page))
                       "Contact"))
                (p "Contact me via LinkedIn, email, et al."))
            (li (h2 (a (@ (href ,github-page))
                       "Projects"))
                (p "See the code."))
            (li (h2 (a (@ (href ,cv-path))
                       "CV / Résumé"))
                (p "See what I've done, aside from the code."))
            (li (h2 (a (@ (href ,posts-page))
                       "Articles"))
                (p "What I've written about what I've done.")))))))

(define (day-or-month->string day-or-month)
  (string-pad (number->string day-or-month)
              2 #\0))

;; Keep old links working from previous website's posts. New posts do not get
;; these redirects.
(define volatile-thunk-redirects

  ;; For old links that match Haunt's slugline generation, redirects can be
  ;; procedurally generated. For links that don't match, specify both source
  ;; and destination paths manually.
  (let ((redirect (lambda (year month day slugline)
                    (list (string-append posts-prefix
                                         "/"
                                         (number->string year)
                                         "/"
                                         (day-or-month->string month)
                                         "/"
                                         (day-or-month->string day)
                                         "/"
                                         slugline
                                         "/post.html")
                          (string-append posts-prefix
                                         "/"
                                         slugline
                                         ".html")))))

    (list (list "/posts/2018/02/12/unix-parallelism-and-concurrency-processes-and-signalling/post.html"
                (string-append posts-prefix
                               "/unix-parallelism-and-concurrency-processes--signalling.html"))
          (list "/posts/2018/03/03/escape-bypassing-language-injection-through-multiple-embedded-languages/post.html"
                (string-append posts-prefix
                               "/escape-bypassing-language-injection-exploiting-multiple-level-language-embedding.html"))

          (redirect 2018 03 24 "asynchronous-apis-are-a-step-backwards-for-non-blocking-code")

          (list "/posts/2018/07/29/time-attacks-why-being-efficient-can-leak-information/post.html"
                (string-append posts-prefix
                               "/timing-attacks-why-being-efficient-can-leak-information.html"))

          (redirect 2018 08 25 "syntax-highlighting-and-remote-code-execution-why-developers-are-an-easy-target")
          (redirect 2018 11 18 "webassembly-a-security-engineers-review")
          (redirect 2018 11 25 "your-ci-pipeline-has-the-skeleton-key-to-your-infrastructure")
          (redirect 2019 01 11 "lambda-syntax-in-mainstream-programming-languages")
          (redirect 2019 02 02 "skipping-expensive-security-checks-with-jit-compilation")
          (redirect 2019 02 10 "to-secure-systems-of-the-future-we-must-rethink-our-notions-of-environment-and-operating-system")
          (redirect 2019 04 18 "the-distinct-niches-of-go--rust")
          (redirect 2019 08 19 "using-single-field-wrapper-types-to-reduce-bugs")
          (redirect 2019 10 01 "a-proposal-for-the-web-improving-security-with-versioned-baseline-defaults")
          (redirect 2019 12 08 "in-defence-of-java")
          (redirect 2020 04 08 "source-portability-vs-platform-portability")
          (redirect 2020 12 06 "creating-standalone-executables-from-lisp-with-quick-startup-times-in-2020")

          (list "/posts/2021/10/09/a-brief-history-of-text-editors-from-vi-and-emacs-to-intellij-and-visual-studio-code/post.html"
                (string-append posts-prefix
                               "/a-brief-history-of-text-editors-from-vi-to-visual-studio-code.html"))
          (list "/posts/2021/10/10/configuring-neovim-with-lua/post.html"
                (string-append posts-prefix
                               "/using-neovim-and-configuring-it-with-lua.html")))))

(site #:title site-title
      #:domain site-domain

      #:default-metadata
      '((author . "Louis Jackman")
        (email  . "ljackman@pm.me"))

      #:readers (list commonmark-reader)

      #:builders (list (index-page)
                       (blog #:theme (volatile-thunk-theme)
                             #:prefix posts-prefix
                             #:collections `(("Articles"
                                              ,posts-page
                                              ,posts/reverse-chronological)))
                       (flat-pages "pages"
                                   #:template (theme-layout (volatile-thunk-theme))
                                   #:prefix (string-append pages-prefix "/"))
                       (atom-feed #:blog-prefix posts-prefix
                                  #:max-entries 20)
                       (atom-feeds-by-tag #:blog-prefix posts-prefix
                                          #:max-entries 20)
                       (rss-feed #:file-name rss-path
                                 #:max-entries 20)
                       (static-directory static-source-path static-dest-path)
                       (redirects volatile-thunk-redirects)))
