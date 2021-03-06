;;; ergoemacs-test.el --- tests for ErgoEmacs issues

;; Copyright © 2013-2016 Free Software Foundation, Inc.

;; Maintainer: Matthew L. Fidler
;; Keywords: convenience

;; ErgoEmacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; ErgoEmacs is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with ErgoEmacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;; Todo:

;; 

;;; Code:

(eval-when-compile 
  (require 'cl-lib)
  (require 'ergoemacs-macros))

(declare-function ergoemacs-translate--keymap "ergoemacs-translate")
(declare-function ergoemacs-mode-reset "ergoemacs-mode")

(defvar ergoemacs-map--)
(defvar ergoemacs-layout-us)
(defvar ergoemacs-keyboard-layout)
(defvar ergoemacs-command-loop-type)
(defvar ergoemacs-dir)
(defvar ergoemacs-mode)
(defvar dired-sort-map)
(defvar dired-mode-map)

(declare-function ergoemacs-translate--meta-to-escape "ergoemacs-translate")
(declare-function ergoemacs-map-keymap "ergoemacs-mapkeymap")

(declare-function ergoemacs-mode "ergoemacs-mode")

(declare-function ergoemacs-command-loop--mouse-command-drop-first "ergoemacs-command-loop")

(declare-function ergoemacs-copy-line-or-region "ergoemacs-functions")
(declare-function ergoemacs-cut-line-or-region "ergoemacs-functions")
(declare-function ergoemacs-emacs-exe "ergoemacs-functions")
(declare-function ergoemacs-eshell-here "ergoemacs-functions")
(declare-function ergoemacs-paste "ergoemacs-functions")

(declare-function ergoemacs-translate--quail-to-ergoemacs "ergoemacs-translate")
(declare-function ergoemacs-translate-layout "ergoemacs-translate")

(require 'ert)
(require 'elp)
;;; Not sure why `cl-gensym' is called, probably from `ert'/`elp'?
;; Suppress: "the function `cl-gensym' might not be defined at
;; runtime" warning.
(autoload 'cl-gensym "cl-macs.el")
(defvar ergoemacs-test-lorem-ipsum
  "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed
do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
enim ad minim veniam, quis nostrud exercitation ullamco laboris
nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat
nulla pariatur. Excepteur sint occaecat cupidatat non proident,
sunt in culpa qui officia deserunt mollit anim id est laborum.")

(defun ergoemacs-test-fast ()
  "Fast test of ergoemacs-mode (doesn't include keyboard startup issues)."
  (interactive)
  (elp-instrument-package "ergoemacs-")
  (ert '(and "ergoemacs-" (not (tag :slow))))
  (call-interactively 'elp-results))

(defun ergoemacs-test-search ()
  "Test search functionality in ergoemacs-mode."
  (interactive)
  (elp-instrument-package "ergoemacs-")
  (ert '(and "ergoemacs-" (tag :search)))
  (call-interactively 'elp-results))

(defun ergoemacs-test-map-keymap ()
  "Test search functionality in ergoemacs-mode."
  (interactive)
  (elp-instrument-package "ergoemacs-")
  (ert '(and "ergoemacs-" (tag :map-keymap)))
  (call-interactively 'elp-results))

(defun ergoemacs-test-calc ()
  "Test for calc."
  (interactive)
  (elp-instrument-package "ergoemacs-")
  (ert '(and "ergoemacs-" (tag :calc)))
  (call-interactively 'elp-results))

(defun ergoemacs-test-no-calc ()
  "Test for calc."
  (interactive)
  (elp-instrument-package "ergoemacs-")
  (ert '(and "ergoemacs-" (not (tag :calc))))
  (call-interactively 'elp-results))

(defun ergoemacs-test-shift-select ()
  "Shift-selection test for ergoemacs-mode."
  (interactive)
  (elp-instrument-package "ergoemacs-")
  (ert '(and "ergoemacs-" (tag :shift-select)))
  (call-interactively 'elp-results))

(defun ergoemacs-test-translate ()
  "Translation test for ergoemacs-mode."
  (interactive)
  (elp-instrument-package "ergoemacs-")
  (ert '(and "ergoemacs-" (tag :translate)))
  (call-interactively 'elp-results))

(defun ergoemacs-test-interactive ()
  "Interactive test for ergoemacs-mode."
  (interactive)
  (elp-instrument-package "ergoemacs-")
  (ert '(and "ergoemacs-" (tag :interactive)))
  (call-interactively 'elp-results))

;;;###autoload
(defun ergoemacs-test ()
  "Test ergoemacs issues."
  (interactive)
  (let ((ret t)
        (test))
    (elp-instrument-package "ergoemacs-")
    (ert "^ergoemacs-test-")
    (call-interactively 'elp-results)))

;; Test isearch

;; This does not seem to work for interactive tests when I set the
;; layout to "us"
(defmacro ergoemacs-test-layout (&rest keys-and-body)
  (let ((kb (make-symbol "body-and-plist"))
        (plist (make-symbol "plist"))
        (body (make-symbol "body")))
    (setq kb (ergoemacs-theme-component--parse-keys-and-body keys-and-body  nil t)
          plist (nth 0 kb)
          body (nth 1 kb))
    (macroexpand-all
     `(let ((old-type ergoemacs-command-loop-type)
            (old-paste interprogram-paste-function)
            (old-cut interprogram-cut-function)
            (old-version nil)
            (macro
             ,(if (plist-get plist :macro)
                  `(edmacro-parse-keys ,(plist-get plist :macro) t)))
            (old-ergoemacs-keyboard-layout ergoemacs-keyboard-layout)
            (reset-ergoemacs nil))
        (setq ergoemacs-keyboard-layout ,(or (plist-get plist ':layout) "us")
              ergoemacs-command-loop-type nil
              interprogram-paste-function nil
              interprogram-cut-function nil
              
              ;; Make sure the copy functions don't think the last
              ;; command was a copy.
              last-command 'ergoemacs-test)
        (unless (equal old-ergoemacs-keyboard-layout ergoemacs-keyboard-layout)
          (setq reset-ergoemacs t)
          (ergoemacs-mode-reset))
        
        ,(if (plist-get plist :cua)
             `(cua-mode 1))
        (unwind-protect
            (progn
              ,@body)
          (setq ergoemacs-command-loop-type old-type
                ergoemacs-keyboard-layout old-ergoemacs-keyboard-layout
                interprogram-paste-function old-paste
                interprogram-cut-function old-cut
                )
          (when reset-ergoemacs
            (ergoemacs-mode-reset)))))))


(ert-deftest ergoemacs-test-isearch-C-f-backspace ()
  "Test Backspace in `isearch-mode'"
  :tags '(:search :interactive)
  ;; Google Code Issue #145
  (ergoemacs-test-layout
   :layout "colemak"
   :macro "C-f a r s C-f <backspace> M-n"
   (save-excursion
     (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
     (delete-region (point-min) (point-max))
     (insert "aars1\nars2\nars3\nars4")
     (goto-char (point-min))
     (execute-kbd-macro macro)
     (when (looking-at ".*")
       (should (string= "s1" (match-string 0))))
     (kill-buffer (current-buffer)))))

(ert-deftest ergoemacs-test-isearch-C-f ()
  "C-f doesn't work in isearch-mode."
  :tags '(:search :interactive)
  ;; Google Code Issue #119
  (ergoemacs-test-layout
   :layout "colemak"
   :cua t
   :macro "C-f ars C-f C-f"
   (save-excursion
     (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
     (delete-region (point-min) (point-max))
     (insert "aars1\nars2\nars3\nars4")
     (goto-char (point-min))
     (execute-kbd-macro macro)
     (when (looking-at ".*")
       (should (string= "3" (match-string 0))))
     (kill-buffer (current-buffer)))))

(ert-deftest ergoemacs-test-isearch-in-eshell ()
  "Test Issue #322."
  :tags '(:search)
  (ergoemacs-test-layout
   :layout "us"
   (ergoemacs-eshell-here)
   (should (eq 'isearch-forward (key-binding (kbd "C-f"))))
   (kill-buffer (current-buffer))))

(ert-deftest ergoemacs-test-isearch-works-with-region ()
  "With vanilla Emacs, when mark is active and even some region is
already selected, isearch-ing would expand or shrink selection.
Currently ergoemacs-mode discards selection as soon as isearch key is
pressed. Reproducible with ergoemacs-clean.
Issue #186."
  :tags '(:search)
  (let ((ret t))
    (ergoemacs-test-layout
     :macro "C-f lab"
     :layout "colemak"
     :cua t
     (save-excursion
       (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
       (delete-region (point-min) (point-max))
       (insert ergoemacs-test-lorem-ipsum)
       (goto-char (point-min))
       (mark-word)
       (execute-kbd-macro macro)
       (setq ret mark-active)
       (kill-buffer (current-buffer))))
    (should (equal ret t))))

(ert-deftest ergoemacs-test-isearch-exits-with-ergoemacs-movement-keys ()
  "Tests if isearch exits the search with movement keys.
Tests issue #347"
  :tags '(:search)
  (ergoemacs-test-layout
   :macro "C-f ars M-e"
   :layout "colemak"
  (save-excursion
    (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
    (delete-region (point-min) (point-max))
    (insert "aars1\nars2\nars3\nars4")
    (goto-char (point-min))
    (execute-kbd-macro macro)
    (should (not isearch-mode))
    (when isearch-mode
      (isearch-mode -1))
    (kill-buffer (current-buffer)))))

;;; Shift Selection
(ert-deftest ergoemacs-test-shift-select-move-no-mark ()
  "Tests another shifted selection"
  :tags '(:shift-select)
  (let ((ret t))
    (ergoemacs-test-layout
     :macro "M-H"
     :layout "colemak"
     (save-excursion
       (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
       (delete-region (point-min) (point-max))
       (goto-char (point-min))
       (insert ";;")
       (execute-kbd-macro macro)
       (setq ret (not mark-active)) ;;  Shouldn't be selected
       (kill-buffer (current-buffer))))
    (should (equal ret t))))

(ert-deftest ergoemacs-test-shift-select-cua-move-keep-mark ()
  "Test the shifted selection bug."
  :tags '(:shift-select)
  (let (ret)
    (ergoemacs-test-layout
     :macro "M-SPC M-h M-I"
     :layout "colemak"
     :cua t
     (save-excursion
       (switch-to-buffer (get-buffer-create "*ergoemacs-test-shifted-move*"))
       (delete-region (point-min) (point-max))
       (insert ";;;;")
       (goto-char (point-min))
       (execute-kbd-macro macro)
       (setq ret mark-active) ;; Should be selected.
       (kill-buffer (current-buffer))))
    (should (equal ret t))))

(ert-deftest ergoemacs-test-shift-select-subword ()
  "Test for mark working with shift-selection of `subword-forward'."
  :tags '(:shift-select)
  (let (ret)
    (ergoemacs-test-layout
     :macro "M-Y M-x"
     :layout "colemak"
     (save-excursion
       (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
       (delete-region (point-min) (point-max))
       (insert ergoemacs-test-lorem-ipsum)
       (subword-mode 1)
       (goto-char (point-max))
       (beginning-of-line)
       (execute-kbd-macro macro)
       (when (looking-at " in culpa qui")
         (setq ret t))
       (kill-buffer (current-buffer))))))

;;; Copy/Paste

(ert-deftest ergoemacs-test-copy-paste-cut-line-or-region ()
  "Issue #68.
kill-ring function name is used and such doesn't exist. It errs when
not using cua or cutting line. I think kill-region is what is meant."
  (let ((old-c cua-mode)
        (ret t))
    (cua-mode -1)
    (save-excursion
      (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
      (delete-region (point-min) (point-max))
      (insert ergoemacs-test-lorem-ipsum)
      (condition-case _err
          (ergoemacs-cut-line-or-region)
        (error (setq ret nil)))
      (kill-buffer (current-buffer)))
    (when old-c
      (cua-mode 1))
    (should ret)
    )
  )

;;; Functionality Test

(ert-deftest ergoemacs-test-function-bol-or-what ()
  "Test beginning of line functionality."
  (let ((ergoemacs-end-of-comment-line t)
        (ergoemacs-back-to-indentation t))
    (with-temp-buffer
      (emacs-lisp-mode) ; Turn on ergoemacs-mode 
      (insert "(progn\n  (ergoemacs-mode 1)) ; Turn on ergoemacs-mode")
      (goto-char (point-max))
      (call-interactively 'ergoemacs-beginning-of-line-or-what)
      (should (string= "Turn on ergoemacs-mode"
                       (buffer-substring (point) (point-at-eol))))
      (call-interactively 'ergoemacs-beginning-of-line-or-what)
      (should (string= " ; Turn on ergoemacs-mode"
                       (buffer-substring (point) (point-at-eol))))
      (call-interactively 'ergoemacs-beginning-of-line-or-what)
      (should (string= "(ergoemacs-mode 1)) ; Turn on ergoemacs-mode"
                       (buffer-substring (point) (point-at-eol))))
      (call-interactively 'ergoemacs-beginning-of-line-or-what)
      (should (string= "  (ergoemacs-mode 1)) ; Turn on ergoemacs-mode"
                       (buffer-substring (point) (point-at-eol)))))))


(ert-deftest ergoemacs-test-function-eol-or-what ()
  "Test beginning of line functionality."
  (let ((ergoemacs-end-of-comment-line t)
        (ergoemacs-back-to-indentation t))
    (with-temp-buffer
      (emacs-lisp-mode) ; Turn on ergoemacs-mode
      (insert "(progn\n  (ergoemacs-mode 1)) ; Turn on ergoemacs-mode")
      (goto-char (point-max))
      (beginning-of-line)
      
      (call-interactively 'ergoemacs-end-of-line-or-what)
      (should (string= " ; Turn on ergoemacs-mode"
                       (buffer-substring (point) (point-at-eol))))
      (call-interactively 'ergoemacs-end-of-line-or-what)
      (should (= (point) (point-at-eol))))))

(ert-deftest ergoemacs-test-function-unbind-commands-active ()
  "Make sure the unbound keys work"
  (should (eq nil (key-binding (read-kbd-macro "C-x C-s")))))

(ert-deftest ergoemacs-test-function-M-f-only-one-char-issue-306 ()
  "Tests Issue #306."
  :tags '(:calc)
  (let ((ergoemacs-test-fn t)
        (ergoemacs-read-input-keys nil))
    (ergoemacs-test-layout
     ;; Using 'us' here breaks everything.  All of the other tests use
     ;; 'colemak' or have identical bindings as colemak, so it is
     ;; probably an issue when you switch.  That is now unsupported.
     :layout "colemak"
     :macro "M-f"
     (save-excursion
       (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
       (delete-region (point-min) (point-max))
       (insert ergoemacs-test-lorem-ipsum)
       (fundamental-mode)
       (print "issue 306")
       (print (key-binding (kbd "M-f")))
       (print (key-binding (kbd "M-e")))
       
       (should (or (eq (key-binding (kbd "M-f")) 'backward-kill-word)
                   (eq (key-binding (kbd "M-f")) (command-remapping 'backward-kill-word (point)))))
       (setq ergoemacs-test-fn nil)
       (goto-char (point-max))
       (execute-kbd-macro macro)
       (should (string= "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed
do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut
enim ad minim veniam, quis nostrud exercitation ullamco laboris
nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat
nulla pariatur. Excepteur sint occaecat cupidatat non proident,
sunt in culpa qui officia deserunt mollit anim id est " (buffer-string)))
       (kill-buffer (current-buffer))))))


(ert-deftest ergoemacs-test-function-issue-305-variables-set-to-nil ()
  "Test Issue #305.
When calling `ergoemacs-refresh' variable values should be preserved."
  (ergoemacs-mode-reset)
  (should (eq t shift-select-mode)))

;;; Grep


(ert-deftest ergoemacs-test-grep-issue-293 ()
  "Test Issue #293.
Unable to use M-ijkl in a grep buffer."
  (ergoemacs-test-layout
   :layout "colemak"
   :macro "M-e M-e M-e M-i"
   (save-excursion
     (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
     (delete-region (point-min) (point-max))
     (insert "-*- mode: grep; default-directory: \"~src/ergoemacs-mode/\" -*-
Grep started at Fri Aug 22 08:30:37
grep -nH -e ergoemacs-mode ergoemacs-mode.el
ergoemacs-mode.el:1:;;; ergoemacs-mode.el --- Emacs mode based on common modern interface and ergonomics. -*- lexical-binding: t -*-
ergoemacs-mode.el:949:;;; ergoemacs-mode.el ends here
Grep finished (matches found) at Fri Aug 22 08:30:37
")
     (grep-mode)
     (goto-char (point-min))
     (execute-kbd-macro macro)
     (should (string= (buffer-substring (point) (+ 16 (point)))
                      "rgoemacs-mode.el"))
     (kill-buffer (current-buffer)))))

;;; Org-mode

(ert-deftest ergoemacs-test-org-C-a ()
  "Test beginning of line in standard ergoemacs-mode/org-mode."
  (ergoemacs-test-layout
   :layout "colemak"
   :macro "M-m"
   (let (ret)
     (save-excursion
       (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
       (delete-region (point-min) (point-max))
       (insert "abc\n* TODO Fix org C-a issue")
       (org-mode)
       (goto-char (point-max))
       (execute-kbd-macro macro)
       (ignore-errors
         (should (string= (buffer-substring (point) (point-at-eol))
                          "Fix org C-a issue")))
       (kill-buffer (current-buffer))))))

(ert-deftest ergoemacs-test-org-respect-keys-issue-304 ()
  "Tests Issue #304.
`org-mode' should respect the keys used."
  (let ((ergoemacs-test-fn t))
    (ergoemacs-test-layout
     :layout "us"
     (save-excursion
       (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
       (delete-region (point-min) (point-max))
       (insert ergoemacs-test-lorem-ipsum)
       (org-mode)
       (should (eq (key-binding (kbd "<M-right>")) 'ergoemacs-org-metaright))
       (should (eq (key-binding (kbd "<M-left>")) 'ergoemacs-org-metaleft))
       (should (eq (key-binding (kbd "<M-up>")) 'ergoemacs-org-metaup))
       (should (eq (key-binding (kbd "<M-down>")) 'ergoemacs-org-metadown))
       (kill-buffer (current-buffer))))))


;;; Calc

(ert-deftest ergoemacs-test-calc-300 ()
  "Test Calc undo"
  :tags '(:calc :interactive)
  (let ((ergoemacs-test-fn t))
    (ergoemacs-test-layout
     :layout "colemak"
     (call-interactively 'calc)
     (unwind-protect
         (should (eq (key-binding (kbd "C-z")) (or (command-remapping 'calc-undo (point)) 'calc-undo)))
       (call-interactively 'calc-quit)))))

(ert-deftest ergoemacs-test-calc-fries-ergoemacs-mode ()
  "After calc has entered some numbers, it fries ergoemacs-mode."
  :tags '(:calc :interactive)
  (let ((ergoemacs-test-fn t))
    (ergoemacs-test-layout
     :layout "colemak"
     (call-interactively 'calc)
     (execute-kbd-macro "1 1 +")
     (call-interactively 'calc-quit)
     (should (eq (key-binding (kbd "M-u")) 'previous-line)))))

;;; Command Loop

(ert-deftest ergoemacs-test-command-loop-C-x-8-! ()
  "Test that unicode translations work.
See Issue #138."
  (save-excursion
    (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
    (delete-region (point-min) (point-max))
    (execute-kbd-macro (kbd "C-x 8 !"))
    (should (string= "¡" (buffer-string)))
    (kill-buffer (current-buffer))))

(ert-deftest ergoemacs-test-command-loop-C-x-8-A ()
  "Test that unicode translations work.
See Issue #138."
  (save-excursion
    (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
    (delete-region (point-min) (point-max))
    (execute-kbd-macro (kbd "C-x 8 \" A"))
    (should (string= "Ä" (buffer-string)))
    (kill-buffer (current-buffer))))

;;; Global map tests.
(defun ergoemacs-test-global-key-set-before (&optional after key ergoemacs ignore-prev-global delete-def)
  "Test the global key set before ergoemacs-mode is loaded."
  :tags '(:slow)
  (let* ((emacs-exe (ergoemacs-emacs-exe))
         (ret nil)
         (sk nil)
         (test-key (or key "M-k"))
         (w-file (expand-file-name "global-test" ergoemacs-dir))
         (temp-file (make-temp-file "ergoemacs-test" nil ".el")))
    (setq sk
          (format "(%s '(lambda() (interactive) (with-temp-file \"%s\" (insert \"Ok\"))))"
                  (cond
                   ((eq ergoemacs 'define-key)
                    (format "define-key global-map (kbd \"%s\") " test-key))
                   (t
                    (format "global-set-key (kbd \"%s\") " test-key)))
                  w-file))
    (with-temp-file temp-file
      (if (boundp 'wait-for-me)
          (insert "(setq debug-on-error t)")
        (insert "(condition-case err (progn "))
      (unless after
        (when delete-def
          (insert (format "(global-set-key (kbd \"%s\") nil)" delete-def)))
        (insert sk))
      (insert (format "(add-to-list 'load-path \"%s\")" ergoemacs-dir))
      (insert "(setq ergoemacs-keyboard-layout \"us\")")
      (unless ignore-prev-global
        (insert "(setq ergoemacs-ignore-prev-global nil)"))
      (insert "(require 'ergoemacs-mode)(setq ergoemacs-mode--start-p t)(ergoemacs-mode 1)")
      (insert
       (format
        "(setq ergoemacs-test-macro (edmacro-parse-keys \"%s\" t))"
        test-key))
      (when after
        (when delete-def
          (insert (format "(global-set-key (kbd \"%s\") nil)" delete-def)))
        (insert sk))
      (insert "(execute-kbd-macro ergoemacs-test-macro)")
      (insert (format "(if (file-exists-p \"%s\") (message \"Passed\") (message \"Failed\"))" w-file))
      (unless (boundp 'wait-for-me)
        (insert ") (error (message \"Error %s\" err)))")
        (insert "(kill-emacs)")))
    (message
     "%s"
     (shell-command-to-string
      (format "%s %s -Q -l %s" emacs-exe (if (boundp 'wait-for-me) "" "--batch") temp-file)))
    (delete-file temp-file)
    (when (file-exists-p w-file)
      (setq ret 't)
      (delete-file w-file))
    ret))

(ert-deftest ergoemacs-test-global-key-set-after-220 ()
  "Test global C-c b"
  :tags '(:slow)
  (should (equal (ergoemacs-test-global-key-set-before 'after "C-c b") t)))


(ert-deftest ergoemacs-test-global-key-set-after-397 ()
  "Test global C-SPC"
  :tags '(:slow)
  (should (equal (ergoemacs-test-global-key-set-before 'after "C-SPC") t)))

(ert-deftest ergoemacs-test-397-test-3 ()
  "Test M-s is switch pane."
  :tags '(:slow)
  (let* ((emacs-exe (ergoemacs-emacs-exe))
         (w-file (expand-file-name "global-test" ergoemacs-dir))
         (temp-file (make-temp-file "ergoemacs-test" nil ".el")))
    (with-temp-file temp-file
      (insert "(eval-when-compile (load (expand-file-name \"ergoemacs-macros\")) (require 'cl-lib))"
              (or (and (boundp 'wait-for-me)
                       "(setq debug-on-error t debug-on-quit t)") "")
	      "(setq ergoemacs-keyboard-layout \"us\")"
              "(ergoemacs-mode 1)\n"
	      "(global-set-key (kbd \"C-SPC\") 'set-mark-command)\n"
              "(when (eq (key-binding (kbd \"M-s\")) 'other-window)\n"
              "(with-temp-file \"" w-file "\")\n"
              "   (message \"Passed\")"
              "  (insert \"Found\"))\n"
              (or (and (boundp 'wait-for-me) "")
                  "(kill-emacs)")))
    (byte-compile-file temp-file)
    (message "%s"
             (shell-command-to-string
              (format "%s %s -Q -L %s -l %s -l %s"
                      emacs-exe (if (boundp 'wait-for-me) "-debug-init" "--batch")
                      (expand-file-name (file-name-directory (locate-library "ergoemacs-mode")))
                      (expand-file-name (file-name-sans-extension (locate-library "ergoemacs-mode")))
                      temp-file)))
    (should (file-exists-p w-file))
    (when  (file-exists-p temp-file)
      (delete-file temp-file))
    (when  (file-exists-p (concat temp-file "c"))
      (delete-file (concat temp-file "c")))
    (when (file-exists-p w-file)
      (delete-file w-file))))

(defvar ergoemacs-component-hash)

(ert-deftest ergoemacs-test-397-test-2 ()
  "Test that defining C-SPC after ergoemacs-mode loads will give `set-mark-command'."
  :tags '(:slow)
  (let* ((emacs-exe (ergoemacs-emacs-exe))
         (w-file (expand-file-name "global-test" ergoemacs-dir))
         (temp-file (make-temp-file "ergoemacs-test" nil ".el")))
    (with-temp-file temp-file
      (insert "(eval-when-compile (require 'ergoemacs-macros) (require 'cl-lib))"
              (or (and (boundp 'wait-for-me)
                       "(setq debug-on-error t debug-on-quit t)") "")
	      "(setq ergoemacs-keyboard-layout \"us\")"
              "(ergoemacs-mode 1)\n"
	      "(global-set-key (kbd \"C-SPC\") 'set-mark-command)\n"
              "(when (eq (key-binding (kbd \"C-SPC\")) 'set-mark-command)\n"
              "(with-temp-file \"" w-file "\")\n"
              "   (message \"Passed\")"
              "  (insert \"Found\"))\n"
              (or (and (boundp 'wait-for-me) "")
                  "(kill-emacs)")))
    (byte-compile-file temp-file)
    (message "%s"
             (shell-command-to-string
              (format "%s %s -Q -L %s -l %s -l %s"
                      emacs-exe (if (boundp 'wait-for-me) "-debug-init" "--batch")
                      (expand-file-name (file-name-directory (locate-library "ergoemacs-mode")))
                      (expand-file-name (file-name-sans-extension (locate-library "ergoemacs-mode")))
                      temp-file)))
    (should (file-exists-p w-file))
    (when  (file-exists-p temp-file)
      (delete-file temp-file))
    (when  (file-exists-p (concat temp-file "c"))
      (delete-file (concat temp-file "c")))
    (when (file-exists-p w-file)
      (delete-file w-file))))

(ert-deftest ergoemacs-test-global-key-set-apps-220-before ()
  "Test global C-c b"
  :tags '(:slow :interactive)
  (should (equal (ergoemacs-test-global-key-set-before nil "C-c b") t)))

(ert-deftest ergoemacs-test-global-key-set-C-d-after ()
  "Test global C-d"
  :tags '(:slow)
  (should (equal (ergoemacs-test-global-key-set-before 'after "C-d") t)))

(ert-deftest ergoemacs-test-issue-243 ()
  "Allow globally set keys like C-c C-c M-x to work globally while local commands like C-c C-c will work correctly. "
  :tags '(:slow)
  (let ((emacs-exe (ergoemacs-emacs-exe))
        (w-file (expand-file-name "global-test" ergoemacs-dir))
        (temp-file (make-temp-file "ergoemacs-test" nil ".el")))
    (with-temp-file temp-file
      (insert "(condition-case err (progn ")
      (insert (format "(add-to-list 'load-path \"%s\")" ergoemacs-dir))
      (insert "(setq ergoemacs-keyboard-layout \"us\")")
      (insert "(setq ergoemacs-command-loop-type nil)")
      (insert "(require 'ergoemacs-mode)(require 'ergoemacs-test)(setq ergoemacs-mode--start-p t)(ergoemacs-mode 1)")
      (insert "(global-set-key (kbd \"C-c C-c M-x\") 'execute-extended-command)")
      (insert (format "(define-key ergoemacs-test-major-mode-map (kbd \"C-c C-c\") #'(lambda() (interactive (with-temp-file \"%s\" (insert \"Ok\")))))" w-file))
      (insert
       "(setq ergoemacs-test-macro (edmacro-parse-keys \"C-c C-c\" t))(ergoemacs-test-major-mode)")
      (insert "(with-timeout (0.5 nil) (execute-kbd-macro ergoemacs-test-macro))")
      (insert (format "(if (file-exists-p \"%s\") (message \"Passed\") (message \"Failed\"))" w-file))
      (insert ") (error (message \"Error %s\" err)))")
      (unless (boundp 'wait-for-me)
        (insert "(kill-emacs)")))
    (message "%s"
             (shell-command-to-string
              (format "%s %s -Q -l %s"
                      emacs-exe (if (boundp 'wait-for-me) "" "--batch")
                      temp-file)))
    (delete-file temp-file)
    (should (file-exists-p w-file))
    (when (file-exists-p w-file)
      (delete-file w-file))))

;; Issue 437
;;
;; Can override an ergoemacs binding when loading the new mode.  For
;; example, this code changes M-left to M-right.
;;
;; (add-hook 'org-mode-hook
;;   (lambda ()
;;     (define-key org-mode-map (kbd "<M-left>") 'org-metaright)
;;     ))

;;; Not sure why this doesn't actually use `ergoemacs-test-major-mode-map'.
(define-derived-mode ergoemacs-test-major-mode fundamental-mode "ET"
  "Major mode for testing some issues with `ergoemacs-mode'.
\\{ergoemacs-test-major-mode-map}")

(define-key ergoemacs-test-major-mode-map (kbd "C-s") 'search-forward)
(define-key ergoemacs-test-major-mode-map (kbd "<f6>") 'search-forward)
(define-key ergoemacs-test-major-mode-map (kbd "M-s a") 'isearch-forward)
(define-key ergoemacs-test-major-mode-map (kbd "M-s b") 'isearch-backward)

(let ((ergoemacs-is-user-defined-map-change-p t))
  (add-hook 'ergoemacs-test-major-mode-hook
            '(lambda()
               (interactive)
               (define-key ergoemacs-test-major-mode-map (kbd "C-w") 'ergoemacs-close-current-buffer))))

(ert-deftest ergoemacs-test-issue-349 ()
  "Unbind <f6>"
  :tags '(:slow :interactive)
  (let ((emacs-exe (ergoemacs-emacs-exe))
        (w-file (expand-file-name "global-test" ergoemacs-dir))
        (temp-file (make-temp-file "ergoemacs-test" nil ".el")))
    (with-temp-file temp-file
      (insert "(condition-case err (progn ")
      (insert (format "(add-to-list 'load-path \"%s\")" ergoemacs-dir))
      (insert "(setq ergoemacs-keyboard-layout \"us\")")
      (insert "(setq ergoemacs-command-loop-type nil)")
      (insert "(require 'ergoemacs-mode)(require 'ergoemacs-test)(setq ergoemacs-mode--start-p t)(ergoemacs-mode 1)")
      (insert (format "(define-key ergoemacs-test-major-mode-map (kbd \"<f6>\") #'(lambda() (interactive (with-temp-file \"%s\" (insert \"Ok\")))))" w-file))
      (insert "(global-unset-key (kbd \"<f6>\"))")
      (insert
       "(setq ergoemacs-test-macro (edmacro-parse-keys \"<f6>\" t))(ergoemacs-test-major-mode)(run-hooks 'post-command-hook)")
      (insert "(with-timeout (0.5 nil) (execute-kbd-macro ergoemacs-test-macro))")
      (insert (format "(if (file-exists-p \"%s\") (message \"Passed\") (message \"Failed\"))" w-file))
      (insert ") (error (message \"Error %s\" err)))")
      (unless (boundp 'wait-for-me)
        (insert "(kill-emacs)")))
    (message "%s"
             (shell-command-to-string
              (format "%s %s -Q -l %s"
                      emacs-exe (if (boundp 'wait-for-me) "" "--batch")
                      temp-file)))
    (delete-file temp-file)
    (should (file-exists-p w-file))
    (when (file-exists-p w-file)
      (delete-file w-file))))

(ert-deftest ergoemacs-test-ignore-ctl-w ()
  "Keep user-defined C-w in major-mode `ergoemacs-test-major-mode'.
Part of addressing Issue #147."
  (let (ret
        (ergoemacs-use-function-remapping t))
    (with-temp-buffer
      (ergoemacs-test-major-mode)
      (when (not (current-local-map))
        (use-local-map ergoemacs-test-major-mode-map))
      (should (eq (key-binding (kbd "C-w")) 'ergoemacs-close-current-buffer))
      ;; The user-defined C-w should not affect kill-region remaps.
      (should (not (eq (key-binding [ergoemacs-remap kill-region]) 'ergoemacs-close-current-buffer))))))

(ert-deftest ergoemacs-test-keep-alt-s ()
  "Keep ergoemacs defined M-s in major-mode `ergoemacs-test-major-mode'.
Tests Issue #372."
  :tags '(:interactive)
  (ergoemacs-test-layout
   :layout "colemak"
   (let (ret
         (ergoemacs-use-function-remapping t))
     (with-temp-buffer
       (ergoemacs-test-major-mode)
       (when (not (current-local-map))
         (use-local-map ergoemacs-test-major-mode-map))
       (should (eq (key-binding (kbd "M-r")) 'other-window))))))

(ert-deftest ergoemacs-test-dired-sort-files ()
  "Test Issue #340"
  (add-hook 'dired-mode-hook (lambda ()
                               (interactive)
                               (make-local-variable  'dired-sort-map)
                               (setq dired-sort-map (make-sparse-keymap))
                               (define-key dired-mode-map "s" dired-sort-map)
                               (define-key dired-sort-map "s"
                                 '(lambda () "sort by Size"
                                    (interactive) (dired-sort-other (concat dired-listing-switches "-AlS --si --time-style long-iso"))))
                               (define-key dired-sort-map "."
                                 '(lambda () "sort by eXtension"
                                    (interactive) (dired-sort-other (concat dired-listing-switches "X"))))
                               (define-key dired-sort-map "t"
                                 '(lambda () "sort by Time"
                                    (interactive) (dired-sort-other (concat dired-listing-switches "t"))))
                               (define-key dired-sort-map "n"
                                 '(lambda () "sort by Name"
                                    (interactive) (dired-sort-other (concat dired-listing-switches ""))))
                               ;; Use "|", not "r".
                               (define-key dired-mode-map "|" 'dired-sort-menu-toggle-reverse)
                               ))
  (dired ergoemacs-dir)
  (should (equal (key-binding (kbd "s s")) '(lambda () "sort by Size" (interactive) (dired-sort-other (concat dired-listing-switches "-AlS --si --time-style long-iso")))))
  (should (equal (key-binding (kbd "s .")) '(lambda () "sort by eXtension" (interactive) (dired-sort-other (concat dired-listing-switches "X")))))
  (should (equal (key-binding (kbd "s t")) '(lambda () "sort by Time" (interactive) (dired-sort-other (concat dired-listing-switches "t")))))
  (should (equal (key-binding (kbd "s n")) '(lambda () "sort by Name" (interactive) (dired-sort-other (concat dired-listing-switches "")))))
  (should (equal (key-binding (kbd "|")) 'dired-sort-menu-toggle-reverse))
  (kill-buffer (current-buffer))
  (remove-hook 'dired-mode-hook (lambda ()
    (interactive)
    (make-local-variable  'dired-sort-map)
    (setq dired-sort-map (make-sparse-keymap))
    (define-key dired-mode-map "s" dired-sort-map)
    (define-key dired-sort-map "s"
      '(lambda () "sort by Size"
         (interactive) (dired-sort-other (concat dired-listing-switches "-AlS --si --time-style long-iso"))))
    (define-key dired-sort-map "."
      '(lambda () "sort by eXtension"
         (interactive) (dired-sort-other (concat dired-listing-switches "X"))))
    (define-key dired-sort-map "t"
      '(lambda () "sort by Time"
         (interactive) (dired-sort-other (concat dired-listing-switches "t"))))
    (define-key dired-sort-map "n"
      '(lambda () "sort by Name"
         (interactive) (dired-sort-other (concat dired-listing-switches ""))))
    ;; Use "|", not "r".
    (define-key dired-mode-map "|" 'dired-sort-menu-toggle-reverse)
    )))


(ert-deftest ergoemacs-test-quail-translations ()
  "Test if quail to ergoemacs-mode translations work."
  :tags '(:translate)
  (should (equal ergoemacs-layout-us (ergoemacs-translate--quail-to-ergoemacs (ergoemacs-translate-layout 'us :quail)))))

(ert-deftest ergoemacs-test-translate-bound ()
  "Make sure that bound keys are put in the `ergoemacs-map--'
hash appropriaetly."
  :tags '(:translate)
  (ergoemacs-test-layout
   :layout "colemak"
   (should (equal (ergoemacs-gethash (read-kbd-macro "M-r" t) ergoemacs-map--)
                  (ergoemacs-gethash (ergoemacs-translate--meta-to-escape (read-kbd-macro "M-r" t)) ergoemacs-map--)))))

(ert-deftest ergoemacs-test-table-insert ()
  "Tests that table can insert without hanging emacs."
  :tags '(:table)
  (save-excursion
    (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
    (delete-region (point-min) (point-max))
    (table-insert 1 2)
    (execute-kbd-macro (kbd "abc <tab> abc <tab>"))
    (should (string= (buffer-string) "+-----+
|abc  |
+-----+
|abc  |
+-----+
"))
    (kill-buffer (current-buffer))))

;; File variables
(ert-deftest ergoemacs-test-mouse-command-list-changes ()
  "Part of test for Sub issue described in #351"
  (should (equal '(&rest arg) (ergoemacs-command-loop--mouse-command-drop-first '(&rest arg) t)))
  (should (equal '(arg) (ergoemacs-command-loop--mouse-command-drop-first '(&rest arg))))
  (should (equal 'arg (ergoemacs-command-loop--mouse-command-drop-first '(&rest arg) :rest)))

  (should (equal nil (ergoemacs-command-loop--mouse-command-drop-first '(&rest arg) :drop-rest)))
  
  (should (equal nil (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg) t)))
  (should (equal nil (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg))))
  (should (equal nil (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg) :rest)))
  (should (equal nil (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg) :drop-rest)))

  (should (equal '(&optional arg2) (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 arg2) t)))
  (should (equal '(arg2) (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 arg2))))
  (should (equal nil (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 arg2) :rest)))
  (should (equal '(arg2) (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 arg2) :drop-rest)))

  (should (equal '(&rest arg2) (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 &rest arg2) t)))
  (should (equal '(arg2) (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 &rest arg2))))
  (should (equal 'arg2 (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 &rest arg2) :rest)))
  (should (equal nil (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 &rest arg2) :drop-rest)))

  (should (equal '(&optional arg2 &rest arg3) (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 arg2 &rest arg3) t)))
  (should (equal '(arg2 arg3) (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 arg2 &rest arg3))))
  (should (equal 'arg3 (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 arg2 &rest arg3) :rest)))
  (should (equal '(arg2) (ergoemacs-command-loop--mouse-command-drop-first '(&optional arg1 arg2 &rest arg3) :drop-rest))))


(ert-deftest ergoemacs-test-map-keymap-prefix ()
  "Tests mapping multiple keymaps defining a prefix."
  :tags '(:map-keymap)
  (let ((parent (make-sparse-keymap))
        (map (make-sparse-keymap))
        list)
    (define-key parent [27 ?a] 'ignore)
    (define-key map [27 ?b] 'ignore)
    (set-keymap-parent map parent)
    (ergoemacs-map-keymap
     (lambda(key item)
       (unless (or (eq item 'ergoemacs-prefix)
                   (consp key)
                   (equal key [ergoemacs-labeled]))
         (push key list)))
     map)
    (should (member [27 ?a] list))
    (should (member [27 ?b] list))
    list))

(ert-deftest ergoemacs-test-temp-map-issue ()
  "Test temporary map issue."
  (if (version-list-< (version-to-list "24.4") (version-to-list emacs-version))
      (ergoemacs-test-layout
       :layout "colemak"
       :macro "M-8 M-SPC M-SPC M-i"
       (save-excursion
	 (switch-to-buffer (get-buffer-create "*ergoemacs-test*"))
	 (delete-region (point-min) (point-max))
	 (insert ergoemacs-test-lorem-ipsum)
	 (goto-char (point-max))
	 (beginning-of-line)
	 (execute-kbd-macro macro)
	 (should (eq (key-binding (kbd "8")) 'self-insert-command))
	 (kill-buffer (current-buffer)))))
  (should t))

;;; minibuffer tests...
;;; Related to: http://emacs.stackexchange.com/questions/10393/how-can-i-answer-a-minibuffer-prompt-from-elisp

(defmacro ergoemacs-minibuffer-key-bindings (minibuffer-call &rest keys)
  "Setup minibuffer with MINIBUFFER-CALL, and lookep KEYS."
  `(catch 'found-key
       (minibuffer-with-setup-hook
	   (lambda ()
	     (run-with-timer
	      0.05 nil
	      (lambda()
		(throw 'found-key (mapcar (lambda(key) (if (consp key)
                                                           (key-binding (eval key))
                                                         (key-binding key)))
					  ',keys)))))
	 ,minibuffer-call)
       nil))

(provide 'ergoemacs-test)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ergoemacs-test.el ends here
;; Local Variables:
;; coding: utf-8-emacs
;; End:
