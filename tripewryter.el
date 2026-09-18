;; -*- lexical-binding: t; -*-

(defvar-local tripewryter--save-fill-column)

(defvar-local tripewryter--save-double-spaces)

(defvar double-spaces-regexp "\\(?:[!.?][]\"'.”’)}]*\\) \\( \\)\.")

;;;###autoload
(defun tripewryter-font-lock-hide-extra-spaces()
  (interactive)

  "Use font lock to hide double spaces.

The main purpose of this tweak is so you can have two spaces after a
period/full-stop, but they aren't displayed."

  (font-lock-add-keywords
   'nil `((,double-spaces-regexp 1 '(face font-lock-warning-face invisible
   t)))))

;;;###autoload
(defun tripewryter-remove-font-lock-hide-extra-spaces()
  (interactive)

  "Undo the action of `tripewryter-font-lock-hide-extra-spaces'."

  (font-lock-remove-keywords
   'nil `((,double-spaces-regexp 1 '(face font-lock-warning-face invisible
   t)))))

(defun tripewryter--fixup-sentences ()
  (and (eq 10 last-command-event)
       (save-excursion
         (let
             ((start (and (forward-paragraph -1) (point)))
              (end (and (forward-paragraph) (point))))
           (repunctuate-sentences t start end)))))

(defun tripewryter--window-min-size-override(orig-fun &rest args)

  "Internal function to work around an Emacs issue.

The function `window-min-size’ includes fringes and margins when making
its calculations.  There is even a note in the source to say this is
probably not what is wanted.  Olivetti mode uses fringes and/or margins
to do its thing, so if the IGNORE parameter passed to `window-min-size’
is not `safe’, the calculated size is often going to be greater than the
current window size, which stops Emacs from splitting the window!

This function is used to advise `window-min-size’ to ensure that,
whenever it is called from a window where Olivetti mode is active, the
IGNORE parameter is always `safe’.  A bit `sledgehammer to crack a nut’,
but probably OK."

  (when (bound-and-true-p olivetti-mode)
    (setf (caddr args) 'safe)) (let ((res (apply orig-fun args)))
  res))

(defun tripewryter-setup(&optional teardown)
  (interactive)

  "Enables various writing tweaks.

If TEARDOWN is true, removes the tweaks instead."

  (if (not teardown)
      (progn
        (setq tripewryter--save-fill-column fill-column
              tripewryter--save-double-spaces sentence-end-double-space)
        (setq-local fill-column 76
                    sentence-end-double-space t
                    window-min-width 78)
        (auto-fill-mode 1)
        (variable-pitch-mode 1)
        (olivetti-mode 1)
        (advice-add 'window-min-size :around
                    #'tripewryter--window-min-size-override)
        (setq-local olivetti-body-width (+ 4 fill-column)
                    olivetti-style 'fancy)
        (add-hook 'post-self-insert-hook #'tripewryter--fixup-sentences 0 t)
        (electric-quote-local-mode 1)
        (von-count-mode 1)
        (aline-mode 1)
        (tripewryter-font-lock-hide-extra-spaces))
    (auto-fill-mode -1)
    (olivetti-mode -1)
    (advice-remove 'window-min-size
                   #'tripewryter--window-min-size-override)
    (variable-pitch-mode -1)
    (remove-hook 'post-self-insert-hook #'tripewryter--fixup-sentences)
    (electric-quote-local-mode -1)
    (von-count-mode -1)
    (aline-mode -1)
    (setq-local fill-column tripewryter--save-fill-column
                sentence-end-double-space tripewryter--save-double-spaces
                tripewryter--save-fill-column nil
                tripewryter--save-double-spaces nil)
    (tripewryter-remove-font-lock-hide-extra-spaces)))

;;;###autoload
(define-minor-mode tripewryter-mode

  "Enable various opinionated writing tweaks and modes."

  :lighter nil
  (if tripewryter-mode
      (tripewryter-setup)
    (tripewryter-setup 'teardown)))

(provide 'tripewryter)
