;;; usa-president-2020.el -- Indicate USA President 2020 -*- lexical-binding: t; -*-

;;; Commentary:
;; Indicate USA President 2020

;;; Code:

(require 'request)

(defgroup usa-president-2020 nil
  "USA President 2020"
  :group 'comm)

(defcustom usa-president-2020-mode-line
  '(:eval
    (propertize (concat " [B(" (format "%d" usa-president-2020-biden-votes) ") vs T(" (format "%d" usa-president-2020-trump-votes) ")]")))
  "Mode line lighter for USA President 2020."
  :type 'sexp
  :risky t
  :group 'usa-president-2020)

(defcustom usa-president-update-interval 60
  "Seconds after which the electoral votes will be updated."
  :type 'integer
  :group 'usa-president-2020)

(defvar usa-president-2020-update-timer nil)
(defvar usa-president-2020-biden-votes nil)
(defvar usa-president-2020-trump-votes nil)

(defun usa-president-2020-echo ()
  "Indicate USA President 2020."
  (interactive)
  (request
    "https://www.huffpost.com/elections/president.json"
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (let* ((wins (assoc-default
                              'wins
                              (assoc-default
                               'president
                               (assoc-default
                                'summaries
                                data))))
                       (biden (assoc-default 'dem wins))
                       (tramp (assoc-default 'gop wins)))
                  (message "Biden(%s) vs Trump(%s)" biden tramp))))))

(cl-defun usa-president-2020-update-callback (&key data &allow-other-keys)
  "Update `usa-president-2020-biden-votes` and `usa-president-2020-trump-votes` by DATA."
  (let* ((wins (assoc-default 'wins
                              (assoc-default 'president
                                             (assoc-default 'summaries
                                                            data))))
         (biden-votes (assoc-default 'dem wins))
         (trump-votes (assoc-default 'gop wins)))
    (setq usa-president-2020-biden-votes biden-votes
          usa-president-2020-trump-votes trump-votes)
    (message "usa-president-2020 updated.")
    (force-mode-line-update t))
  (when usa-president-2020-mode
    (setq usa-president-2020-update-timer
          (run-at-time usa-president-update-interval nil #'usa-president-2020-update))))

(defun usa-president-2020-update ()
  "Update usa-president-2020-mode-line."
  (when usa-president-2020-mode
    (request
    "https://www.huffpost.com/elections/president.json"
    :parser 'json-read
    :timeout 5
    :complete #'usa-president-2020-update-callback)))

;;;###autoload
(define-minor-mode usa-president-2020-mode
  "Toggle usa president electoral votes display in mode line."
  :global t :group 'usa-president-2020
  (if (not usa-president-2020-mode)
      (progn
        (setq global-mode-string
              (delq 'usa-president-2020-mode-line global-mode-string))
        (when usa-president-2020-update-timer
          (cancel-timer usa-president-2020-update-timer)
          (setq usa-president-2020-update-timer nil)))
    (add-to-list 'global-mode-string 'usa-president-2020-mode-line t)
    (usa-president-2020-update)))

(provide 'usa-president-2020)
;;; usa-president-2020.el ends here
