# Emacs

With [apheleia](https://github.com/radian-software/apheleia), which formats on save without moving point:

```elisp
(with-eval-after-load 'apheleia
  (setf (alist-get 'beaver apheleia-formatters)
        '("beaver" "--stdin" "--stdin-name" filepath))
  (setf (alist-get 'dart-mode apheleia-mode-alist) 'beaver)
  (setf (alist-get 'dart-ts-mode apheleia-mode-alist) 'beaver))
(apheleia-global-mode +1)
```

Saving a Dart buffer formats it; `M-x apheleia-format-buffer` formats on demand. `filepath` passes the file's path so `.beaver.yaml` and exclusions apply.

Selection formatting: not available. apheleia formats whole buffers.
