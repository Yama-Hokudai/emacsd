;;; init.el --- My Emacs Configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;; =====================================================================
;;; Emacs init.el
;;; =====================================================================

;;; Code:
;;; 1.Package Management

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(declare-function straight-use-package "straight")
(defvar straight-use-package-by-default)
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)


;;; 2. Basic Customize

;;;; 2-1. General Configs
(use-package emacs
  :init
  ;; Emacs 28 以降で推奨される書き方
  (setq use-short-answers t)
  ;; yes/no を y/n で回答できるようにする
					; (fset 'yes-or-no-p 'y-or-n-p)
  ;; Region選択中に C-d で削除
  (setq delete-active-region t)
  ;; 選択範囲がある状態で入力を始めると、範囲を消去して上書きする
  (delete-selection-mode 1)
  ;; スクロール設定（一行ずつ）
  (setq scroll-step 1)
  (setq scroll-conservatively 10000)
  ;; スクロール時にカーソル位置を固定する設定
  (setq scroll-preserve-screen-position t)
  ;; :config
  ;; ロード後に実行される

  :bind
  ;; キーバインドの一括設定
  (("C-h" . delete-backward-char)
   ("C-u" . my-backward-kill-line)
   ("M-n" . scroll-up-line)
   ("M-p" . scroll-down-line)
   ("M-;" . comment-line)
   ("C-M-\\" . my-indent-region-or-line)
   ("M-?" . help-command)
   ("C-c e" . eval-buffer))

  :config
  (defun my-backward-kill-line ()
    "カーソル位置から行頭までをキルする"
    (interactive)
    (kill-line 0))

  (defun my-indent-region-or-line ()
    "Regionが選択されていれば indent-region を、そうでなければ現在の行をインデントする。"
    (interactive)
    (if (use-region-p)
	(call-interactively 'indent-region)
      (indent-for-tab-command)))

  (defun osx-paste-from-clipboard ()
    "macOSのクリップボード（pbpaste）から直接テキストを挿入します。"
    (interactive)
    ;; pbpaste コマンドの出力をそのままバッファに挿入（文字コードは一括で安全に処理されます）
    (let ((coding-system-for-read 'utf-8))
      (insert (shell-command-to-string "pbpaste"))))

  ;; ターミナル環境（CUI）のときだけ、使いやすいショートカットキーに割り当て
  (unless (display-graphic-p)
    ;; 例： C-c C-y (Control + C を押した後に Control + Y)
    (global-set-key (kbd "C-c C-y") 'osx-paste-from-clipboard))

;;; 存在しないディレクトリにファイルを保存しようとした時、自動で親ディレクトリを作成する
  (add-hook 'before-save-hook
            (lambda ()
              (when buffer-file-name
		(let ((dir (file-name-directory buffer-file-name)))
                  (unless (file-exists-p dir)
                    ;; 確認を出したい場合は以下の行のコメントを外し、make-directory を (when (y-or-n-p ...) の中に入れます
                    ;; (when (y-or-n-p (format "ディレクトリ %s が存在しません。作成しますか？ " dir))
                    (make-directory dir t))))))

  )

;;;; 2-2. 環境変数の確実なパス解決とOS切り替え機構 (exec-path-from-shell)
(use-package exec-path-from-shell
  :straight t
  :config
  ;; OS（Linux、Mac、Windowsなど）の差異を `system-type` 等で判定する切り替え機構。
  ;; GUIのEmacsからターミナルの環境変数（PATH）を正しく引き継ぎ、
  ;; LSPサーバー（clangdなど）が見つからないトラブルを未然に防ぎます。
  ;; ※Windows環境では動作不要かつエラーの原因になるため除外します。
  (when (and (not (eq system-type 'windows-nt))
             (memq window-system '(mac ns x pgtk)))
    (exec-path-from-shell-initialize)))

;;;; 2-3. Highlighting the region yanked
(use-package volatile-highlights
  :straight t
  :config
  (volatile-highlights-mode t))

;;; 3. Mini-buffer completion

;;;; 3-1. vertico
;;;; ミニバッファの候補を縦一列に美しく表示
(use-package vertico
  :straight t
  :init
  (vertico-mode 1)
  :config
  ;; 候補表示の行数（お好みで調整してください）
  (setq vertico-count 15)
  ;; 候補をループできるようにする (最下部でさらに下にいくと最上部に戻る)
  (setq vertico-cycle t)
  :bind
  (:map vertico-map
        ("TAB" . vertico-next)       ; TABで次の候補へ
        ([tab] . vertico-next)
        ("<backtab>" . vertico-previous) ; Shift+TABで前の候補へ
        ("S-TAB" . vertico-previous)))


;;;; 3-2. orderless
;;;; Orderless: スペース区切りで「順不同」の爆速絞り込みを実現
(use-package orderless
  :straight t
  :init
  ;; Emacs標準の補完スタイルに orderless を割り当て
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

;;;; 3-3. marginalia
;;;; Marginalia: 補完候補の右側にファイルサイズやモードなどの詳細情報を付与
(use-package marginalia
  :straight t
  :init
  (marginalia-mode 1))

;;;; 3-4. consult
;;;; 高度な検索・ナビゲーションとライブプレビュー
(use-package consult
  :straight t
  ;; よく使う標準コマンドを consult の拡張版に置き換える
  :bind (("C-x b" . consult-buffer)         ; バッファ/最近のファイル/ブックマークを統合検索
         ("C-x 4 b" . consult-buffer-other-window) ; 別ウィンドウでバッファを開く
         ("C-s" . consult-line)             ; インクリメンタル行検索（標準のisearchを上書き）
         ("M-s l" . consult-line)           ; M-s プレフィックスからの行検索
         ("M-i" . consult-imenu)            ; 見出しジャンプ（既存の imenu を上書き）
         ("M-y" . consult-yank-pop)         ; コピー(kill-ring)履歴のプレビュー付き検索
         ("M-g g" . consult-goto-line)      ; プレビュー付きの行番号ジャンプ
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline)        ; アウトライン（見出し）検索
         ("M-g m" . consult-mark))          ; マーク位置へのジャンプ
  :custom
  ;; ライブプレビューのトリガー設定（'any は入力のたびに即時プレビュー）
  ;; ※もし巨大なファイルでプレビューが重い場合は (list :debounce 0.5 'any) などに遅延設定も可能
  (consult-preview-key 'any))

;;; 4. Navigation
;;; =====================================================================
;;; 拡張ナビゲーション (標準 Imenu のカスタマイズ)
;;; =====================================================================
(use-package imenu
  :bind
  ("M-i" . imenu)
  :custom
  ;; 1. Imenu自身のソート機能をオフにし、バッファ内の出現順にする [1]
  (imenu-sort-function nil)
  :hook
  ;; 【追加】ジャンプした直後にカーソル位置を画面の最上部（0行目）に合わせる
  (imenu-after-jump . (lambda () (recenter 0)))
  :init
  (declare-function my-init-el-imenu-create-index "imenu")
  (add-hook 'emacs-lisp-mode-hook
            (lambda ()
              (when (string-match-p "init\\.el$" (buffer-name))
                (setq-local imenu-create-index-function #'my-init-el-imenu-create-index))))
  :config
  ;; 2. 補完UI（Vertico等）が Imenu のリストを勝手にソートしないようにする [1, 2]
  (add-to-list 'completion-category-overrides '(imenu (display-sort-function . identity)))
  ;; init.el 専用のカスタムインデックス生成関数
  (defun my-init-el-imenu-create-index ()
    "init.el 内の ';;; 1.title' (大見出し) と ';;;; 1-1.title' (小見出し) をパースし、
階層的な Imenu インデックスを生成する関数。"
    (let ((index-alist nil)
          (current-parent-name nil)
          (current-sublist nil))
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward "^;;;\\(;?\\) +\\([1-9]+\\(?:-[1-9]+\\)?\\..*\\)$" nil t)
          (let ((level (if (string= (match-string 1) ";") 2 1))
                (name  (string-trim (match-string 2)))
                (pos   (match-beginning 0)))
            (if (= level 1)
                ;; 【変更】大見出しの場合
                (progn
                  (when current-parent-name
                    (if (= (length current-sublist) 1)
                        ;; 小見出しがない場合は、直接ジャンプできる形式で登録
                        (push (cons current-parent-name (cdr (car current-sublist))) index-alist)
                      ;; 小見出しがある場合は、今まで通り階層リストとして登録
                      (push (cons current-parent-name (nreverse current-sublist)) index-alist)))
                  (setq current-parent-name name)
                  (setq current-sublist (list (cons "📍 ブロック冒頭へ" pos))))
              ;; 小見出しの場合
              (if current-parent-name
                  (push (cons name pos) current-sublist)
                (push (cons name pos) index-alist))))))
      ;; 【変更】最後の大見出しグループをリストに追加する際の処理も同様に変更
      (when current-parent-name
        (if (= (length current-sublist) 1)
            (push (cons current-parent-name (cdr (car current-sublist))) index-alist)
          (push (cons current-parent-name (nreverse current-sublist)) index-alist)))
      (nreverse index-alist))))

;;; 5. Terminal Integration
;; =====================================================================
;; ターミナル環境の統合とデバッガ連携
;; =====================================================================
(use-package eshell
  :bind (("C-c s" . eshell))) ;; いつでもeshellを呼び出すキー


;;; 6. Coding & Display
;;;; 6-1. Highlighting Space
(use-package whitespace
  :diminish
  :hook (prog-mode . whitespace-mode)
  :config
  ;; 1. ハイライトの対象から 'spaces を外す（これで半角スペースが反応しなくなります）

  (setq whitespace-style '(face        ; 色を付ける
                           trailing    ; 行末の空白
                           tabs        ; タブ
                           space-mark)) ; 記号表示（全角スペース用）

  ;; 2. 全角スペースのみを「space-mark」として認識させる
  (setq whitespace-space-regexp "　+")

  ;; 3. 表示の色設定
  (set-face-attribute 'whitespace-space nil
                      :background "OrangeRed"
                      :foreground "white"
                      :underline t)

  ;; 4. タブの色設定（ついでに、タブも目立たせすぎないように薄くする場合）
  (set-face-attribute 'whitespace-tab nil
                      :background 'unspecified
                      :foreground "gray30"
                      :strike-through t))

;;;; 6-2. Undo tree
;;
(use-package undo-tree
  :straight t
  :init
  (global-undo-tree-mode 1)
  :custom
  ;; 1. 履歴ファイルの自動保存を明示的に有効化
  (undo-tree-auto-save-history t)
  ;; 2. 履歴ファイルの散乱防止：すべてのファイルを一括ディレクトリへ
  (undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo-tree-history/")))
  ;; 3. パフォーマンス最適化：巨大なツリーの描画を遅延させる
  (undo-tree-visualizer-lazy-drawing t)
  ;; 4. UIのデフォルト設定（最初からタイムスタンプとdiffを表示）
  (undo-tree-visualizer-timestamps t)
  (undo-tree-visualizer-diff t)
  ;; 5. ツリー画面でのキャンセル操作 (C-g) の割り当て
  :bind (:map undo-tree-visualizer-mode-map
	      ("RET" . undo-tree-visualizer-quit)
              ;; C-g を押すと「ツリーを開いた時点の状態に戻して」終了する（※ソース外情報）
              ("C-g" . undo-tree-visualizer-abort))

  :config
  ;; 保存先ディレクトリが存在しない場合はEmacs起動時に自動作成
  (let ((undo-dir (expand-file-name "undo-tree-history" user-emacs-directory)))
    (unless (file-exists-p undo-dir)
      (make-directory undo-dir t))))

;;;; 6-3. corfu (バッファ内のポップアップ補完UI)
(use-package corfu
  :custom
  (corfu-auto t)               ; タイピング中の自動補完を有効化
  (corfu-auto-delay 0.05)      ; 補完ポップアップまでの遅延を極限まで短く (0.05秒)
  (corfu-auto-prefix 1)        ; 1文字入力しただけで補完を開始
  (corfu-cycle t)              ; 候補リストの末尾と先頭をループさせる
  (corfu-preselect 'prompt)    ; 勝手に最初の候補を選択せず、自分の入力を優先
  (corfu-separator ?\s)        ; ← 追加: セパレータを半角スペースとして扱う
  :init
  (global-corfu-mode)
  :bind
  (:map corfu-map
        ("TAB" . corfu-next)       ; TABで次の候補へ
        ([tab] . corfu-next)
        ("<backtab>" . corfu-previous) ; Shift+TABで前の候補へ
        ("S-TAB" . corfu-previous)
	("SPC" . corfu-insert-separator)))         ; 全てのバッファ（Elispや将来のLSP含む）で有効

;; ターミナル（CUI）環境でのみ corfu-terminal をロードして有効化
(use-package corfu-terminal
  :unless (display-graphic-p) ; GUI環境でない場合のみ実行
  :straight t
  :init
  (corfu-terminal-mode +1))

;;;; 6-4. flymake (標準搭載のリアルタイム構文チェック)
(use-package flymake
  ;; ※ Emacs標準機能のため :straight t は不要です
  :hook
  ;; とりあえず Elisp を書くときだけ自動有効化しておく
  (emacs-lisp-mode . flymake-mode)
  :bind
  ;; エラー箇所へジャンプするキーバインド
  (("M-g n" . flymake-goto-next-error)
   ("M-g p" . flymake-goto-prev-error)))

;;; 7. AI Integration
;; =====================================================================
;; 🤖 バイブコーディング（AI主導開発）環境設定
;; =====================================================================

;; t "バイブコーディング機能（gptel連携）を有効にするフラグ。"
(defvar my/enable-vibe-coding t)

(use-package gptel
  :straight t
  :if my/enable-vibe-coding  ;; フラグが nil の時は、インストールもロードも完全にスキップ
  :bind (("C-c g g" . gptel)          ; 独立したチャットバッファを開く
         ("C-c g r" . gptel-rewrite)  ; 選択範囲のコードをインラインで書き換え・修正
         ("C-c g s" . gptel-send))   ; 現在のバッファ、または選択範囲をAIに送信
  :config
  ;; デフォルトのモデル（通常時）を Gemini に設定
  (setq gptel-backend
	(gptel-make-openai "LM Studio"
	  :host "localhost:1234"
	  :protocol "http"
	  :key "lm-studio"
	  :stream t))
  (setq-default gptel-backend gptel-backend))

;;; 8. C/C++ Development Environment
;; =====================================================================
;; LSP(eglot)を利用したコーディング支援とOS切り替え機構
;; =====================================================================

;; パスの引き継ぎは，2. Basic Customization に移行済み

;;;; 8-1. LSPクライアント (eglot) と Clangd 連携
(use-package eglot
  :hook ((c-mode . eglot-ensure)
         (c++-mode . eglot-ensure))
  :bind (:map eglot-mode-map
              ("C-c l a" . eglot-code-actions)
              ("C-c l r" . eglot-rename)
              ("C-c l f" . eglot-format)))

;;;; 8-2. CMakeモードとプロジェクト構築のカスタムフロー
(use-package cmake-mode
  :straight t
  :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'")
  :bind (("C-c c" . my-cmake-compile)
         ("C-c r" . my-cmake-run))  ;; ★追加: 自動ビルド＆実行コマンド
  :hook ((c-mode . my-setup-cmake-project-on-new-file)
         (c++-mode . my-setup-cmake-project-on-new-file))
  :config

  ;; --- 1. プロジェクト作成コマンド（既存ファイル開始 兼 新規ファイルフック用） ---
  (defun my-cmake-project-create ()
    "CMakeプロジェクトの初期化（git init, build作成, CMakeLists.txt作成）を行う"
    (interactive)
    (let ((dir default-directory))
      ;; (1) git init の実行
      (unless (locate-dominating-file dir ".git")
        (shell-command "git init")
        (message "Git リポジトリを初期化しました。"))
      ;; (2) build ディレクトリの作成
      (let ((build-dir (expand-file-name "build" dir)))
        (unless (file-exists-p build-dir)
          (make-directory build-dir t)
          (message "build ディレクトリを作成しました。")))
      ;; (3) CMakeLists.txt の作成（裏側で生成してメインに留まる）
      (let ((cmake-file (expand-file-name "CMakeLists.txt" dir))
            (src-file (if buffer-file-name (file-name-nondirectory buffer-file-name) "main.cpp")))
        (if (file-exists-p cmake-file)
            (message "CMakeLists.txt は既に存在します。")
          (let ((cmake-version "3.15")
                (proj-name "MyProject")
                (aborted nil))
            ;; ミニバッファでの入力処理。C-g の例外をキャッチしてスキップを実現
            (condition-case nil
                (progn
                  (let ((input (read-string (format "CMake VERSION (default %s) [q to skip]: " cmake-version) nil nil cmake-version)))
                    (if (string= input "q")
                        (setq aborted t)
                      (setq cmake-version input)))
                  (unless aborted
                    (let ((input (read-string (format "Project Name (default %s) [q to skip]: " proj-name) nil nil proj-name)))
                      (if (string= input "q")
                          (setq aborted t)
                        (setq proj-name input)))))
              (quit (message "入力をスキップしました。デフォルト値を使用して生成します。")))
            ;; バックグラウンドで CMakeLists.txt を生成
            (with-temp-file cmake-file
              (insert (format "cmake_minimum_required(VERSION %s)\n" cmake-version))
              (insert (format "project(%s)\n\n" proj-name))
              (insert "# LSP(Clangd)連携用の設定\n")
              (insert "set(CMAKE_EXPORT_COMPILE_COMMANDS ON)\n\n")
              (insert "# 1. 自作ライブラリの定義\n")
              (insert "# add_library(my_library STATIC my_lib.cpp)\n")
              (insert "# target_compile_features(my_library PRIVATE cxx_std_20)\n\n")
              (insert "# 2. 実行ファイルの定義\n")
              (insert (format "add_executable(%s %s)\n" proj-name src-file))
              (insert (format "target_compile_features(%s PRIVATE cxx_std_20)\n\n" proj-name))
              (insert "# 3. リンクの指定\n")
              (insert (format "# target_link_libraries(%s PRIVATE my_library)\n" proj-name)))
            (message "CMakeLists.txt を生成しました。%s の編集を開始します。" src-file))))))

  ;; --- 2. 新規ファイル作成時のフック ---
  (defun my-setup-cmake-project-on-new-file ()
    "新規C/C++ファイルを開いた際にプロジェクトセットアップを促す"
    (when (and buffer-file-name (not (file-exists-p buffer-file-name)))
      (unless (locate-dominating-file default-directory "CMakeLists.txt")
        (when (y-or-n-p "CMakeプロジェクトが見つかりません。新規プロジェクトとして初期化しますか？ ")
          (my-cmake-project-create)))))

  ;; --- 3. コンパイルコマンド ---
  (defun my-cmake-compile ()
    "buildディレクトリへ移動し、cmake .. と make を実行する"
    (interactive)
    (let* ((proj-dir (or (locate-dominating-file default-directory "CMakeLists.txt")
                         default-directory))
           (default-directory proj-dir)) ;; プロジェクトルートでコマンドを実行
      (if (file-exists-p (expand-file-name "build" proj-dir))
          (compile "cd build && cmake .. && make")
        (message "buildディレクトリが見つかりません。M-x my-cmake-project-create を実行してください。"))))

  ;; --- ★追加: 4. 自動ビルドとeshell連携実行コマンド ---
  (defvar-local my-cmake-executable nil "実行するバイナリ名")
  ;; 【修正】バッファローカル変数ではなく、プロジェクトパスをキーとするグローバル変数に変更
  (defvar my-cmake-executable-alist nil
    "プロジェクトのパスと実行ファイル名の対応表 \(alist\)")

  ;; プロジェクトパスをキーとするグローバル変数
  (defvar my-cmake-executable-alist nil 
    "プロジェクトのパスと実行ファイル名の対応表 (alist)")

  (defun my-cmake-run ()
    "プロジェクトをビルドし、成功すればeshellで実行する"
    (interactive)
    (let* ((proj-dir (locate-dominating-file default-directory "CMakeLists.txt"))
           build-dir
           exe-name)

      ;; 1. CMakeLists.txtとbuildディレクトリの厳格なチェック
      (unless proj-dir
        (error "CMakeLists.txt が見つかりません。M-x my-cmake-project-create でプロジェクトを初期化してください。"))

      (setq build-dir (expand-file-name "build" proj-dir))
      (unless (file-exists-p build-dir)
        (error "buildディレクトリが見つかりません。M-x my-cmake-project-create で初期化してください。"))

      ;; 2. まず、alist(対応表)から過去に保存した実行ファイル名の取得を試みる
      (setq exe-name (cdr (assoc proj-dir my-cmake-executable-alist)))

      ;; 3. 【新規追加】alistに無い場合、CMakeLists.txt から add_executable を自動パースして取得する
      (unless (and exe-name (not (string= exe-name "")))
        (let ((cmake-file (expand-file-name "CMakeLists.txt" proj-dir)))
          (with-temp-buffer
            (insert-file-contents cmake-file)
            (goto-char (point-min))
            ;; 正規表現で add_executable(実行ファイル名 ...) の部分を検索・抽出
            (when (re-search-forward "add_executable[ \t\n]*([ \t\n]*\\([^ \t\n]+\\)" nil t)
              (setq exe-name (match-string 1))))))

      ;; 4. 自動パースでも取得できなかった場合の最終フォールバック（手入力）
      (while (or (not exe-name) (string= exe-name ""))
        (setq exe-name (read-string "Executable name (e.g. MyProject): "))
        (when (string= exe-name "")
          (message "実行ファイル名は空にできません！")))

      ;; 5. 取得・抽出した実行ファイル名を、確実にalistに保存（更新）する
      (setf (alist-get proj-dir my-cmake-executable-alist nil nil #'equal) exe-name)

      ;; 6. 実行処理
      (let ((default-directory proj-dir))
        (eshell)
        (goto-char (point-max))
        (insert (format "cd %s && cmake .. && make && ./%s" build-dir exe-name))
        (eshell-send-input)))))

;; (let ((default-directory proj-dir))
;;   (eshell)
;;   (goto-char (point-max))
;;   ;; 【修正】"cd build" を絶対パスの展開 "cd %s" (build-dir) に変更
;;   (insert (format "cd %s && cmake .. && make && ./%s" build-dir my-cmake-executable))
;;   (eshell-send-input)))))

;; (defun my-cmake-run ()
;;   "プロジェクトをビルドし、成功すればeshellで実行する"
;;   (interactive)
;;   (let* ((proj-dir (or (locate-dominating-file default-directory "CMakeLists.txt")
;;                        default-directory))
;;          (build-dir (expand-file-name "build" proj-dir)))
;;     (unless (file-exists-p build-dir)
;;       (error "buildディレクトリが見つかりません。M-x my-cmake-project-create で初期化してください。"))

;;     ;; 実行するバイナリ名の確認
;;     (unless my-cmake-executable
;;       (setq my-cmake-executable (read-string "Executable name (e.g. MyProject): ")))

;;     ;; プロジェクトルートをカレントディレクトリとしてeshellを開く
;;     (let ((default-directory proj-dir))
;;       (eshell)
;;       (goto-char (point-max))
;;       ;; ビルド(cmake & make)と実行を && で直列に繋いでeshellに送信する
;;       (insert (format "cd build && cmake .. && make && ./%s" my-cmake-executable))
;;       (eshell-send-input)))))

;;;; 8-3. CMakeプロジェクトの高度な自動認識 (project-cmake)
(use-package project-cmake
  :straight '(project-cmake :type git :host github :repo "juanjosegarciaripoll/project-cmake")
  :config
  (project-cmake-eglot-integration))

;;;; 8-4. デバッガ連携 (dape)
(use-package dape
  :straight t
  :bind (("C-c d d" . dape)                   ; デバッグの開始
         ("C-c d b" . dape-breakpoint-toggle) ; ブレークポイントの設置／解除
         ("C-c d q" . dape-quit))             ; デバッガの終了
  :config
  ;; 左側のフリンジ（行番号の横）をクリックして視覚的にブレークポイントを置けるようにする
  (dape-breakpoint-global-mode)

  ;; ウィンドウの分割方法など、GUIライクなデバッガ画面の表示設定
  (setq dape-buffer-window-arrangement 'right))

;;; 99. Startup Optimization Cleanup
;; ---  仕上げ（起動ブーストの解除） ---
(defvar default-file-name-handler-alist)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024))
            (setq file-name-handler-alist default-file-name-handler-alist)))


(provide 'init)
;;; init.el ends here
