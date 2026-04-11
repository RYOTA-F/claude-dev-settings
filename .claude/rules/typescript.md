---
description: TypeScriptの型安全性、命名規則、インポート、型定義に関するルール
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
  - "tsconfig*.json"
---

# TypeScript ルール

## 基本方針

- `strict: true` を有効にし、型安全性を最大限に活用する
- `any` 型の使用を禁止する。やむを得ない場合は `unknown` を使用する
- 型推論が可能な場合でも、関数の引数と戻り値には明示的な型注釈をつける

## 命名規則

- 変数・関数: camelCase
- 型・インターフェース: PascalCase
- 定数: UPPER_SNAKE_CASE
- ファイル名: kebab-case.ts

## インポート

- 型のみのインポートには `import type` を使用する
- バレルファイル（index.ts）での再エクスポートを活用する
- 相対パスよりもパスエイリアス（`@/`）を優先する

## 型定義

- `interface` と `type` の使い分け：オブジェクト型には `interface`、ユニオン型や交差型には `type` を使用する
- Enum の代わりに `as const` オブジェクトを使用する
- ユーティリティ型（`Partial`, `Pick`, `Omit` など）を積極的に活用する

## エラーハンドリング

- カスタムエラークラスを定義して使用する
- `try-catch` では型ガードでエラー型を絞り込む
