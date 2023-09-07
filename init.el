;;; init.el --- the entry of emacs config -*- lexical-binding: t -*-
;; Author: Cabins
;; Github: https://github.com/cabins/emacs.d

;;; Commentary:
;; (c) Cabins Kong, 2022-

;;; Code:
(require 'subr-x)

;; Default directory location(Not necessary, but RECOMMENDED)
(setq default-directory "~/")
(add-to-list 'load-path (concat user-emacs-directory "lisp"))

;; definitions
(defvar cabins--os-win (memq system-type '(ms-dos windows-nt cygwin)))
(defvar cabins--os-mac (eq system-type 'darwin))

;;;###autoload
(defun cabins--set-font-common (character font-list &optional scale-factor)
  "Set fonts for multi CHARACTER from FONT-LIST and modify style with SCALE-FACTOR."

  (cl-loop for font in font-list
	   when (find-font (font-spec :name font))
	   return (if (not character)
		      (set-face-attribute 'default nil :family font)
		    (when scale-factor (setq face-font-rescale-alist `((,font . ,scale-factor))))
		    (set-fontset-font t character (font-spec :family font) nil 'prepend))))

;;;###autoload
(defun cabins--font-setup ()
  "Font setup."

  (interactive)
  (when (display-graphic-p)
    (cabins--set-font-common nil '("Sometype Mono" "Cascadia Code PL" "Menlo" "Consolas"))
    (cabins--set-font-common 'unicode '("Segoe UI Symbol" "Symbola" "Symbol"))
    (cabins--set-font-common 'emoji '("Noto Color Emoji" "Apple Color Emoji"))
    (dolist (charset '(kana han bopomofo cjk-misc))
      (cabins--set-font-common charset '("KaiTi" "STKaiTi" "WenQuanYi Micro Hei") 1.2))))

;;;###autoload
(defun cabins--cleaner-ui ()
  "Remove all the unnecessary elements."

  (when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
  (when (fboundp 'tool-bar-mode) (tool-bar-mode -1)))

;;;###autoload
(defun cabins--available-theme (theme-list)
  "Get the first available theme from THEME-LIST."

  (cl-loop for theme in theme-list
	   when (member theme (custom-available-themes))
	   return (load-theme theme t)))

;;;###autoload
(defun cabins--load-theme()
  "Load theme, Auto change color scheme according to system dark mode on Windows."

  (interactive)
  (when (display-graphic-p)
    ;; choose theme according to system dark/light mode
    (let* ((cmd (cond
		 (cabins--os-win
		  "powershell (Get-ItemProperty -Path HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize -Name AppsUseLightTheme).AppsUseLightTheme")
		 (cabins--os-mac
		  "defaults read -g AppleInterfaceStyle")
		 ((eq system-type 'gnu/linux)
		  "gsettings get org.gnome.desktop.interface color-scheme")))
	   (mode (string-trim (shell-command-to-string cmd))))
      (if (member mode '("0" "Dark" "'prefer-dark'"))
	  (cabins--available-theme '(modus-vivendi leuven-dark tsdh-dark tango-dark))
	(cabins--available-theme '(modus-operandi leuven tsdh-light tango))))))

;;;###autoload
(defun cabins--user-init-file()
  "Nothing, but alias like `crux-find-user-init-file', inspired by VSCode."

  (interactive)
  (find-file-other-window user-init-file))

;;;###autoload
(defun cabins--custom-file()
  "Nothing, but alias like `crux-find-user-custom-file', inspired by VSCode."

  (interactive)
  (find-file-other-window custom-file))

;;;###autoload
(defun cabins--reset-ui()
  "Try to reset ui options."

  (interactive)
  (cabins--font-setup)
  (cabins--load-theme))

(add-hook 'emacs-startup-hook #'cabins--reset-ui)
(when (daemonp)
  (add-hook 'after-make-frame-functions
	    (lambda (frame) (with-selected-frame frame
			  (cabins--reset-ui)))))

;; packages
(use-package package
  :config
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
  (unless (bound-and-true-p package--initialized)
    (package-initialize)))

;; Emacs builtin packages
(setq-default auto-window-vscroll nil
	      inhibit-startup-screen t	   ; disable the startup screen splash
	      isearch-allow-motion t
	      isearch-lazy-count t
	      load-prefer-newer t
	      make-backup-files nil             ; disable backup file
	      read-file-name-completion-ignore-case t
	      use-short-answers t ;; Use y/n for yes/no case
	      )

;; auto revert
;; `global-auto-revert-mode' is provided by autorevert.el (builtin)
(add-hook 'after-init-hook 'global-auto-revert-mode)

;; auto save to the visited file (provided by `files.el')
(add-hook 'after-init-hook 'auto-save-visited-mode)

;; Delete Behavior
;; `delete-selection-mode' is provided by delsel.el (builtin)
(add-hook 'after-init-hook 'delete-selection-mode)

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
  :unless cabins--os-win
  :hook (text-mode . flspell-mode))

;; Highlight Current Line
(use-package hl-line
  :when (display-graphic-p)
  :hook (after-init . global-hl-line-mode))

;; ibuffer
(defalias 'list-buffers 'ibuffer)

;; minibuffer
(add-hook 'after-init-hook 'minibuffer-electric-default-mode)

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
  ;; recentf-open since v29.1, recentf-open-files since v22
  :bind (("C-c r" . #'recentf-open))
  :custom (add-to-list 'recentf-exclude '("~\/.emacs.d\/elpa\/")))

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

;; windmove.el, use  <SHIFT - arrow key> to switch buffers
(use-package windmove
  :config (windmove-default-keybindings))

;; Third part packages
;; make use-package default behavior better
;; with `use-package-always-ensure' you won't need ":ensure t" all the time
;; with `use-package-always-defer' you won't need ":defer t" all the time
(setq use-package-enable-imenu-support t
      use-package-expand-minimally t)

;; Settings for company, auto-complete only for coding.
(use-package company :ensure t :defer t
  :hook ((prog-mode . company-mode)
	 (inferior-emacs-lisp-mode . company-mode)))

;; crux, a collection of many useful extensions/commands
(use-package crux :ensure t :defer t)

;; Settings for exec-path-from-shell
;; fix the PATH environment variable issue
(use-package exec-path-from-shell
  :ensure t
  :when (or (memq window-system '(mac ns x))
	    (unless cabins--os-win
	      (daemonp)))
  :init (exec-path-from-shell-initialize))

;; format all, formatter for almost languages
;; great for programmers
(use-package format-all :ensure t :defer t
  :bind ("C-c f" . #'format-all-buffer))

;; gnu-elpa-keyring-update
(use-package gnu-elpa-keyring-update :ensure t :defer t)

;; iedit - edit same text in one buffer or region
(use-package iedit :ensure t :defer t)

;; move-dup, move/copy line or region
(use-package move-dup :ensure t :defer t
  :hook (after-init . global-move-dup-mode))

;; Settings for which-key - suggest next key
(use-package which-key :ensure t :defer t
  :hook (after-init . which-key-mode))

;;Configs for OS
;; Special configs for MS-Windows
(when (and cabins--os-win
	   (boundp 'w32-get-true-file-attributes))
  (setq w32-get-true-file-attributes nil
	w32-pipe-read-delay 0
	w32-pipe-buffer-size (* 64 1024)))

;; Special configs for macOS
(when cabins--os-mac
  (setq mac-command-modifier 'meta
	mac-option-modifier 'super
	ns-use-native-fullscreen t))

;; solve the Chinese paste issue
;; let Emacs auto-guess the selection coding according to the Windows/system settings
(unless cabins--os-win
  (set-selection-coding-system 'utf-8))

;; Configs for programming languages
(add-hook 'prog-mode-hook 'column-number-mode)
(add-hook 'prog-mode-hook 'display-line-numbers-mode)
(add-hook 'prog-mode-hook 'electric-pair-mode)
(add-hook 'prog-mode-hook 'flymake-mode)
(add-hook 'prog-mode-hook 'hs-minor-mode)
(add-hook 'prog-mode-hook 'prettify-symbols-mode)

;; Flymake
(global-set-key (kbd "M-n") #'flymake-goto-next-error)
(global-set-key (kbd "M-p") #'flymake-goto-prev-error)

;; Some useful tools
(use-package protobuf-mode :ensure t :defer t)
(use-package quickrun :ensure t :defer t)
(use-package restclient :ensure t :defer t
  :mode (("\\.http\\'" . restclient-mode)))

;; Language Server (eglot - builtin since v29)
(use-package eglot
  :hook (prog-mode . eglot-ensure)
  :bind ("C-c e f" . eglot-format)
  :config (advice-add 'eglot-code-action-organize-imports :before #'eglot-format))

(use-package treesit
  :when (and (fboundp 'treesit-available-p)
	     (treesit-available-p))
  :config (setq treesit-font-lock-level 4)
  :init
  (setq treesit-language-source-alist
	'((bash       . ("https://github.com/tree-sitter/tree-sitter-bash"))
	  (c          . ("https://github.com/tree-sitter/tree-sitter-c"))
	  (cpp        . ("https://github.com/tree-sitter/tree-sitter-cpp"))
	  (css        . ("https://github.com/tree-sitter/tree-sitter-css"))
	  (cmake      . ("https://github.com/uyha/tree-sitter-cmake"))
	  (csharp     . ("https://github.com/tree-sitter/tree-sitter-c-sharp.git"))
	  (dockerfile . ("https://github.com/camdencheek/tree-sitter-dockerfile"))
	  (elisp      . ("https://github.com/Wilfred/tree-sitter-elisp"))
	  (go         . ("https://github.com/tree-sitter/tree-sitter-go"))
	  (gomod      . ("https://github.com/camdencheek/tree-sitter-go-mod.git"))
	  (html       . ("https://github.com/tree-sitter/tree-sitter-html"))
	  (java       . ("https://github.com/tree-sitter/tree-sitter-java.git"))
	  (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript"))
	  (json       . ("https://github.com/tree-sitter/tree-sitter-json"))
	  (lua        . ("https://github.com/Azganoth/tree-sitter-lua"))
	  (make       . ("https://github.com/alemuller/tree-sitter-make"))
	  (markdown   . ("https://github.com/MDeiml/tree-sitter-markdown" nil "tree-sitter-markdown/src"))
	  (ocaml      . ("https://github.com/tree-sitter/tree-sitter-ocaml" nil "ocaml/src"))
	  (org        . ("https://github.com/milisims/tree-sitter-org"))
	  (python     . ("https://github.com/tree-sitter/tree-sitter-python"))
	  (php        . ("https://github.com/tree-sitter/tree-sitter-php"))
	  (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" nil "typescript/src"))
	  (tsx        . ("https://github.com/tree-sitter/tree-sitter-typescript" nil "tsx/src"))
	  (ruby       . ("https://github.com/tree-sitter/tree-sitter-ruby"))
	  (rust       . ("https://github.com/tree-sitter/tree-sitter-rust"))
	  (sql        . ("https://github.com/m-novikov/tree-sitter-sql"))
	  (vue        . ("https://github.com/merico-dev/tree-sitter-vue"))
	  (yaml       . ("https://github.com/ikatyang/tree-sitter-yaml"))
	  (toml       . ("https://github.com/tree-sitter/tree-sitter-toml"))
	  (zig        . ("https://github.com/GrayJack/tree-sitter-zig"))))
  (setq major-mode-remap-alist
	'((sh-mode         . bash-ts-mode)
	  (c-mode          . c-ts-mode)
	  (c++-mode        . c++-ts-mode)
	  (c-or-c++-mode   . c-or-c++-ts-mode)
	  (css-mode        . css-ts-mode)
	  (js-mode         . js-ts-mode)
	  (java-mode       . java-ts-mode)
	  (js-json-mode    . json-ts-mode)
	  (makefile-mode   . cmake-ts-mode)
	  (python-mode     . python-ts-mode)
	  (ruby-mode       . ruby-ts-mode)
	  (conf-toml-mode  . toml-ts-mode)))
  (add-to-list 'auto-mode-alist '("\\(?:Dockerfile\\(?:\\..*\\)?\\|\\.[Dd]ockerfile\\)\\'" . dockerfile-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode))
  (add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.y[a]?ml\\'" . yaml-ts-mode)))

(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

(provide 'init)

;;; init.el ends here
;;; Local Variables:
;; coding: utf-8
;; byte-compile-warnings: (not unresolved obsolete)
;; End:
