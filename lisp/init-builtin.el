;;; init-builtin.el --- initialize the builtin plugins -*- lexical-binding: t -*-
;;; Commentary:
;; (c) Cabins Kong, 2022-

;;; Code:

;; Misc configurations for default
(setq-default auto-window-vscroll nil
              cursor-type 'bar
              help-window-select t
              indent-tabs-mode nil ;; Use space for indent
              inhibit-default-init t
              inhibit-startup-screen t	   ; disable the startup screen splash
              isearch-allow-motion t
              isearch-lazy-count t
              load-prefer-newer t
              make-backup-files nil             ; disable backup file
              mode-line-compact t ;; Use compact modeline style
              read-file-name-completion-ignore-case t
              read-process-output-max (* 64 1024)
              ring-bell-function 'ignore
              scroll-conservatively 10000
              truncate-lines nil
              truncate-partial-width-windows nil
              use-short-answers t ;; Use y/n for yes/no case
              visible-bell nil)

;; auto revert
;; `global-auto-revert-mode' is provided by autorevert.el (builtin)
(use-package autorevert
  :hook (after-init . global-auto-revert-mode))

;; auto save to the visited file (provided by `files.el')
(use-package files
  :hook
  (after-init . auto-save-visited-mode))

;; Delete Behavior
;; `delete-selection-mode' is provided by delsel.el (builtin)
(use-package delsel
  :hook (after-init . delete-selection-mode))

;; fido-mode
;; `fido-mode' is provided by icomplete.el
(use-package icomplete
  :hook (after-init . fido-vertical-mode)
  :config (setq completions-detailed t))

;; Flyspell
;; to use this package, you may install 'aspell' and dict by manual
;; for example, "pacman -S aspell" on archlinux
;; and "pacman -S pacman -S mingw64/mingw-w64-x86_64-aspell{,-en}" on msys2 (Windows)
;; for performance issue, do NOT use on Windows
(use-package flyspell
  :unless (memq system-type '(ms-dos windows-nt cygwin))
  :hook (text-mode . flspell-mode))

;; Highlight Current Line
(use-package hl-line
  :when (display-graphic-p)
  :hook (after-init . global-hl-line-mode))

;; ibuffer
(defalias 'list-buffers 'ibuffer)

;; minibuffer
(use-package minibuf-eldef
  :hook (after-init . minibuffer-electric-default-mode))

;; Org Mode
(use-package org
  :hook (org-mode . org-num-mode)
  :config
  (setq org-hide-leading-stars t
        org-hide-emphasis-markers t
        org-startup-indented t
        org-latex-listings 'minted
        ;; use tectonic to export pdf
        org-latex-pdf-process '("tectonic -Z shell-escape %f"))
  ;; solve CJK issue when export to pdf
  (add-to-list 'org-latex-packages-alist '("" "ctex"))
  ;; highlight code block
  (add-to-list 'org-latex-packages-alist '("" "minted"))
  ;; long word wrap when export to pdf
  (add-to-list 'org-latex-packages-alist '("" "seqsplit")))

;; Pulse the cursor line
(dolist (cmd '(recenter-top-bottom other-window))
  (advice-add cmd :after
              (lambda (&rest _) (pulse-momentary-highlight-one-line (point)))))

;; Recentf
(use-package recentf
  :hook (after-init . recentf-mode)
  :bind (("C-c r" . #'recentf-open-files))
  :custom
  (add-to-list 'recentf-exclude '("~\/.emacs.d\/elpa\/")))

;; Show Paren Mode
(use-package paren
  :config
  (setq show-paren-when-point-in-periphery t
        show-paren-when-point-inside-paren t
        show-paren-style 'mixed))

;; Speedbar
(use-package speedbar
  :config
  (setq speedbar-show-unknown-files t)
  (global-set-key (kbd "<f8>") #'speedbar))

;; whitespace
(add-hook 'before-save-hook #'whitespace-cleanup)

;; windmove.el, use C-c <arrow key> to switch buffers
(use-package windmove
  :config (windmove-default-keybindings))

(provide 'init-builtin)

;;; init-builtin.el ends here
;; Local Variables:
;; byte-compile-warnings: (not free-vars unresolved)
;; End:
