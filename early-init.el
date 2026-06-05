;; スプラッシュスクリーンを愛用するための明示的設定
(setq inhibit-startup-screen nil)
(setq inhibit-startup-message nil)

(setq gc-cons-threshold most-positive-fixnum)

;; 標準の package.el の自動初期化を無効化
(setq package-enable-at-startup nil)

;; ついでに起動を速めるために UI の余計な装飾も削っておく
(push '(menu-bar-lines . 0) default-frame-alist)    ; メニューバー非表示
(push '(tool-bar-lines . 0) default-frame-alist)    ; ツールバー非表示
(push '(vertical-scroll-bars) default-frame-alist) ; スクロールバー非表示

;; 起動時のウィンドウサイズと位置を指定
(add-to-list 'default-frame-alist '(width . 100))
(add-to-list 'default-frame-alist '(height . 40))

;; フォントを最初から適用する（環境に合わせて調整してください）
;; (set-face-attribute 'default nil :family "JetBrains Mono" :height 120)

;; タイトルバーを透明にし、外観をスッキリさせる (MacOS 限定)
;; (add-to-list 'default-frame-alist '(ns-appearance . dark))
;; (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))

;; 起動時のファイル名ハンドラのルックアップを抑制して高速化
;; (init.el の最後で元に戻すのが一般的です)
(defvar default-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

;; 警告音を完全に消す（好みによります）
(setq ring-bell-function 'ignore)

;; システム側の初期設定ファイルを無視して自分設定のみを優先する
(setq inhibit-default-init t)
(setq site-run-file nil)
