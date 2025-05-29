;;;;
;;;; # VolatileThunk
;;;;
;;;; Louis Jackman's personal website, generated via
;;;; [Haunt](https://dthompson.us/projects/haunt.html). Haunt runs atop the
;;;; [Scheme](https://en.wikipedia.org/wiki/Scheme_(programming_language))
;;;; dialect [GNU Guile](https://www.gnu.org/software/guile/).
;;;;
;;;; Only break from Haunt's defaults to align with path conventions of old
;;;; website, for SEO purposes.
;;;;

(use-modules (haunt artifact)
             (haunt asset)
             (haunt builder assets)
             (haunt builder atom)
             (haunt builder blog)
             (haunt builder rss)
             (haunt html)
             (haunt post)
             (haunt reader)
             (haunt reader commonmark)
             (haunt site))

(define site-name "VolatileThunk")
(define author "Louis Jackman")
(define description "Louis Jackman's Website")
(define site-url "https://volatilethunk.com")

;; Override Haunt's defaults for these cases to retain path-compatibility with
;; previous website.
(define posts-prefix "/posts")
(define pages-prefix "/pages")
(define rss-path "index.xml")
(define static-path ".")
(define cv-path "/louis-jackman-cv.pdf")

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
              (content "louis jackman volatile thunk volatilethunk articles blog cv resume")))
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
              (href "/static/style.css")))
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
      (h1 "VolatileThunk")
      (nav
       (ul
        (li (a (@ (href "/index.html"))
               "Home"))
        (li (a (@ (href "/pages/about.html"))
               "About"))
        (li (a (@ (href "/pages/contact.html"))
               "Contact"))
        (li (a (@ (href "https://github.com/LouisJackman"))
               "Projects"))
        (li (a (@ (href ,cv-path))
               "CV / Resumé"))
        (li (a (@ (href "/posts.html"))
               "Articles")))))
     (main
      ,body))))

(define (layout site title body)
  (page-template
   `(article ,body)))

(define* (post-template post #:key post-link)
  `(article
    (h2 ,(post-ref post 'title))
    ,(post-sxml post)))

(define (post-uri site post)
  (string-append posts-prefix
                 "/"
                 (site-post-slug site post)
                 ".html"))

(define (collection-template site title posts prefix)
  `(ul
    ,@(map (lambda (post)
             `(li (a (@ (href ,(post-uri site post)))
                     ,(post-ref post 'title))))
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
   "/index.html"
   `((header (h1 "VolatileThunk")
             (aside
              (p (em "Louis Jackman's Personal Website"))))
     (main (@ (class "landing-page"))
           (ul
            (li (h2 (a (@ (href "/pages/about.html"))
                       "About"))
                (p "Aside from a Product Security Manager in London, who am I?"))
            (li (h2 (a (@ (href "/contact.html"))
                       "Contact"))
                (p "Contact me via LinkedIn, email, et al."))
            (li (h2 (a (@ (href "https://github.com/LouisJackman"))
                       "Projects"))
                (p "See the code."))
            (li (h2 (a (@ (href ,cv-path))
                       "CV / Resumé"))
                (p "See what I've done, if the code wasn't enough."))
            (li (h2 (a (@ (href "/posts.html"))
                       "Articles"))
                (p "What I've written about what I've done.")))))))

(site #:title "VolatileThunk"
      #:domain "volatilethunk.com"

      #:default-metadata
      '((author . "Louis Jackman")
        (email  . "ljackman@protonmail.com"))

      #:readers (list commonmark-reader)

      #:builders (list (index-page)
                       (blog #:theme (volatile-thunk-theme)
                             #:prefix posts-prefix
                             #:collections `(("Articles"
                                              "posts.html"
                                              ,posts/reverse-chronological)))
                       (index-page)
                       (atom-feed #:blog-prefix posts-prefix)
                       (atom-feeds-by-tag #:blog-prefix posts-prefix)
                       (rss-feed #:file-name rss-path)
                       (static-directory static-path)))
