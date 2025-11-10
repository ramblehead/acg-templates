;; Hey Emacs, this is -*- coding: utf-8 -*-

(require 'hydra)
(require 'prettier)
(require 'blacken)
(require 'flycheck)
(require 'lsp-mode)
(require 'lsp-pyright)
(require 'lsp-ruff)
(require 'lsp-rust)
(require 'vterm)

(define-minor-mode acg-templates-mode
  "acg-templates project-specific minor mode."
  :lighter " acg-templates")

(add-to-list 'rm-blacklist " acg-templates")

(defun acg-templates/lsp-javascript-deps-providers-path (relative-path)
  (let ((path-hop
         (expand-file-name
          (file-name-concat (rh-project-get-root)
                            "node_modules/.bin" relative-path))))
    path-hop))

(defun acg-templates/lsp-javascript-setup ()
  ;; (setq-local lsp-deps-providers (copy-tree lsp-deps-providers))

  (plist-put
   lsp-deps-providers
   :acg-templates/local-npm
   (list :path #'acg-templates/lsp-javascript-deps-providers-path))

  (lsp--require-packages)

  (lsp-dependency 'typescript-language-server
                  '(:acg-templates/local-npm
                    "typescript-language-server"))

  (lsp-dependency 'tailwindcss-language-server
                  '(:acg-templates/local-npm
                    "tailwindcss-language-server"))

  (lsp-dependency 'typescript
                  '(:acg-templates/local-npm "tsserver"))

  (add-hook
   'lsp-after-initialize-hook
   #'acg-templates/flycheck-add-eslint-next-to-lsp))

(defun acg-templates/flycheck-after-syntax-check-hook-once ()
  (remove-hook
   'flycheck-after-syntax-check-hook
   #'acg-templates/flycheck-after-syntax-check-hook-once
   t)
  (flycheck-buffer))

(defun acg-templates/flycheck-add-eslint-next-to-lsp ()
  (when (seq-contains-p '(js2-mode typescript-mode web-mode) major-mode)
    (flycheck-add-next-checker 'lsp 'javascript-eslint)))

(defun acg-templates/lsp-python-deps-providers-path (relative-path)
  (let ((hop-root
         (expand-file-name
          (file-name-concat (rh-project-get-root)
                            ".venv/bin" relative-path)))
        (project-root
         (expand-file-name
          (file-name-concat (rh-project-get-root)
                            "hop" ".venv/bin" relative-path))))
    (if (file-exists-p hop-root)
        hop-root
      project-root)))

(defun acg-templates/lsp-python-setup ()
  (plist-put
   lsp-deps-providers
   :acg-templates/local-venv
   (list :path #'acg-templates/lsp-python-deps-providers-path))

  (lsp-dependency 'pyright
                  '(:acg-templates/local-venv
                    "basedpyright-langserver")))

(eval-after-load 'lsp-javascript
  #'acg-templates/lsp-javascript-setup)

(eval-after-load 'lsp-pyright
  #'acg-templates/lsp-python-setup)

(defun acg-templates-setup ()
  (when buffer-file-name
    (let ((hop-root (expand-file-name (rh-project-get-root)))
          project-root)
      (when hop-root
        (setq project-root (file-name-concat hop-root "hop"))

        (cond
         ;; This is required as tsserver does not work with files in archives
         ((bound-and-true-p archive-subfile-mode)
          (company-mode 1))

         ((or (string-match-p "\\.py\\'\\|\\.pyi\\'" buffer-file-name)
              (string-match-p "^#!.*python"
                              (or (save-excursion
                                    (goto-char (point-min))
                                    (thing-at-point 'line t))
                                  "")))

          ;;; /b/; pyright-lsp config
          ;;; /b/{

          ;; (lsp-workspace-folders-add project-root)
          ;; Adding additional project-root non-persistent
          (cl-pushnew (lsp-f-canonical project-root)
                      (lsp-session-folders (lsp-session)) :test 'equal)

          ;; (setq-local lsp-pyright-venv-path project-root)
          ;; (setq-local lsp-pyright-venv-directory ".venv")

          (setq-local lsp-pyright-prefer-remote-env nil)
          (setq-local lsp-pyright-langserver-command "basedpyright")
          (setq-local lsp-pyright-python-executable-cmd
                      (file-name-concat project-root ".venv/bin/python"))

          ;; (setq-local lsp-pyright-venv-path
          ;;             (file-name-concat project-root ".venv"))
          ;; (setq-local lsp-pyright-python-executable-cmd "poetry run python")
          ;; (setq-local lsp-pyright-langserver-command-args
          ;;             `(,(file-name-concat project-root ".venv/bin/pyright")
          ;;               "--stdio"))
          ;; (setq-local lsp-pyright-venv-directory
          ;;             (file-name-concat project-root ".venv"))

          ;;; /b/}

          ;;; /b/; ruff-lsp config
          ;;; /b/{

          (setq-local lsp-ruff-server-command
                      `(,(file-name-concat project-root ".venv/bin/ruff")
                        "server"))
          (setq-local lsp-ruff-python-path
                      (file-name-concat project-root ".venv/bin/python"))

          ;;; /b/}

          ;;; /b/; Python black
          ;;; /b/{

          (setq-local blacken-executable
                      (file-name-concat project-root ".venv/bin/black"))

          ;;; /b/}

          (setq-local lsp-enabled-clients '(pyright ruff))
          ;; (setq-local lsp-enabled-clients '(pyright))
          ;; (setq-local lsp-enabled-clients '(ruff))
          (setq-local lsp-before-save-edits nil)
          (setq-local lsp-modeline-diagnostics-enable nil)

          (blacken-mode 1)
          ;; (run-with-idle-timer 0 nil #'lsp)
          (lsp-deferred))

         ((string-match-p "\\.rs\\'" buffer-file-name)

          ;;; /b/; rustfmt config
          ;;; /b/{

          (setq-local rust-format-on-save t)

          ;;; /b/}

          ;;; /b/; LSP config
          ;;; /b/{

          (setq-local lsp-rust-analyzer-cargo-watch-command "clippy")
          (setq-local lsp-rust-clippy-preference "on")

          (let ((lsp-rust-analyzer-linked-projects-copy
                 (seq-copy lsp-rust-analyzer-linked-projects)))
            (setq-local
             lsp-rust-analyzer-linked-projects
             (seq-concatenate
              'vector
              lsp-rust-analyzer-linked-projects-copy
              (vector (file-name-concat
                       project-root
                       "external/qkd-declarations-core/Cargo.toml")))))

          ;;; /b/}

          (lsp-deferred))

         ((string-match-p "\\.toml\\'" buffer-file-name)
          (prettier-mode 1))

         ((string-match-p "\\.json\\'" buffer-file-name)
          (prettier-mode 1))

         ((string-match-p "\\.yml\\'\\|\\.yaml\\'" buffer-file-name)
          (prettier-mode 1))

         ((string-match-p "\\.js\\'" buffer-file-name)
          (prettier-mode 1))

         ((string-match-p "\\.md\\'" buffer-file-name)
          (prettier-mode 1)))))))

;;; /b/}
