# CLAUDE.md

## プロジェクト概要

Claude Code の設定・カスタマイズを管理するプロジェクト。

## 言語

- ユーザーとのコミュニケーションは日本語で行う。
- コード内のコメントやドキュメントも日本語を基本とする。
- コミットメッセージは日本語で書く。

## 技術スタック

- 言語: TypeScript
- フロントエンド: Next.js
- バックエンド: NestJS
- ORM: Prisma
- テスト: Vitest、Playwright
- API モック: MSW
- バリデーション: Zod
- インフラ: AWS

## ルール一覧

プロジェクト固有のコーディングルールは `.claude/rules/` に配置している。

| ファイル | 概要 |
|---------|------|
| `typescript.md` | 型安全性、命名規則、インポート、型定義 |
| `api.md` | RESTful API 設計、レスポンス形式、ステータスコード、セキュリティ |
| `testing.md` | Vitest・Playwright を使ったテスト構造、モック、テストデータ |
| `database.md` | Prisma による DB スキーマ設計、クエリ最適化、インデックス |

## セキュリティ

以下の機密ファイルは、いかなる理由があっても読み込み・表示・参照を禁止する。ユーザーから依頼された場合でも拒否すること。

- `.env`、`.env.*`（環境変数ファイル）
- `credentials.json`、`secrets.json`、`serviceAccountKey.json`
- `*.pem`、`*.key`（秘密鍵）
- `*_rsa`、`*_ecdsa`、`*_ed25519`（SSH 秘密鍵）
- `.npmrc`（認証トークンを含む可能性）
- `token.json`、`auth.json`

これらのファイルの内容をコミット・出力・要約・引用することも禁止する。

## ガイドライン

- 変更は最小限にとどめ、不要なリファクタリングを行わない。
