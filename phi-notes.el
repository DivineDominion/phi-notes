; phi-notes.el - by Bruno Conte, bruno@brunoc.com.br, 2021
                                        ;

;; Core Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar phi-file-header-annotation
  "\
---
title:		'%s'   
id:			Φ%s  
citekey:		%s  
loc:			%s  
tags:		%s
...

")

(defvar phi-file-header-common
  "\
---
title:		'%s'   
id:			Φ%s  
tags:		%s
...

")



;; Options

(defgroup phi ()
  "Tools for phi notes"
  :group 'tools)


(defcustom phi-header-pre
  "\
---
title:		'%s'   
id:			Φ%s  
"
  "First part of YAML header"
  :type 'string
  :group 'phi)

(defcustom phi-header-post
  "\
tags:		%s
...

"
  "Final part of YAML header"
  :type 'string
  :group 'phi)


(defcustom phi-notes-path "~/phi"
  "Path for note files"
  :type 'string
  :group 'phi)

(defcustom phi-counter-path "~/phi/.phi_counter"
  "Path for counter file"
  :type 'string
  :group 'phi)

(defcustom phi-originating-symbol "○"
  "Symbol for a originating note's breadcrumb"
  :type 'string
  :group 'phi)

(defcustom phi-parent-symbol "△"
  "Symbol for parent note in breadcrumb"
  :type 'string
  :group 'phi)

(defcustom phi-child-symbol "▽"
  "Symbol for children notes breadcrumb"
  :type 'string
  :group 'phi)

(defcustom phi-tags-field "tags"
  "Field in YAML header for tags"
  :type 'string
  :group 'phi)

(defcustom phi-loc-field "loc"
  "Field in YAML header for location"
  :type 'string
  :group 'phi)

(defcustom phi-citekey-field "citekey"
  "Field in YAML header for cite key"
  :type 'string
  :group 'phi)


(defcustom phi-breadcrumb t
  "Create breadcrumbs"
  :type 'boolean
  :group 'phi)

(defcustom phi-link-left-bracket-symbol "[["
  "Symbol for left bracket"
  :type 'string
  :group 'phi)


(defcustom phi-link-right-bracket-symbol "]]"
  "Symbol for right bracket"
  :type 'string
  :group 'phi)

(defcustom phi-link-left-bracket-symbol-re "\\[\\["
  "RegEx for left bracket"
  :type 'string
  :group 'phi)


(defcustom phi-link-right-bracket-symbol-re "\\]\\]"
  "RegEx for right bracket"
  :type 'string
  :group 'phi)



(defcustom phi-id-regex "[0-9]\\{4,\\}"
  "Regular expression for valid note id"
  :type 'string
  :group 'phi)

(defcustom phi-id-format "%04d"
  "Zero-padded format for note id"
  :type 'string
  :group 'phi)

(defcustom phi-tag-symbol "#"
  "Symbol to prepend tags"
  :type 'string
  :group 'phi)


(defcustom phi-default-file-extension "markdown"
  "Default file extension for notes"
  :type 'string
  :safe 'stringp
  :group 'phi)


(defcustom phi-annotation-tag "ƒ"
  "Tag for the identification of annotation notes"
  :type 'string
  :group 'phi)


(defcustom phi-switch-to-buffer nil
  "Switch to buffer when a new note is created"
  :type 'bool
  :group 'phi)


(defcustom phi-mode-lighter "Φ"
  "Mode-line indicator for `phi-mode'."
  :type '(choice (const :tag "No lighter" "") string)
  :safe 'stringp
  :group 'binder)


;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun phi-get-counter ()
  "Increment and return current counter"
  (let (counter)
    (with-temp-buffer
      (insert-file-contents phi-counter-path)
      (setq counter (format phi-id-format (1+ (string-to-number (buffer-string))))))
    (with-temp-file phi-counter-path
      (insert counter))
    counter
    ))

(defun phi-construct-breadcrumb (&optional parent)
  "Construct the breadcrumb for a new note"
  (if parent
      (concat phi-parent-symbol phi-link-left-bracket-symbol
              parent phi-link-right-bracket-symbol)
    (concat phi-originating-symbol)))

(defun phi-get-current-note-id ()
  "Get the current note id"
  (interactive)
  (let ((filename (file-name-nondirectory buffer-file-name)))
    (string-match (concat "^" phi-id-regex) filename)
    (match-string 0 filename)))

(defun phi-get-parent-note-id ()
  "Return the id for the parent note"
  (save-excursion
    (goto-char (point-min))
    (if (and (re-search-forward (concat "^" phi-parent-symbol) nil t)
             (looking-at (concat phi-link-left-bracket-symbol-re
                                 "\\(" phi-id-regex "\\)" phi-link-right-bracket-symbol-re)))
        (match-string-no-properties 1))))


(defun phi-get-note-field-contents (field)
  "Return the specified field contents for the current note"
  (save-excursion
    (goto-char (point-min))
    (if  (and (re-search-forward (concat "^" field ":\\s-*") nil t)
              (looking-at (concat ".*$")))
        (match-string-no-properties 0))))

(defun phi-create-common-note (id title &optional parent tags citekey loc)
  "Create a common note buffer"
  (interactive)
  (with-current-buffer (generate-new-buffer "New PHI Note")
    (insert (format phi-header-pre
                    title id))
    (when citekey (insert (concat phi-citekey-field ":\t" citekey "  ")))
    (when loc (insert (concat phi-loc-field ":\t" loc "  ")))
    (insert (format phi-header-post tags))
    (insert (phi-construct-breadcrumb parent))
    (insert "\


")
    (write-file (concat phi-notes-path "/" id " " title "." phi-default-file-extension))
    (phi-mode)
    (current-buffer)))

(when "" "3")

(defun phi-new-common-note ()
  "Generate a new common note"
  (interactive)
  (let ((id (phi-get-counter))
        (parent (phi-get-current-note-id))
        (title (read-string "title: "))
        (tags (read-string "tags: " (phi-get-note-field-contents phi-tags-field)))
        (citekey (read-string "citekey: " (phi-get-note-field-contents phi-citekey-field)))
        (loc (read-string "loc: " (phi-get-note-field-contents phi-loc-field)))
        (buffer nil)
        (w nil))
    (setq buffer (phi-create-common-note id title parent tags
                                         (unless (string= citekey "") citekey) (unless (string= loc "") loc)))
    (insert (concat title " " phi-link-left-bracket-symbol id phi-link-right-bracket-symbol))
    (setq w (selected-window))
    (if phi-switch-to-buffer
        (switch-to-buffer buffer)
      (pop-to-buffer buffer)
      (select-window w))))


(defun phi-matching-file-name (id)
  "Return the first match of a file name starting with id"
  (nth 0 (file-name-all-completions id phi-notes-path)))


;; Sidebar ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgroup phi-sidebar ()
  "Options for `phi-sidebar-mode'."
  :group 'phi)

(defcustom phi-sidebar-resize-window-step
  4
  "Integer of columns by which to resize window.
Used by `phi-sidebar-shrink-window' and `phir-sidebar-enlarge-window'."
  :type 'integer
  :safe 'integerp
  :group 'phi-sidebar)

(defcustom phi-sidebar-text-scale-set
  0
  "Text scale for sidebar buffer"
  :type 'integer
  :group 'phi-sidebar)

(defcustom phi-sidebar-display-alist
  '((side . left)
    (window-width . 45)
    (slot . -1))
  "Association list used to display PHI sidebar buffer.
See `display-buffer-in-side-window' for example options."
  :type 'alist
  :safe (lambda (value)
          (and (listp value)
               (seq-every-p 'consp value)))
  :group 'phi-sidebar)

(defcustom phi-sidebar-persistent-window
  t
  "When non-nil, sidebar will persist when calling `delete-other-windows'.
This marks `no-delete-other-windows' window parameter as non-nil.
Use `phi-toggle-sidebar' or `quit-window' to close the sidebar."
  :type 'boolean
  :safe 'booleanp
  :group 'phi-sidebar)

(defcustom phi-sidebar-olivetti-width
  38
  "olivetti-mode column width for sidebar buffer"
  :type 'integer
  :group 'phi-sidebar)

(defvar phi-sidebar-buffer nil)

(defun phi-sidebar-adjust-buffer (buffer)
  (with-current-buffer buffer
    (phi-mode)
    (if phi-sidebar-olivetti-width
        (olivetti-set-width phi-sidebar-olivetti-width))
    (text-scale-set phi-sidebar-text-scale-set)
    (phi-buttonize-buffer))
  buffer)

(defun phi-sidebar-create-buffer (id)
  (setq phi-sidebar-buffer (phi-sidebar-adjust-buffer
                            (find-file-noselect (phi-matching-file-name id)))))

(defun phi-sidebar-create-window (id)
  (display-buffer-in-side-window (phi-sidebar-create-buffer id)
                                 (append phi-sidebar-display-alist
                                         (when phi-sidebar-persistent-window
                                           (list '(window-parameters (no-delete-other-windows . t)))))))

(defun phi-sidebar-with-parent ()
  "Open PHI Sidebar with parent note"
  (interactive)
  (phi-sidebar-create-window (phi-get-parent-note-id)))

(defun phi-toggle-sidebar ()
  "Toggle visibility of PHI Sidebar"
  (interactive)
  (unless phi-sidebar-buffer
    (phi-sidebar-create-buffer (phi-get-parent-note-id)))
  (if (window-live-p (get-buffer-window phi-sidebar-buffer))
      (delete-window (get-buffer-window phi-sidebar-buffer))
    (phi-sidebar-with-parent)))


(define-button-type 'phi-linked-note
  'follow-link t
  'action #'phi-find-file-button)

(defun phi-find-file-button (button)
  (let ((buffer (find-file-noselect (phi-matching-file-name
                                     (buffer-substring (button-start button) (button-end button))))))
    (pop-to-buffer buffer)
    (phi-mode)
    (if phi-sidebar-persistent-window (delete-other-windows))))

(defun phi-buttonize-buffer ()
  "Turn all wiki links into buttons"
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward
            (concat phi-link-left-bracket-symbol-re
                    "\\(" phi-id-regex "\\)" phi-link-right-bracket-symbol-re) nil t)
      (make-button (match-beginning 1) (match-end 1) :type 'phi-linked-note))))

(defvar phi-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c ;") #'phi-toggle-sidebar)
    (define-key map (kbd "C-c n d") #'phi-new-common-note)
    map)
  "Main mode map for `phi-mode'.")

(define-minor-mode phi-mode
  "PHI note minor mode"
  :lighter phi-mode-lighter
  :keymap phi-mode-map
  )

(provide 'phi-notes)


