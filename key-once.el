;;; key-once.el --- Create transient keymaps for repeated command execution -*- lexical-binding: t; -*-
;; Copyright (C) 2025 KawaYww

;; Author: Your Name <kawayww@gmail.com>
;; Version: 0.0.1
;; Package-Requires: ((emacs "26.1"))
;; Keywords: convenience, keys, keybindings
;; URL: https://github.com/kawayww/key-once.el

;;; Commentary:

;; Key-once allows you to create commands that activate transient keymaps
;; for repeated command execution.
;;
;; Basic usage:
;;   (key-once-create "undo" 
;;     :continue '((\"k\" . undo-only)
;;                 (\"j\" . undo-redo)))
;;
;; This creates `key-once-undo' command that you can bind to a key.
;; When activated, pressing 'k' will call undo-only, and you can press
;; 'k' repeatedly to undo multiple times.

;;; Code:

(defgroup key-once nil
  "Create transient keymaps for repeated command execution."
  :group 'editing)

(defcustom key-once-global-exit-key "q"
  "Key to exit the key-once menu."
  :type 'string
  :group 'key-once)

;; ----------------------------
;; Internal helper functions
;; ----------------------------

(defvar key-once--maps (make-hash-table :test 'equal)
  "Hash table storing key-once keymaps.")
(defvar key-once--active-p nil
  "Non-nil if a key-once menu is currently active.")
(defvar key-once--current-menu-name nil
  "Return name of the current active keymap")

(defun key-once--show-which-key (menu-name keymap)
  "Show which-key menu"
  (when (boundp 'which-key-persistent-popup)
    (setq which-key-persistent-popup t))
  (when (fboundp 'which-key--show-keymap)
    (which-key--show-keymap menu-name keymap)))

(defun key-once--hide-which-key ()
  "Hide which-key menu"
  (when (boundp 'which-key-persistent-popup)
    (setq which-key-persistent-popup nil))
  (when (fboundp 'which-key--hide-popup)
    (which-key--hide-popup)))



(defun key-once--string-to-slug (str)
  "Convert STR to a URL-friendly slug.
If ALLOW-UNICODE is non-nil, allow Unicode letters and numbers.
Otherwise, only allow ASCII alphanumerics.
Examples:
  (string-to-slug \"Hello, World!\") -> \"hello-world\"
  (string-to-slug \"测试 Test 123\") -> \"test-123\"
  (string-to-slug \"测试 Test 123\" t) -> \"测试-test-123\""
  (when (stringp str)
    (let* ((pattern "[^[:alnum:][:multibyte:]]+")
           (sanitized (replace-regexp-in-string pattern "-" (downcase str))))
      ;; Remove leading/trailing hyphens and collapse multiple hyphens
      (replace-regexp-in-string "^-+\\|-+$" ""
        (replace-regexp-in-string "-+" "-" sanitized)))))

(defun key-once--create-menu-name (name)
  "Create menu name"
  (concat "menu-" (key-once--string-to-slug name)))

(defun key-once--call (command &optional exit-after)
  "Wrap COMMAND for execution. If EXIT-AFTER is non-nil, exit menu after running."
  (lambda ()
    (interactive)
    (cond
      ((commandp command) ;; For symbol commands (like 'undo)
        (call-interactively command)) 
      ((functionp command) ;; For lambda functions
        (funcall command))
      (t
        (error "Invalid command: %s" command)))
    (when exit-after
      (key-once--exit))))

(defun key-once--define-keymap (repeat-bindings quit-bindings)
  "Create a sparse keymap from BINDINGS.
BINDINGS is a list of (KEY . COMMAND)."
  (let ((map (make-sparse-keymap)))
    ;; repeat bindings (stay in menu)
    (dolist (pair repeat-bindings)
      (let ((key (car pair)) (repeat-cmd (key-once--call (cdr pair))))
        (define-key map key repeat-cmd)))

    ;; quit bindings (exit after exec)
    (dolist (pair quit-bindings)
      (let ((key (car pair)) (quit-cmd (key-once--call (cdr pair) t)))
        (define-key map key quit-cmd)))

    (when key-once-global-exit-key
      (let ((exit-cmd (key-once--call #'key-once--exit)))
        (define-key map key-once-global-exit-key exit-cmd)))

    map))

(defun key-once--show (name map)
  "Show a key-once menu with NAME and MAP."
  (setq key-once--active-p t
        key-once--current-menu-name (key-once--create-menu-name name))
  (key-once--show-which-key key-once--current-menu-name map)
  (set-transient-map map (lambda () key-once--active-p) (lambda () (key-once--exit)))
  (when (sit-for 0)
    (setq unread-command-events
          (append (list last-input-event) unread-command-events))))
  ; )

(defun key-once--exit ()
  "Exit the current key-once menu and reset active state."
  ; (interactive)
  (when key-once--active-p
    (setq key-once--active-p nil)
    (key-once--hide-which-key)
    (message "[key-once] %s exited." key-once--current-menu-name)))

;; ----------------------------
;; Public API
;; ----------------------------

;;;###autoload
(defun key-once-create (name &rest args)
  "Create a transient keymap named NAME.

ARGS accepts keyword arguments:
  :repeat — list of (KEY . COMMAND) bindings to keep menu open.
  :quit   — list of (KEY . COMMAND) bindings that exit after exec."
  (let* ((repeat-bindings (plist-get args :repeat))
         (quit-bindings (plist-get args :quit))
         (map (key-once--define-keymap repeat-bindings quit-bindings))
         (menu-cmd-name (intern (concat "key-once-" (key-once--create-menu-name name)))))
    ;; Store in internal hash
    (puthash name map key-once--maps)

    ;; Generate menu command
    (fset menu-cmd-name (lambda () (interactive) (key-once--show name map)))
    menu-cmd-name))

;; ----------------------------
;; Utility functions
;; ----------------------------
(defun key-once-active-p ()
  "Return non-nil if a key-once menu is currently active."
  key-once--active-p)

(provide 'key-once)

;;; key-once.el ends here
