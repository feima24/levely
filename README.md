# Levely

日々の学習ログを「あとから使える形」で残すことに特化した、エンジニア向けの日報アプリ（MVP 開発中）。

## 前提

- Ruby 3.1.3（`.ruby-version` に準拠）
- Rails 7.2.x
- PostgreSQL（開発・本番ともに PostgreSQL を想定）

## セットアップ

1. 依存関係のインストール

   ```bash
   bundle install
   ```

2. 環境変数（ローカル）

   `.env` は **Git にコミットしません**（`.gitignore` で除外済み）。

   ```bash
   cp .env.example .env
   ```

   `.env` を編集し、ローカルの PostgreSQL のユーザー名・パスワード・DB 名などを実際の値に合わせてください。

3. データベースの準備

   ```bash
   bin/rails db:prepare
   ```

   存在しないデータベースの作成・マイグレーション適用・（あれば）シードまで行います。

4. サーバーの起動

   ```bash
   bin/rails server
   ```

   ブラウザで `http://localhost:3000` を開いてください。

## 本番（Render）での DB

本番では [Render](https://render.com/) の環境変数を利用する想定です。PostgreSQL を Web サービスにリンクすると、通常 **`DATABASE_URL`** が自動で設定されます。`config/database.yml` の `production` はこの `DATABASE_URL` を参照します。追加のキーが必要な場合は Render ダッシュボードの **Environment** から設定してください。

## セキュリティ上の注意

- **データベースのパスワードや API キーなどの秘密情報は、リポジトリに含めないでください。** `.env`・`config/master.key` はコミット対象外です。
- `.env.example` には **ダミー値のみ** を置き、実パスワードは入れないでください。
- 誤って秘密情報をコミットした場合は、履歴の改変だけでなく **該当の資格情報をローテーション（パスワード変更・キー再発行）** することを推奨します。

## テスト

```bash
bin/rails test
```

（テスト実行時も PostgreSQL が起動しており、`LEVELY_DATABASE_TEST_NAME` で指定した DB（未設定時は `levely_test`）に接続できる必要があります。）
