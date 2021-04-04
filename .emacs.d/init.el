(add-hook 'emacs-startup-hook
          (lambda ()
            (message "*** Emacs loaded in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time
                              (time-subtract after-init-time before-init-time)))
                     gcs-done)))

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
      (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(eval-when-compile (require 'use-package))
 ;; (setq use-package-verbose t)

(setq gc-cons-threshold 80000000)
(setq read-process-output-max (* 1024 1024))

(add-hook 'emacs-startup-hook
          (lambda ()
            (if (boundp 'after-focus-change-function)
                (add-function :after after-focus-change-function
                              (lambda ()
                                (unless (frame-focus-state)
                                  (garbage-collect))))
              (add-hook 'after-focus-change-function 'garbage-collect))))

(setq my/lowpower (string= (system-name) "pntk"))

(use-package conda
  :straight t
  :config
  (setq conda-anaconda-home (expand-file-name "~/Programs/miniconda3/"))
  (setq conda-env-home-directory (expand-file-name "~/Programs/miniconda3/"))
  (setq conda-env-subdirectory "envs"))

(if (not (getenv "CONDA_DEFAULT_ENV"))
  (conda-env-activate "base"))

(setenv "IS_EMACS" "true")

(setq custom-file (concat user-emacs-directory "custom.el"))
(load custom-file 'noerror)

(use-package general
  :straight t
  :config
  (general-evil-setup))

(use-package which-key
  :config
  (setq which-key-idle-delay (if my/lowpower 1 0.3))
  (setq which-key-popup-type 'frame)
  (which-key-mode)
  (which-key-setup-side-window-bottom)
  (set-face-attribute 'which-key-local-map-description-face nil
                      :weight 'bold)
  :straight t)

(use-package evil
  :straight t
  :init
  (setq evil-want-integration t)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1)
  (setq evil-search-module 'evil-search)
  (setq evil-split-window-below t)
  (setq evil-vsplit-window-right t)
  ;; (setq evil-respect-visual-line-mode t)
  (evil-set-undo-system 'undo-tree)
  ;; (add-to-list 'evil-emacs-state-modes 'dired-mode)
  )

(use-package evil-surround
  :straight t
  :after evil
  :config
  (global-evil-surround-mode 1))

(use-package evil-commentary
  :straight t
  :after evil
  :config
  (evil-commentary-mode))

(use-package evil-quickscope
  :straight t
  :after evil
  :config
  :hook ((prog-mode . turn-on-evil-quickscope-mode)
         (LaTeX-mode . turn-on-evil-quickscope-mode)))

(use-package evil-collection
  :straight t
  :after evil
  :config
  (evil-collection-init
    '(eww
      dired
      company
      vterm
      flycheck
      profiler
      cider
      explain-pause-mode
      notmuch
      custom
      xref
      eshell
      helpful
      compile
      comint
      magit)))

(defun minibuffer-keyboard-quit ()
  "Abort recursive edit.
In Delete Selection mode, if the mark is active, just deactivate it;
then it takes a second \\[keyboard-quit] to abort the minibuffer."
  (interactive)
  (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark  t)
    (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
    (abort-recursive-edit)))

(general-define-key
 :keymaps '(normal visual global)
 [escape] 'keyboard-quit)

(general-define-key
 :keymaps '(minibuffer-local-map
            minibuffer-local-ns-map
            minibuffer-local-completion-map
            minibuffer-local-must-match-map
            minibuffer-local-isearch-map)
 [escape] 'minibuffer-keyboard-quit)

(general-def :states '(normal insert visual)
  "<home>" 'beginning-of-line
  "<end>" 'end-of-line)

(general-create-definer my-leader-def
  :keymaps 'override
  :prefix "SPC"
  :states '(normal motion emacs))


(general-def :states '(normal motion emacs) "SPC" nil)

(my-leader-def "?" 'which-key-show-top-level)
(my-leader-def "E" 'eval-expression)

(general-def
  :keymaps 'universal-argument-map
  "M-u" 'universal-argument-more)
(general-def
  :keymaps 'override
  :states '(normal motion emacs insert visual)
  "M-u" 'universal-argument)

(my-leader-def "Ps" 'profiler-start)
(my-leader-def "Pe" 'profiler-stop)
(my-leader-def "Pp" 'profiler-report)

(general-define-key
  :keymaps 'override
  "C-<right>" 'evil-window-right
  "C-<left>" 'evil-window-left
  "C-<up>" 'evil-window-up
  "C-<down>" 'evil-window-down
  "C-h" 'evil-window-left
  "C-l" 'evil-window-right
  "C-k" 'evil-window-up
  "C-j" 'evil-window-down
  "C-x h" 'previous-buffer
  "C-x l" 'next-buffer)

(winner-mode 1)
(define-key evil-window-map (kbd "u") 'winner-undo)
(define-key evil-window-map (kbd "U") 'winner-redo)

(general-nmap
  "gD" 'xref-find-definitions-other-window
  "gr" 'xref-find-references)
  
(my-leader-def
  "fx" 'xref-find-apropos)

(general-nmap "TAB" 'evil-toggle-fold)
(general-nmap :keymaps 'hs-minor-mode-map "ze" 'hs-hide-level)

(defun my/zoom-in ()
  "Increase font size by 10 points"
  (interactive)
  (set-face-attribute 'default nil
                      :height
                      (+ (face-attribute 'default :height)
                         10)))

(defun my/zoom-out ()
  "Decrease font size by 10 points"
  (interactive)
  (set-face-attribute 'default nil
                      :height
                      (- (face-attribute 'default :height)
                         10)))

;; change font size, interactively
(global-set-key (kbd "C-+") 'my/zoom-in)
(global-set-key (kbd "C-=") 'my/zoom-out)

(use-package visual-fill-column
  :straight t
  :config
  (add-hook 'visual-fill-column-mode-hook
            (lambda () (setq visual-fill-column-center-text t))))

(use-package smartparens
  :straight t)

(use-package aggressive-indent
  :straight t)

(setq tab-always-indent nil)

(setq default-tab-width 4)
(setq tab-width 4)
(setq evil-indent-convert-tabs nil)
(setq indent-tabs-mode nil)
(setq tab-width 4)
(setq evil-shift-round nil)

(setq scroll-conservatively scroll-margin)
(setq scroll-step 1)
(setq scroll-preserve-screen-position t)
(setq scroll-error-top-bottom t)
(setq mouse-wheel-progressive-speed nil)
(setq mouse-wheel-inhibit-click-time nil)

(setq select-enable-clipboard t)
(setq mouse-yank-at-point t)

(setq backup-inhibited t)
(setq auto-save-default nil)

(use-package undo-tree
  :straight t
  :config
  (global-undo-tree-mode)
  (setq undo-tree-visualizer-diff t)
  (setq undo-tree-visualizer-timestamps t)

  (my-leader-def "u" 'undo-tree-visualize)
  (fset 'undo-auto-amalgamate 'ignore)
  (setq undo-limit 6710886400)
  (setq undo-strong-limit 100663296)
  (setq undo-outer-limit 1006632960))

(use-package helpful
  :straight t
  :commands (helpful-callable
             helpful-variable
             helpful-key
             helpful-macro
             helpful-function
             helpful-command))

(my-leader-def
  :infix "h"
  "RET" 'view-order-manuals
  "." 'display-local-help
  "?" 'help-for-help
  "C" 'describe-coding-system
  "F" 'Info-goto-emacs-command-node
  "I" 'describe-input-method
  "K" 'Info-goto-emacs-key-command-node
  "L" 'describe-language-environment
  "P" 'describe-package
  "S" 'info-lookup-symbol
  "a" 'helm-apropos
  "b" 'describe-bindings
  "c" 'describe-key-briefly
  "d" 'apropos-documentation
  "e" 'view-echo-area-messages
  "f" 'helpful-function
  "g" 'describe-gnu-project
  "h" 'view-hello-file
  "i" 'info
  "k" 'helpful-key
  "l" 'view-lossage
  "m" 'describe-mode
  "n" 'view-emacs-news
  "o" 'describe-symbol
  "p" 'finder-by-keyword
  "q" 'help-quit
  "r" 'info-emacs-manual
  "s" 'describe-syntax
  "t" 'help-with-tutorial
  "v" 'helpful-variable
  "w" 'where-is
  "<f1>" 'help-for-help
  "C-\\" 'describe-input-method
  "C-a" 'about-emacs
  "C-c" 'describe-copying
  "C-d" 'view-emacs-debugging
  "C-e" 'view-external-packages
  "C-f" 'view-emacs-FAQ
  "C-h" 'help-for-help
  "C-n" 'view-emacs-news
  "C-o" 'describe-distribution
  "C-p" 'view-emacs-problems
  "C-s" 'search-forward-help-for-help
  "C-t" 'view-emacs-todo
  "C-w" 'describe-no-warranty)

(use-package ivy
  :straight t
  :config
  (setq ivy-use-virtual-buffers t)
  (ivy-mode))

(use-package counsel
  :straight t
  :after ivy
  :config
  (counsel-mode))
  
(use-package swiper
  :defer t
  :straight t)

(use-package ivy-rich
  :straight t
  :after ivy
  :config
  (ivy-rich-mode 1)
  (setcdr (assq t ivy-format-functions-alist) #'ivy-format-function-line))

(my-leader-def
  :infix "f"
  "b" 'ivy-switch-buffer
  "e" 'conda-env-activate
  "f" 'project-find-file
  "c" 'counsel-yank-pop
  "a" 'counsel-rg
  "A" 'counsel-ag)

(general-imap
  "C-y" 'counsel-yank-pop)

(my-leader-def "SPC" 'ivy-resume)
(my-leader-def "s" 'swiper-isearch
  "S" 'swiper-all)

(general-define-key
 :keymaps '(ivy-minibuffer-map swiper-map)
 "M-j" 'ivy-next-line
 "M-k" 'ivy-previous-line
 "<C-return>" 'ivy-call
 "M-RET" 'ivy-immediate-done
 [escape] 'minibuffer-keyboard-quit)

(use-package treemacs
  :straight t
  :commands (treemacs treemacs-switch-workspace treemacs-edit-workspace)
  :config
  (setq treemacs-follow-mode nil)
  (setq treemacs-follow-after-init nil)
  (setq treemacs-space-between-root-nodes nil)
  (treemacs-git-mode 'extended)
  (with-eval-after-load 'treemacs
    (add-to-list 'treemacs-pre-file-insert-predicates #'treemacs-is-file-git-ignored?)))

(use-package treemacs-evil
  :after (treemacs evil)
  :straight t)

(use-package treemacs-magit
  :after (treemacs magit)
  :straight t)
  
(general-define-key
 :keymaps '(normal override global)
 "C-n" 'treemacs)

(general-define-key
 :keymaps '(treemacs-mode-map) [mouse-1] #'treemacs-single-click-expand-action)
 
(my-leader-def
  "tw" 'treemacs-switch-workspace
  "te" 'treemacs-edit-workspaces)

(use-package projectile
  :straight t
  :config
  (projectile-mode +1)
  (setq projectile-project-search-path '("~/Code" "~/Documents")))

(use-package counsel-projectile
  :after (counsel projectile)
  :straight t)

(use-package treemacs-projectile
  :after (treemacs projectile)
  :straight t)

(my-leader-def
  "p" 'projectile-command-map)

(general-nmap "C-p" 'counsel-projectile-find-file)

(use-package company
  :straight t
  :config
  (global-company-mode)
  (setq company-idle-delay (if my/lowpower 0.5 0.125))
  (setq company-dabbrev-downcase nil)
  (setq company-show-numbers t))

(general-imap "C-SPC" 'company-complete)

(use-package company-box
  :straight t
  :if (not my/lowpower)
  :after (company)
  :hook (company-mode . company-box-mode))

(use-package magit
  :straight t
  :commands (magit-status magit-file-dispatch)
  :config
  (setq magit-blame-styles
        '((margin
           (margin-format    . ("%a %A %s"))
           (margin-width     . 42)
           (margin-face      . magit-blame-margin)
           (margin-body-face . (magit-blame-dimmed)))
          (headings
           (heading-format   . "%-20a %C %s\n"))
          (highlight
           (highlight-face   . magit-blame-highlight))
          (lines
           (show-lines       . t)
           (show-message     . t)))
        ))

(use-package git-gutter
  :straight t
  :config
  (global-git-gutter-mode +1))

(my-leader-def
  "m" 'magit
  "M" 'magit-file-dispatch)

(use-package editorconfig
  :straight t
  :config
  (editorconfig-mode 1))

(use-package yasnippet
  :straight t
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :straight t)
  
(general-imap "M-TAB" 'company-yasnippet)

(use-package wakatime-mode
  :straight t
  :config
  (global-wakatime-mode))

(use-package request
  :straight t)
  
(use-package activity-watch-mode
  :straight t
  :config
  (global-activity-watch-mode))

(use-package dired
  :ensure nil
  :custom ((dired-listing-switches "-alh --group-directories-first"))
  :commands (dired)
  :config
  (setq dired-dwim-target t)
  (setq wdired-allow-to-change-permissions t)
  (setq wdired-create-parent-directories t)
  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (add-hook 'dired-mode-hook
    (lambda ()
      (setq truncate-lines t)
      (visual-line-mode nil)))
  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-single-up-directory
    "l" 'dired-single-buffer
    "h" 'dired-single-up-directory
    "l" 'dired-single-buffer
    "=" 'dired-narrow
    "-" 'dired-create-empty-file
    (kbd "<left>") 'dired-single-up-directory
    (kbd "<right>") 'dired-single-buffer)
  (general-define-key
    :keymaps 'dired-mode-map
    [remap dired-find-file] 'dired-single-buffer
    [remap dired-mouse-find-file-other-window] 'dired-single-buffer-mouse
    [remap dired-up-directory] 'dired-single-up-directory
    "M-<return>" 'dired-open-xdg))

(my-leader-def "ad" 'dired)

(use-package dired+
  :straight t
  :after dired
  :init
  (setq diredp-hide-details-initially-flag nil))

(use-package dired-single
  :after dired
  :straight t)

(use-package all-the-icons-dired
  :straight t
  :if (not my/lowpower)
  :after dired
  :config
  (add-hook 'dired-mode-hook 'all-the-icons-dired-mode)
  (advice-add 'dired-add-entry :around #'all-the-icons-dired--refresh-advice)
  (advice-add 'dired-remove-entry :around #'all-the-icons-dired--refresh-advice))

(use-package dired-open
  :after dired
  :straight t)

(use-package dired-narrow
  :after dired
  :straight t
  :config
  (general-define-key
    :keymaps 'dired-narrow-map
    [escape] 'keyboard-quit))

(use-package vterm
  :straight t
  :commands (vterm vterm-other-window)
  :config
  (setq vterm-kill-buffer-on-exit t)
  
  (add-hook 'vterm-mode-hook
            (lambda ()
              (setq-local global-display-line-numbers-mode nil)
              (display-line-numbers-mode 0)))
  
  (general-define-key
   :keymaps 'vterm-mode-map
   "M-q" 'vterm-send-escape
   
   "C-h" 'evil-window-left
   "C-l" 'evil-window-right
   "C-k" 'evil-window-up
   "C-j" 'evil-window-down
   
   "C-<right>" 'evil-window-right
   "C-<left>" 'evil-window-left
   "C-<up>" 'evil-window-up
   "C-<down>" 'evil-window-down
   
   "M-<left>" 'vterm-send-left
   "M-<right>" 'vterm-send-right
   "M-<up>" 'vterm-send-up
   "M-<down>" 'vterm-send-down)
  
  (general-imap
    :keymaps 'vterm-mode-map
    "C-r" 'vterm-send-C-r
    "C-k" 'vterm-send-C-k
    "C-j" 'vterm-send-C-j
    "M-l" 'vterm-send-right
    "M-h" 'vterm-send-left))

(general-nmap "~" 'vterm)

(add-to-list 'display-buffer-alist
             `(,"vterm-subterminal.*"
               (display-buffer-reuse-window
                display-buffer-in-side-window)
               (side . bottom)
               (reusable-frames . visible)
               (window-height . 0.33)))

(defun my/toggle-vterm-subteminal ()
  "Toogle subteminal."
  (interactive)
  (let
      ((vterm-window
        (seq-find
         (lambda (window)
           (string-match
            "vterm-subterminal.*"
            (buffer-name (window-buffer window))))
         (window-list))))
    (if vterm-window
        (if (eq (get-buffer-window (current-buffer)) vterm-window)
            (kill-buffer (current-buffer))
          (select-window vterm-window))
      (vterm-other-window "vterm-subterminal"))))

(general-nmap "`" 'my/toggle-vterm-subteminal)

(defun my/configure-eshell ()
  (add-hook 'eshell-pre-command-hook 'eshell-save-some-history)
  (add-to-list 'eshell-output-filter-functions 'eshell-truncate-buffer)
  (setq eshell-history-size 10000)
  (setq eshell-hist-ingnoredups t)
  (setq eshell-buffer-maximum-lines 10000)
  
  (evil-define-key '(normal insert visual) eshell-mode-map (kbd "<home>") 'eshell-bol)
  (evil-define-key '(normal insert visual) eshell-mode-map (kbd "C-r") 'counsel-esh-history)
  (evil-collection-define-key 'normal 'eshell-mode-map
    (kbd "C-h") 'evil-window-left
    (kbd "C-l") 'evil-window-right
    (kbd "C-k") 'evil-window-up
    (kbd "C-j") 'evil-window-down))

(use-package eshell
  :ensure nil
  :after evil-collection
  :commands (eshell)
  :config
  (add-hook 'eshell-first-time-mode-hook 'my/configure-eshell 90)
  (setq eshell-banner-message ""))

(use-package aweshell
  :straight (:repo "manateelazycat/aweshell" :host github)
  :after eshell
  :config
  (setq eshell-highlight-prompt nil)
  (setq eshell-prompt-function 'epe-theme-pipeline))
  
;; (general-nmap "`" 'aweshell-dedicated-toggle)
;; (general-nmap "~" 'eshell)

(use-package org
  :straight (:type built-in))

(setq org-directory (expand-file-name "~/Documents/org-mode"))
(setq org-default-notes-file (concat org-directory "/notes.org"))

(setq org-startup-indented t)
(setq org-return-follows-link t)
(add-hook 'org-mode-hook (lambda () (rainbow-delimiters-mode 0)))

(require 'org-crypt)
(org-crypt-use-before-save-magic)
(setq org-tags-exclude-from-inheritance (quote ("crypt")))
(setq org-crypt-key nil)

(use-package evil-org
  :straight t
  :after (org evil-collection)
  :config
  (add-hook 'org-mode-hook 'evil-org-mode)
  (add-hook 'org-mode-hook #'smartparens-mode)
  (add-hook 'evil-org-mode-hook
            (lambda ()
              (evil-org-set-key-theme '(navigation insert textobjects additional calendar todo))))
  (add-to-list 'evil-emacs-state-modes 'org-agenda-mode)
  (require 'evil-org-agenda)
  (add-hook 'org-agenda-mode-hook
          (lambda ()
            (visual-line-mode -1)
            (toggle-truncate-lines 1)
            (display-line-numbers-mode 0)))
  (evil-org-agenda-set-keys))

(use-package jupyter
  :straight t)
  
(my-leader-def "ar" 'jupyter-run-repl)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (python . t)
   ;; (typescript .t)
   (shell . t)
   (jupyter . t)))

(add-hook 'org-babel-after-execute-hook 'org-redisplay-inline-images)

(org-babel-jupyter-override-src-block "python")

(add-hook 'org-src-mode-hook
          (lambda ()
            (hs-minor-mode 0)
            (highlight-indent-guides-mode 0)))

(use-package ob-async
  :straight t
  :after (org)
  :config
  (setq ob-async-no-async-languages-alist '("python" "jupyter-python")))

(use-package org-latex-impatient
  :straight (:repo "yangsheng6810/org-latex-impatient"
                   :branch "master"
                   :host github)
  :hook (org-mode . org-latex-impatient-mode)
  :init
  (setq org-latex-impatient-tex2svg-bin
        "/home/pavel/Programs/miniconda3/lib/node_modules/mathjax-node-cli/bin/tex2svg")
  (setq org-latex-impatient-scale 2)
  (setq org-latex-impatient-delay 1)
  (setq org-latex-impatient-border-color "#ffffff"))

(use-package org-superstar
  :straight t
  :after (org)
  :config
  (add-hook 'org-mode-hook (lambda () (org-superstar-mode 1))))

(if (not my/lowpower)
    (setq org-agenda-category-icon-alist
          `(
            ("work" ,(list (all-the-icons-faicon "cog")) nil nil :ascent center)
            ("lesson" ,(list (all-the-icons-faicon "book")) nil nil :ascent center)
            ("education" ,(list (all-the-icons-material "build")) nil nil :ascent center)
            ("meeting" ,(list (all-the-icons-material "chat")) nil nil :ascent center)
            ("music" ,(list (all-the-icons-faicon "music")) nil nil :ascent center)
            ("misc" ,(list (all-the-icons-material "archive")) nil nil :ascent center)
            ("event" ,(list (all-the-icons-octicon "clock")) nil nil :ascent center))))

(use-package ox-hugo
  :straight t
  :after ox)

(general-define-key
 :keymaps 'org-mode-map
 "C-c d" 'org-decrypt-entry
 "C-c e" 'org-encrypt-entry
 "M-p" 'org-latex-preview)

(general-define-key
 :keymaps 'org-mode-map
 :states '(normal emacs)
 "L" 'org-shiftright
 "H" 'org-shiftleft
 "S-<next>" 'org-babel-next-src-block
 "S-<prior>" 'org-babel-previous-src-block)

(general-define-key
 :keymaps 'org-agenda-mode-map
 "M-]" 'org-agenda-later
 "M-[" 'org-agenda-earlier)

;; (general-imap :keymaps 'org-mode-map "RET" 'evil-org-return)
(general-nmap :keymaps 'org-mode-map "RET" 'org-ctrl-c-ctrl-c)

(my-leader-def
  "aa" 'org-agenda
  "ao" 'org-switchb)

(defun my/org-link-copy (&optional arg)
  "Extract URL from org-mode link and add it to kill ring."
  (interactive "P")
  (let* ((link (org-element-lineage (org-element-context) '(link) t))
          (type (org-element-property :type link))
          (url (org-element-property :path link))
          (url (concat type ":" url)))
    (kill-new url)
    (message (concat "Copied URL: " url))))
    
(general-nmap :keymaps 'org-mode-map
    "C-x C-l" 'my/org-link-copy)

(use-package hide-mode-line
  :straight t)

(use-package org-present
  :straight (:host github :repo "rlister/org-present")
  :commands (org-present)
  :config
  (general-define-key
   :keymaps 'org-present-mode-keymap
   "<next>" 'org-present-next
   "<prior>" 'org-present-prev)
  (add-hook 'org-present-mode-hook
            (lambda ()
              (org-present-big)
              (org-display-inline-images)
              (org-present-hide-cursor)
              (org-present-read-only)
              (display-line-numbers-mode 0)
              (hide-mode-line-mode +1)
              (tab-bar-mode 0)))
  (add-hook 'org-present-mode-quit-hook
            (lambda ()
              (org-present-small)
              (org-remove-inline-images)
              (org-present-show-cursor)
              (org-present-read-write)
              (display-line-numbers-mode 1)
              (hide-mode-line-mode 0)
              (tab-bar-mode 1))))

(use-package org-make-toc
  :after (org)
  :straight t)

(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; (set-frame-parameter (selected-frame) 'alpha '(90 . 90))
;; (add-to-list 'default-frame-alist '(alpha . (90 . 90)))

;; (global-prettify-symbols-mode)

(setq inhibit-startup-screen t)

(setq visible-bell 0)

(defalias 'yes-or-no-p 'y-or-n-p)

(setq make-pointer-invisible t)

(set-frame-font "JetBrainsMono Nerd Font 10" nil t)

(global-display-line-numbers-mode 1)
(line-number-mode nil)
(setq display-line-numbers-type 'visual)
(column-number-mode)

(show-paren-mode 1)

(setq word-wrap 1)
(global-visual-line-mode t)

(global-hl-line-mode 1)

(setq frame-title-format
      '(""
        "emacs"
        (:eval
         (let ((project-name (projectile-project-name)))
           (if (not (string= "-" project-name))
               (format ":%s@%s" project-name (system-name))
             (format "@%s" (system-name)))))))

(general-define-key
 :keymaps 'override
 :states '(normal emacs)
 "gt" 'tab-bar-switch-to-next-tab
 "gT" 'tab-bar-switch-to-prev-tab
 "gn" 'tab-bar-new-tab)
 
(setq tab-bar-show 1)
(setq tab-bar-tab-hints t)
(setq tab-bar-tab-name-function 'tab-bar-tab-name-current-with-count)

;; Tabs
(general-nmap "gn" 'tab-new)
(general-nmap "gN" 'tab-close)

(setq my/project-title-separators "[-_ ]")

(defun my/shorten-project-name-elem (elem crop)
  (if (string-match "^\\[.*\\]$" elem)
      (concat "["
              (my/shorten-project-name-elem (substring elem 1 (- (length elem) 1)) crop)
              "]")
    (let ((prefix (car (s-match my/project-title-separators elem))))
      (let ((rest
             (substring
              (if prefix
                  (substring elem (length prefix))
                elem)
              0 (if crop 1 nil))))
        (concat prefix rest)))))

(defun my/shorten-project-name (project-name)
  (let ((elems (s-slice-at my/project-title-separators project-name)))
    (concat
     (apply
      #'concat
      (cl-mapcar (lambda (elem) (my/shorten-project-name-elem elem t)) (butlast elems)))
     (my/shorten-project-name-elem (car (last elems)) nil))))

(defun my/tab-bar-name-function ()
  (let ((project-name (projectile-project-name)))
    (if (string= "-" project-name)
        (tab-bar-tab-name-current-with-count)
      (concat "[" (my/shorten-project-name project-name) "] " (tab-bar-tab-name-current-with-count)))))

(setq tab-bar-tab-name-function #'my/tab-bar-name-function)

(use-package doom-modeline
  :straight t
  :init
  (setq doom-modeline-env-enable-python nil)
  (setq doom-modeline-env-enable-go nil)
  :config
  (doom-modeline-mode 1)
  (setq doom-modeline-minor-modes nil)
  (setq doom-modeline-buffer-state-icon nil))

(use-package emojify
  :straight t
  :if (not my/lowpower)
  :hook (after-init . global-emojify-mode))

(use-package ligature
  :straight (:host github :repo "mickeynp/ligature.el")
  :config
  (ligature-set-ligatures
   '(
     typescript-mode
     js2-mode
     vue-mode
     svelte-mode
     scss-mode
     php-mode
     python-mode
     js-mode
     markdown-mode
     clojure-mode
     go-mode
     sh-mode
     haskell-mode)
   '("--" "---" "==" "===" "!=" "!==" "=!=" "=:=" "=/=" "<="
     ">=" "&&" "&&&" "&=" "++" "+++" "***" ";;" "!!" "??"
     "?:" "?." "?=" "<:" ":<" ":>" ">:" "<>" "<<<" ">>>"
     "<<" ">>" "||" "-|" "_|_" "|-" "||-" "|=" "||=" "##"
     "###" "####" "#{" "#[" "]#" "#(" "#?" "#_" "#_(" "#:"
     "#!" "#=" "^=" "<$>" "<$" "$>" "<+>" "<+" "+>" "<*>"
     "<*" "*>" "</" "</>" "/>" "<!--" "<#--" "-->" "->" "->>"
     "<<-" "<-" "<=<" "=<<" "<<=" "<==" "<=>" "<==>" "==>" "=>"
     "=>>" ">=>" ">>=" ">>-" ">-" ">--" "-<" "-<<" ">->" "<-<"
     "<-|" "<=|" "|=>" "|->" "<->" "<~~" "<~" "<~>" "~~" "~~>"
     "~>" "~-" "-~" "~@" "[||]" "|]" "[|" "|}" "{|" "[<"
     ">]" "|>" "<|" "||>" "<||" "|||>" "<|||" "<|>" "..." ".."
     ".=" ".-" "..<" ".?" "::" ":::" ":=" "::=" ":?" ":?>"
     "//" "///" "/*" "*/" "/=" "//=" "/==" "@_" "__"))
  (global-ligature-mode t))

(use-package all-the-icons
  :straight t)

(use-package auto-dim-other-buffers
  :straight t
  :if (display-graphic-p)
  :config
  (set-face-attribute 'auto-dim-other-buffers-face nil
                      :background "#212533")
  (auto-dim-other-buffers-mode t))

(use-package doom-themes
  :straight t
  :config
  (setq doom-themes-enable-bold t   
        doom-themes-enable-italic t)
  (load-theme 'doom-palenight t)
  (doom-themes-visual-bell-config)
  (setq doom-themes-treemacs-theme "doom-colors")
  (doom-themes-treemacs-config))

(use-package highlight-indent-guides
  :straight t
  :if (not my/lowpower)
  :hook (
         (prog-mode . highlight-indent-guides-mode)
         (vue-mode . highlight-indent-guides-mode)
         (LaTeX-mode . highlight-indent-guides-mode))
  :config
  (setq highlight-indent-guides-method 'bitmap)
  (setq highlight-indent-guides-bitmap-function 'highlight-indent-guides--bitmap-line))

(use-package rainbow-delimiters
  :straight t
  :if (not my/lowpower)
  :hook (
    (prog-mode . rainbow-delimiters-mode)))

(use-package lsp-mode
  :straight t
  :hook (
         (typescript-mode . lsp)
         (vue-mode . lsp)
         (go-mode . lsp)
         (svelte-mode . lsp)
         (python-mode . lsp)
         (json-mode . lsp)
         (haskell-mode . lsp)
         (haskell-literate-mode . lsp)
         (java-mode . lsp)) 
  :commands lsp
  :config
  (setq lsp-idle-delay 1)
  (setq lsp-eslint-server-command '("node" "/home/pavel/.emacs.d/.cache/lsp/eslint/unzipped/extension/server/out/eslintServer.js" "--stdio"))
  (setq lsp-eslint-run "onSave")
  (setq lsp-signature-render-documentation nil)
 ;  (lsp-headerline-breadcrumb-mode nil)
  (setq lsp-headerline-breadcrumb-enable nil)
  (add-to-list 'lsp-language-id-configuration '(svelte-mode . "svelte")))
  
(use-package lsp-ui
  :straight t
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-doc-delay 2)
  (setq lsp-ui-sideline-show-hover nil))

;; (use-package helm-lsp
;;   :straight t
;;   :commands helm-lsp-workspace-symbol)

;; (use-package origami
;;   :straight t
;;   :hook (prog-mode . origami-mode))

;; (use-package lsp-origami
;;   :straight t
;;   :config
;;   (add-hook 'lsp-after-open-hook #'lsp-origami-try-enable))

(use-package lsp-treemacs
  :straight t
  :commands lsp-treemacs-errors-list)

(my-leader-def
  "ld" 'lsp-ui-peek-find-definitions
  "lr" 'lsp-rename
  "lu" 'lsp-ui-peek-find-references
  "ls" 'lsp-ui-find-workspace-symbol
  ;; "la" 'helm-lsp-code-actions
  "le" 'list-flycheck-errors)

(use-package flycheck
  :straight t
  :config
  (global-flycheck-mode)
  (setq flycheck-check-syntax-automatically '(save idle-buffer-switch mode-enabled))
  (add-hook 'evil-insert-state-exit-hook
            '(lambda ()
               (if flycheck-checker
                   (flycheck-buffer))
               ))
  (advice-add 'flycheck-eslint-config-exists-p :override (lambda() t))
  (add-to-list 'display-buffer-alist
               `(,(rx bos "*Flycheck errors*" eos)
                 (display-buffer-reuse-window
                  display-buffer-in-side-window)
                 (side            . bottom)
                 (reusable-frames . visible)
                 (window-height   . 0.33))))

(defun my/set-smartparens-indent (mode)
  (sp-local-pair mode "{" nil :post-handlers '(("|| " "SPC") ("||\n[i]" "RET")))
  (sp-local-pair mode "[" nil :post-handlers '(("|| " "SPC") ("||\n[i]" "RET")))
  (sp-local-pair mode "(" nil :post-handlers '(("|| " "SPC") ("||\n[i]" "RET"))))

(defun set-flycheck-eslint()
  "Override flycheck checker with eslint."
  (setq-local lsp-diagnostic-package :none)
  (setq-local flycheck-checker 'javascript-eslint))

(use-package typescript-mode
  :straight t
  :mode "\\.ts\\'"
  :config
  (add-hook 'typescript-mode-hook #'smartparens-mode)
  (add-hook 'typescript-mode-hook #'rainbow-delimiters-mode)
  (add-hook 'typescript-mode-hook #'hs-minor-mode)
  (my/set-smartparens-indent 'typescript-mode))

(add-hook 'js-mode-hook #'smartparens-mode)
(add-hook 'js-mode-hook #'hs-minor-mode)
(my/set-smartparens-indent 'js-mode)

(use-package jest-test-mode
  :straight t
  :hook ((typescript-mode . jest-test-mode)
         (js-mode . jest-test-mode))
  :config
  (my-leader-def
    :keymaps 'jest-test-mode-map
    :infix "t"
    "t" 'jest-test-run-at-point
    "r" 'jest-test-run
    "a" 'jest-test-run-all-tests))

(use-package vue-mode
  :straight t
  :mode "\\.vue\\'"
  :config
  (add-hook 'vue-mode-hook #'hs-minor-mode)
  (add-hook 'vue-mode-hook #'smartparens-mode)
  (my/set-smartparens-indent 'vue-mode)
  (add-hook 'vue-mode-hook (lambda () (set-face-background 'mmm-default-submode-face nil))))

(with-eval-after-load 'editorconfig
  (add-to-list 'editorconfig-indentation-alist
               '(vue-mode css-indent-offset
                          js-indent-level
                          sgml-basic-offset
                          ssass-tab-width
                          typescript-indent-level
                          )))

(use-package svelte-mode
  :straight t
  :mode "\\.svelte\\'"
  :config
  (add-hook 'svelte-mode-hook 'set-flycheck-eslint)
  (add-hook 'svelte-mode-hook #'smartparens-mode)
  (my/set-smartparens-indent 'svelte-mode))

(add-hook 'scss-mode-hook #'smartparens-mode)
(add-hook 'scss-mode-hook #'hs-minor-mode)
(my/set-smartparens-indent 'scss-mode)

(use-package php-mode
  :straight t
  :mode "\\.php\\'")

(use-package tex
  :straight auctex
  ;; :mode "\\.tex\\'"
  :config
  (setq-default TeX-auto-save t)
  (setq-default TeX-parse-self t)
  (TeX-PDF-mode)
  ;; Use XeLaTeX & stuff
  (setq-default TeX-engine 'xetex)
  (setq-default TeX-command-extra-options "-shell-escape")
  (setq-default TeX-source-correlate-method 'synctex)
  (TeX-source-correlate-mode)
  (setq-default TeX-source-correlate-start-server t)
  (setq-default LaTeX-math-menu-unicode t)

  (setq-default font-latex-fontify-sectioning 1.3)

  ;; Scale preview for my DPI
  (setq-default preview-scale-function 1.4)
  ;; (assoc-delete-all "--" tex--prettify-symbols-alist)
  ;; (assoc-delete-all "---" tex--prettify-symbols-alist)

  (add-hook 'LaTeX-mode-hook
            (lambda ()
              (TeX-fold-mode 1)
              (outline-minor-mode)))
  
  (add-to-list 'TeX-view-program-selection
               '(output-pdf "Zathura"))
  
  ;; Do not run lsp within templated TeX files
  (add-hook 'LaTeX-mode-hook
            #'(lambda ()
                (unless (string-match "\.hogan\.tex$" (buffer-name))
                  (lsp))
                (setq-local lsp-diagnostic-package :none)
                (setq-local flycheck-checker 'tex-chktex)))
  
  (add-hook 'LaTeX-mode-hook #'rainbow-delimiters-mode)
  (add-hook 'LaTeX-mode-hook #'smartparens-mode)
  (add-hook 'LaTeX-mode-hook #'prettify-symbols-mode)
  
  (my/set-smartparens-indent 'LaTeX-mode)
  (require 'smartparens-latex)
  
  (general-nmap
    :keymaps '(LaTeX-mode-map latex-mode-map)
    "RET" 'TeX-command-run-all
    "C-c t" 'orgtbl-mode))

(defun my/import-sty ()
  (interactive)
  (insert 
   (apply #'concat
          (cl-mapcar
           (lambda (file) (concat "\\usepackage{" (file-name-sans-extension (file-relative-name file default-directory)) "}\n"))
           (sort 
            (seq-filter
             (lambda (file) (if (string-match ".*\.sty$" file) 1 nil))
             (directory-files
              (seq-some
               (lambda (dir)
                 (if (and
                      (f-directory-p dir)
                      (seq-some
                       (lambda (file) (string-match ".*\.sty$" file))
                       (directory-files dir))
                      ) dir nil))
               (list "./styles" "../styles/" "." "..")) :full))
            (lambda (f1 f2)
              (pcase f1
                ("gostBibTex.sty" 2)
                ("russianlocale.sty" 1)
                (_ nil))))))))

(use-package markdown-mode
  :straight t
  :mode "\\.md\\'"
  :config
  (setq markdown-command
      (concat
       "pandoc"
       " --from=markdown --to=html"
       " --standalone --mathjax --highlight-style=pygments"
       " --css=pandoc.css"
       " --quiet"
       ))
  (setq markdown-live-preview-delete-export 'delete-on-export)
  (setq markdown-asymmetric-header t)
  (setq markdown-open-command "/home/pavel/bin/scripts/chromium-sep")
  (add-hook 'markdown-mode-hook #'smartparens-mode))

;; (use-package livedown
;;   :straight (:host github :repo "shime/emacs-livedown")
;;   :commands livedown-preview
;;   :config
;;   (setq livedown-browser "qutebrowser"))

(general-define-key
  :keymaps 'markdown-mode-map
  "M-<left>" 'markdown-promote
  "M-<right>" 'markdown-demote)

(use-package plantuml-mode
  :straight t
  :mode "(\\.\\(plantuml?\\|uml\\|puml\\)\\'"
  :config
  (setq plantuml-executable-path "/usr/bin/plantuml")
  (setq plantuml-default-exec-mode 'executable)
  (add-to-list 'auto-mode-alist '("\\.plantuml\\'" . plantuml-mode))
  (add-to-list 'auto-mode-alist '("\\.uml\\'" . plantuml-mode))
  (add-hook 'plantuml-mode-hook #'smartparens-mode))
  
(general-nmap
  :keymaps 'plantuml-mode-map
  "RET" 'plantuml-preview)

(use-package langtool
  :straight t
  :commands (langtool-check)
  :config
  (setq langtool-language-tool-server-jar "/home/pavel/Programs/LanguageTool-5.1/languagetool-server.jar")
  (setq langtool-mother-tongue "ru"))
  
(my-leader-def
  :infix "L"
  "c" 'langtool-check
  "s" 'langtool-server-stop
  "d" 'langtool-check-done
  "n" 'langtool-goto-next-error
  "p" 'langtool-goto-previous-error
  "l" 'langtool-correct-buffer)

(add-hook 'lisp-interaction-mode-hook #'smartparens-mode)
(add-hook 'emacs-lisp-mode-hook #'smartparens-strict-mode)
(add-hook 'emacs-lisp-mode-hook #'aggressive-indent-mode)

(sp-with-modes sp-lisp-modes
  (sp-local-pair "'" nil :actions nil))

(add-hook 'python-mode-hook #'smartparens-mode)
(add-hook 'python-mode-hook #'hs-minor-mode)

(use-package lsp-java
  :straight t
  :after (lsp)
  :config
  (setq lsp-java-jdt-download-url "https://download.eclipse.org/jdtls/milestones/0.57.0/jdt-language-server-0.57.0-202006172108.tar.gz"))

(add-hook 'java-mode-hook #'smartparens-mode)
  (add-hook 'java-mode-hook #'hs-minor-mode)
  (my/set-smartparens-indent 'java-mode)

(use-package clojure-mode
  :straight t
  :mode "\\.clj[sc]?\\'"
  :config
  (add-hook 'clojure-mode-hook #'smartparens-strict-mode)
  (add-hook 'clojure-mode-hook #'aggressive-indent-mode))
  
(use-package cider
  :mode "\\.clj[sc]?\\'"
  :straight t)

(use-package go-mode
  :straight t
  :mode "\\.go\\'"
  :config
  (my/set-smartparens-indent 'go-mode)
  (add-hook 'go-mode-hook #'smartparens-mode)
  (add-hook 'go-mode-hook #'hs-minor-mode))

(use-package fish-mode
  :straight t
  :mode "\\.fish\\'"
  :config
 (add-hook 'fish-mode-hook #'smartparens-mode))

(add-hook 'sh-mode-hook #'smartparens-mode)

(use-package clips-mode
  :straight t
  :mode "\\.cl\\'")

(use-package haskell-mode
  :straight t
  :mode "\\.hs\\'")
  
(use-package lsp-haskell
  :straight t
  :after (lsp haskell-mode))

(use-package json-mode
  :straight t
  :mode "\\.json\\'"
  :config
  (add-hook 'json-mode #'smartparens-mode)
  (add-hook 'json-mode #'hs-minor-mode)
  (my/set-smartparens-indent 'json-mode))

(use-package yaml-mode
  :straight t
  :mode "\\.yml\\'"
  :config
  (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode)))

(use-package csv-mode
  :straight t
  :mode "\\.csv\\'")

(use-package dockerfile-mode
  :mode "Dockerfile\\'"
  :straight t)

(defun my/edit-configuration ()
  "Open the init file."
  (interactive)
  (find-file "~/Emacs.org"))
  
;; (defun my/edit-exwm-configuration ()
;;   "Open the exwm config file."
;;   (interactive)
;;   (find-file "~/.emacs.d/exwm.org"))
  
(general-define-key "C-c c" 'my/edit-configuration)
;; (general-define-key "C-c C" 'my/edit-exwm-configuration)

(defun my/open-yadm-file ()
  "Open a file managed by yadm"
  (interactive)
  (find-file
   (concat
    (file-name-as-directory (getenv "HOME"))
    (completing-read
     "yadm files: "
     (split-string
      (shell-command-to-string "yadm ls-files $HOME --full-name") "\n")))))

(general-define-key "C-c f" 'my/open-yadm-file)

(use-package notmuch
  :ensure nil
  :commands (notmuch)
  :config
  (setq mail-specify-envelope-from t)
  (setq message-sendmail-envelope-from 'header)
  (setq mail-envelope-from 'header)
  (setq notmuch-always-prompt-for-sender t)
  (setq sendmail-program "/usr/bin/msmtp")
  (setq send-mail-function #'sendmail-send-it)
  (add-hook 'notmuch-hello-mode-hook
            (lambda () (display-line-numbers-mode 0))))
  
(my-leader-def "am" 'notmuch)

(use-package google-translate
  :straight t
  :functions (my-google-translate-at-point google-translate--search-tkk)
  :custom
  (google-translate-backend-method 'curl)
  :config
  (defun google-translate--search-tkk ()
    "Search TKK."
    (list 430675 2721866130))
  (defun my-google-translate-at-point()
    "reverse translate if prefix"
    (interactive)
    (if current-prefix-arg
        (google-translate-at-point)
      (google-translate-at-point-reverse)))
  (setq google-translate-translation-directions-alist
	'(("en" . "ru")
	  ("ru" . "en"))))

(my-leader-def
  "atp" 'google-translate-at-point
  "atP" 'google-translate-at-point-reverse
  "atq" 'google-translate-query-translate
  "atQ" 'google-translate-query-translate-reverse
  "att" 'google-translate-smooth-translate)

(my-leader-def "aw" 'eww)

(general-define-key
 :keymaps 'eww-mode-map
 "+" 'text-scale-increase
 "-" 'text-scale-decrease)

(use-package snow
  :straight (:repo "alphapapa/snow.el" :host github)
  :commands (snow))

(use-package zone
  :ensure nil
  :config
  (setq original-zone-programs (copy-sequence zone-programs)))

(defun my/zone-with-select ()
  (interactive)
  (ivy-read "Zone programs"
            (cl-pairlis
             (cl-mapcar 'symbol-name original-zone-programs)
             original-zone-programs)
            :action (lambda (elem)
                      (setq zone-programs (vector (cdr elem)))
                      (zone))))
