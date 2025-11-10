# key-once.el

`key-once.el` allows you to create transient keymaps for performing grouped commands repeatedly.  
Think of it as a lightweight alternative to `transient`, `hydra`, or `repeat-mode`, but just simpler.  

This package is designed to be integrated with other modal-editing package, like `general`, `meow`.  
(WIP)

# Installation

- manually: clone this repo, add the full path of it to your `load-path`, and then:

```elisp
(add-to-list 'load-path "~/.emacs.d/site-lisp/key-once/")
(require 'key-once)
```

- use-package:

```elisp
(use-package key-once
  :vc (:url "https://github.com/kawayww/key-once.el"
       :branch "main"))
```

- straight.el: 

```elisp
(use-package key-once
  :straight (key-once :type git :host github :repo "kawayww/key-once.el"))
```

# Examples

with `meow`:

```elisp
(use-package key-once
  :straight (key-once :type git :host github :repo "kawayww/key-once.el"))

(use-package undo-tree
  :straight t
  :init (global-undo-tree-mode)
  :after meow key-once
  :config
  (key-once-create "undo"
    '(("u" . undo-tree-undo)
      ("r" . undo-tree-redo)
      ("s" . undo-tree-save-history)
      ("l" . undo-tree-load-history)
      ("v" . undo-tree-visualize)))
  (meow-leader-define-key '("u" . key-once-menu-undo)))
```
