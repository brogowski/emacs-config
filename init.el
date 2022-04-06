;;Transparency
(defun on-after-init ()
  (unless (display-graphic-p (selected-frame))
    (set-face-background 'default "unspecified-bg" (selected-frame))))

(add-hook 'window-setup-hook 'on-after-init)
;;;;
;; Packages
;;;;

;; Define package repositories
(require 'package)
(add-to-list 'package-archives
             '("tromey" . "http://tromey.com/elpa/") t)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives
             '("melpa-stable" . "http://stable.melpa.org/packages/") t)

(add-to-list 'package-pinned-packages '(cider . "melpa-stable") t)
(add-to-list 'package-pinned-packages '(magit . "melpa-stable") t)


;; Load and activate emacs packages. Do this first so that the
;; packages are loaded before you start trying to modify them.
;; This also sets the load path.
(package-initialize)

;; Download the ELPA archive description if needed.
;; This informs Emacs about the latest versions of all packages, and
;; makes them available for download.
(when (not package-archive-contents)
  (package-refresh-contents))
(require 'use-package)

(setq use-package-always-ensure t)
;; Define he following variables to remove the compile-log warnings
;; when defining ido-ubiquitous
;; (defvar ido-cur-item nil)
;; (defvar ido-default-item nil)
;; (defvar ido-cur-list nil)
;; (defvar predicate nil)
;; (defvar inherit-input-method nil)

;; The packages you want installed. You can also install these
;; manually with M-x package-install
;; Add in your own as you wish:
(defvar my-packages
  '(;; makes handling lisp expressions much, much easier
    ;; Cheatsheet: http://www.emacswiki.org/emacs/PareditCheatsheet
    paredit

    ;; key bindings and code colorization for Clojure
    ;; https://github.com/clojure-emacs/clojure-mode
    clojure-mode


    ;; extra syntax highlighting for clojure
    clojure-mode-extra-font-locking

    ;; integration with a Clojure REPL
    ;; https://github.com/clojure-emacs/cider
    cider

    ;; allow ido usage in as many contexts as possible. see
    ;; customizations/navigation.el line 23 for a description
    ;; of ido
    ido-completing-read+

    ;; project navigation
    projectile

    ;; colorful parenthesis matching
    rainbow-delimiters

    ;; edit html tags like sexps
    tagedit

    ;; git integration
    magit))

(use-package org
  :init
  (setq org-startup-indented t)
  (setq org-agenda-files '("~/org"))
  (setq org-todo-keywords
        '((sequence "TODO(t)" "DOING(d)" "|" "COMPLETE(c)"))))

;; Try to center org files content and wrap lines by words
(defun my/org-mode-visual-fill ()
  (setq visual-fill-column-width 100
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1)
  (toggle-truncate-lines)
  (visual-line-mode))

(use-package visual-fill-column
  :hook (org-mode . my/org-mode-visual-fill))

;; Fix C-return not working on Windows Terminal
(define-key org-mode-map (kbd "C-j") 'org-insert-heading-respect-content)

(define-key org-mode-map (kbd "C-c l") 'my/org-link-copy-at-point)

;; Copy URL from org link at cursor
;; Additonally copy it into wsl clipboard
(defun my/org-link-copy-at-point ()
  (interactive)
  (save-excursion
    (let* ((ol-regex "\\[\\[.*?:.*?\\]\\(\\[.*?\\]\\)?\\]")
       (beg (re-search-backward "\\[\\["))
       (end (re-search-forward ol-regex))
       (link-string (buffer-substring-no-properties (match-beginning 0) (match-end 0)))
       (link-url (my/get-url-from-org-link link-string))) 
      (kill-new link-url)
      (wsl-copy link-url)
      (message "Org link %s is copied." link-url))))

(defun my/get-url-from-org-link (text)
  (progn 
    (string-match org-bracket-link-regexp text)
    (substring text (match-beginning 1) (match-end 1))))

(defun wsl-copy (text)
  (interactive "r")
  (shell-command (concat "echo " text " | " "clip.exe"))
  (deactivate-mark))

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory "~/org/notes")
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)         
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture))
  :config
  (org-roam-db-autosync-mode))

;; Dired settings
(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :custom ((dired-listing-switches "-agho --group-directories-first")))

(use-package dired-hide-dotfiles
  :hook (dired-mode . dired-hide-dotfiles-mode)
  :config (define-key dired-mode-map (kbd ".") 'dired-hide-dotfiles-mode))

;; On OS X, an Emacs instance started from the graphical user
;; interface will have a different environment than a shell in a
;; terminal window, because OS X does not run a shell during the
;; login. Obviously this will lead to unexpected results when
;; calling external utilities like make from Emacs.
;; This library works around this problem by copying important
;; environment variables from the user's shell.
;; https://github.com/purcell/exec-path-from-shell
(if (eq system-type 'darwin)
    (add-to-list 'my-packages 'exec-path-from-shell))

(dolist (p my-packages)
  (when (not (package-installed-p p))
    (package-install p)))


;;;;
;; Customization
;;;;

;; Add a directory to our load path so that when you `load` things
;; below, Emacs knows where to look for the corresponding file.
(add-to-list 'load-path "~/.emacs.d/customizations")

;; Sets up exec-path-from-shell so that Emacs will use the correct
;; environment variables
(load "shell-integration.el")

;; These customizations make it easier for you to navigate files,
;; switch buffers, and choose options from the minibuffer.
(load "navigation.el")

;; These customizations change the way emacs looks and disable/enable
;; some user interface elements
(load "ui.el")

;; These customizations make editing a bit nicer.
(load "editing.el")

;; Hard-to-categorize customizations
(load "misc.el")

;; For editing lisps
(load "elisp-editing.el")

;; Langauage-specific
(load "setup-clojure.el")
(load "setup-js.el")
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(cljr-favor-private-functions nil)
 '(cljr-use-multiple-cursors nil)
 '(cljr-warn-on-eval nil)
 '(coffee-tab-width 2)
 '(custom-safe-themes
   '("47db50ff66e35d3a440485357fb6acb767c100e135ccdf459060407f8baea7b2" "da186cce19b5aed3f6a2316845583dbee76aea9255ea0da857d1c058ff003546" "1d5e33500bc9548f800f9e248b57d1b2a9ecde79cb40c0b1398dec51ee820daf" "a6e620c9decbea9cac46ea47541b31b3e20804a4646ca6da4cce105ee03e8d0e" "1704976a1797342a1b4ea7a75bdbb3be1569f4619134341bd5a4c1cfb16abad4" "835868dcd17131ba8b9619d14c67c127aa18b90a82438c8613586331129dda63" "7f1263c969f04a8e58f9441f4ba4d7fb1302243355cb9faecb55aec878a06ee9" "9e54a6ac0051987b4296e9276eecc5dfb67fdcd620191ee553f40a9b6d943e78" "1157a4055504672be1df1232bed784ba575c60ab44d8e6c7b3800ae76b42f8bd" "cf08ae4c26cacce2eebff39d129ea0a21c9d7bf70ea9b945588c1c66392578d1" "5ee12d8250b0952deefc88814cf0672327d7ee70b16344372db9460e9a0e3ffc" "52588047a0fe3727e3cd8a90e76d7f078c9bd62c0b246324e557dfa5112e0d0c" default))
 '(package-selected-packages
   '(org-roam dired-hide-dotfiles all-the-icons-dired visual-fill-column org doom-themes which-key doom-modeline marginalia orderless vertigo vertico use-package clj-refactor tagedit rainbow-delimiters projectile ido-completing-read+ clojure-mode-extra-font-locking clojure-mode paredit exec-path-from-shell)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(vertico-current ((t (:background "#3a3f5a")))))
