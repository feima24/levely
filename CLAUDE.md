# Levely - Claude Code ルール

## Git ブランチ

- 命名: `{feat|fix|chore|refactor}/{kebab-case}`
- 例: `fix/learning-item-category-constraint`

## コミットメッセージ

- 形式: `{type}: 日本語の説明`
- 1 PR につき原則 1 コミット（型が異なる変更は別コミットに分ける）

### prefix の使い分け

| prefix | 使う場面 | 例 |
|---|---|---|
| `feat:` | 新機能の追加 | feat: 月間クエスト機能を実装 |
| `fix:` | バグ・不具合の修正 | fix: パスワード再設定メールが届かない問題を修正 |
| `chore:` | 依存関係・設定・ドキュメント等 | chore: credentials.yml.encを廃止 |
| `refactor:` | 動作を変えないコード改善 | refactor: 週間集計をコントローラに移動 |
| `ci:` | `.github/workflows/` の変更 | ci: PostgreSQLをpgvector対応イメージに変更 |
| `style:` | rubocop 等のコードスタイル修正 | style: rubocop指摘の空行を修正 |

## プルリクエスト

### タイトル
- 形式: `{type}: 日本語の説明`（70文字以内）

### 本文の構成

```
## 概要
何を・なぜ。2〜3文以内。

## 変更内容
### 機能単位のグループ名
- 変更の箇条書き

## 動作確認
- 〜すると〜になる
```

### 書き方のルール
- 日本語で書く
- 専門用語（streak, specificity 等）は使わず平易な日本語にする
- 実装の解説（「〜メソッドで判定を一元化」等）は書かない
- 変更内容はファイル単位ではなく機能単位で `###` グループ化
- 動作確認は必ず書く。ユーザー操作ベースで「〜すると〜になる」の形式
- 箇条書きはチェックボックスなしの普通の `-`
- ファイル名を出す場合はバックティックでパス（`app/models/learning_item.rb`）
- 英語見出し（Summary / Test plan）は使わない
- issue がある場合は末尾に `Closes #XX`

## コミット前の確認

以下を実行してエラーがないことを確認してからコミットする。

- `bin/rubocop` — スタイル違反（空行、メソッドの長さ等）
- `bin/rspec` — テスト
