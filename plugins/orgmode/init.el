;; Init file to use with the orgmode plugin.

;; Load org-mode
;; Requires org-mode v8.x

;; Uncomment these lines and change the path to your org source to
;; add use it.
(let* ((org-lisp-dir "~/.emacs.d.bk/site-lisp/org-mode/lisp"))
  (when (file-directory-p org-lisp-dir)
      (add-to-list 'load-path org-lisp-dir)
      (require 'org)))

(require 'ox-html)

;;; Custom configuration for the export. ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst org-pygments-language-alist
  '(
    ("asymptote" . "asymptote")
    ("awk" . "awk")
    ("C" . "c")
    ("cpp" . "cpp")
    ("clojure" . "clojure")
    ("css" . "css")
    ("D" . "d")
    ("ditaa" . "image")
    ("emacs-lisp" . "elisp")
    ("F90" . "fortran")
    ("gnuplot" . "gnuplot")
    ("groovy" . "groovy")
    ("haskell" . "haskell")
    ("java" . "java")
    ("js" . "js")
    ("julia" . "julia")
    ("latex" . "latex")
    ("lisp" . "lisp")
    ("makefile" . "makefile")
    ("matlab" . "matlab")
    ("mscgen" . "mscgen")
    ("ocaml" . "ocaml")
    ("octave" . "octave")
    ("perl" . "perl")
    ("picolisp" . "scheme")
    ("python" . "python")
    ("R" . "r")
    ("ruby" . "ruby")
    ("sass" . "sass")
    ("scala" . "scala")
    ("scheme" . "scheme")
    ("sh" . "sh")
    ("sql" . "sql")
    ("sqlite" . "sqlite3")
    ("tcl" . "tcl")
    )
  "Alist between org-babel languages and Pygments lexers.

See: http://orgmode.org/worg/org-contrib/babel/languages.html and
http://pygments.org/docs/lexers/ for adding new languages to the
mapping. ")

;;; Add any custom configuration that you would like to 'conf.el'.
(setq
 org-export-with-toc nil
 org-export-with-section-numbers nil
 org-startup-folded 'showeverything
 org-use-sub-superscripts '{}
 org-export-with-sub-superscripts '{})

;; Load additional configuration from conf.el
(let ((conf (expand-file-name "conf.el" (file-name-directory load-file-name))))
  (if (file-exists-p conf)
      (load-file conf)))

;;; Macros ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Load Nikola macros
(setq nikola-macro-templates
      (with-current-buffer
          (find-file
           (expand-file-name "macros.org" (file-name-directory load-file-name)))
        (org-macro--collect-macros)))


;;; Code highlighting ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Use pygments highlighting for code
(defun pygmentize (lang code)
  "Use Pygments to highlight the given code and return the output"
  (with-temp-buffer
    (insert code)
    (let ((lang (or (cdr (assoc lang org-pygments-language-alist)) "text")))
      (if (string-equal lang "image")
          ;; A crazy hack!! Why src-block have no info?!@!@#
          (let* ((file-name (format "%s.png" (sha1 code)))
                 (output-path (format "../files/images/%s" file-name))
                 (url (format "../images/%s" file-name)))
            (shell-command-on-region
             (point-min) (point-max)
             (format "pygmentize -f png -O font_name=UbuntuMono,line_numbers=False -o %s -l text" output-path))
            (format "<img src=\"%s\" >" url))
        (shell-command-on-region
         (point-min) (point-max)
         (format "pygmentize -f html -O encoding=utf8 -l %s" lang)
         (buffer-name) t)
        (buffer-string)))))

;; Override the html export function to use pygments
(defun org-html-src-block (src-block contents info)
  "Transcode a SRC-BLOCK element from Org to HTML.
CONTENTS holds the contents of the item.  INFO is a plist holding
contextual information."
  (if (org-export-read-attribute :attr_html src-block :textarea)
      (org-html--textarea-block src-block)
    (let ((lang (org-element-property :language src-block))
          (code (car (org-export-unravel-code element))))
      (pygmentize lang code))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Export function used by Nikola.
(defun nikola-html-export (infile)
  "Export the body only of the input file and write it to
specified location."

  (with-current-buffer (find-file infile)
    (org-macro-replace-all nikola-macro-templates)
    (org-html-export-as-html nil nil t t)
    (print (buffer-string))))
