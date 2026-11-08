# 依存関係の更新手順

- Dependabot alerts と security updates は GitHub の Settings → Security（Code security）で有効にする。`dependabot.yml` だけでは有効化されない。
- 通常のGem・GitHub Actions更新は毎週月曜09:00（日本時間）に確認し、各エコシステム最大10件のPRを作成する。脆弱性修正のPRはこの週次スケジュールと関係なく、検知時にすぐ作成される。
- 更新PRごとに既存のBrakeman・importmap audit・Rubocop・RSpecが実行される。RSpecはテスト専用DB（`levely_test`）を使い、本番の情報は渡さない。
- 更新PRは差分・リリースノート・CI結果を確認してから対応する。Railsなどのメジャー更新は影響が大きいため、個別に動作確認してから進める。RSpecのpending項目は成功扱いになるため、該当機能は画面でも確認する。
- 自動マージは使用しない。内容を確認し、承認後に手動でマージする。
- 本番反映前にRenderのSettings → Build & DeployでAuto-DeployがOffになっていることを確認する。承認後に対象コミットを手動デプロイし、ログと主要画面を確認する。
- このCIにデプロイ処理は含まれていない。Render側の自動デプロイ設定はこのリポジトリの設定ファイルでは制御できない。
