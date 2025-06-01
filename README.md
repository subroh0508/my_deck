# My Deck

Marpを使用したプレゼンテーションスライド管理プロジェクトです。CLIツールを使って効率的にスライドの雛形作成とテーマ管理を行うことができます。

## 🚀 機能

- **スライド雛形の自動生成**: イベント名、日付、発表者情報を指定してMarkdownファイルを生成
- **テーマ管理**: CSSテーマのダウンロードとVSCode設定の自動更新
- **設定のカスタマイズ**: デフォルト値やテーマの設定をYAMLファイルで管理

## 📁 プロジェクト構成

```
my_deck/
├── README.md              # このファイル
├── cli/                   # CLIツール
│   ├── config.yaml       # 設定ファイル
│   ├── new.sh            # スライド雛形生成スクリプト
│   ├── download_css.sh   # CSSダウンロードスクリプト
│   └── template.md       # スライドテンプレート
├── themes/                # CSSテーマファイル
└── YYYY/                  # 年別スライドフォルダ
    └── [YYYYMMDD]_[イベント名].md
```

## 🛠️ 事前準備

### 必要なツールのインストール

```bash
# Homebrewを使用してツールをインストール
brew install yq jq curl
```

### VSCodeでのMarp環境設定

1. VSCode拡張機能「Marp for VS Code」をインストール
2. 本プロジェクトのCLIツールが自動的にVSCode設定を更新します

## 📝 スライド雛形作成

### 基本的な使用方法

```bash
cd cli
./new.sh [日付] [イベント名] [スライドタイトル] [発表者情報]
```

### パラメータ

| パラメータ | 説明 | 形式 | 省略時の動作 |
|-----------|------|------|-------------|
| 日付 | スライド作成日 | YYYYMMDD | 今日の日付を使用 |
| イベント名 | 発表するイベント名 | 文字列 | config.yamlのデフォルト値 |
| スライドタイトル | スライドのタイトル | 文字列 | config.yamlのデフォルト値 |
| 発表者情報 | 発表者の名前とアカウント | 文字列 | config.yamlのデフォルト値 |

### オプション

- `--theme <theme_key>`: 使用するテーマを指定
- `--help`, `-h`: ヘルプメッセージを表示

### 使用例

```bash
# 全てのパラメータを指定
./new.sh 20250531 '技術勉強会' 'Marpの使い方' '田中太郎(@tanaka)'

# 一部パラメータをデフォルト値で使用（空文字で指定）
./new.sh '' '勉強会' 'タイトル' ''

# 全てデフォルト値を使用
./new.sh

# テーマを指定して作成
./new.sh 20250531 '勉強会' 'タイトル' '' --theme graph_paper
```

### 出力

- **ファイル名**: `YYYY/YYYYMMDD_イベント名.md`
- **例**: `2025/20250531_技術勉強会.md`

生成されるファイルには以下の内容が含まれます：
- Marpの設定（YAML front matter）
- タイトルページ
- アジェンダページ
- サンプルセクション
- まとめページ

## 🎨 テーマ管理

### CSSテーマのダウンロード

```bash
cd cli
./download_css.sh <theme_key>
```

### 利用可能なテーマ一覧の確認

```bash
./download_css.sh --list
```

### 使用例

```bash
# Graph Paperテーマをダウンロード
./download_css.sh graph_paper

# 利用可能なテーマ一覧を表示
./download_css.sh --list

# ヘルプを表示
./download_css.sh --help
```

### テーマダウンロード時の動作

1. 指定されたテーマのCSSファイルをダウンロード
2. `themes/` フォルダに保存
3. VSCodeの設定ファイル（`.vscode/settings.json`）を自動更新
4. Marpで即座に使用可能になる

## ⚙️ 設定ファイル

### config.yaml の構成

```yaml
# テーマ設定
theme:
  theme_key:
    url: "ダウンロード元URL"
    description: "テーマの説明"
    extension: ".css"

# 出力先ディレクトリ
theme_directory: "../themes"

# デフォルト値
defaults:
  event_name: "デフォルトイベント名"
  slide_title: "デフォルトタイトル"
  author: "デフォルト発表者"
  theme: "デフォルトテーマキー"
```

### カスタマイズ方法

1. `cli/config.yaml` を編集
2. `defaults` セクションでデフォルト値を変更
3. `theme` セクションで新しいテーマを追加

## 📖 ワークフロー例

### 新しいスライドを作成する場合

1. **テーマの確認・ダウンロード**
   ```bash
   cd cli
   ./download_css.sh --list        # 利用可能テーマの確認
   ./download_css.sh graph_paper   # 必要に応じてダウンロード
   ```

2. **スライド雛形の生成**
   ```bash
   ./new.sh 20250601 'DevFest' 'Web開発の最新動向' '山田花子(@yamada)'
   ```

3. **生成されたファイルを編集**
   - `2025/20250601_DevFest.md` が生成される
   - VSCodeで開いてコンテンツを編集

4. **プレビュー・エクスポート**
   - VSCodeのMarp拡張機能でプレビュー
   - PDF/HTMLでエクスポート

## 🔧 トラブルシューティング

### よくあるエラー

**「yq コマンドが見つかりません」**
```bash
brew install yq
```

**「テーマキーが見つかりません」**
```bash
./download_css.sh --list  # 利用可能なテーマを確認
```

**「日付形式が無効です」**
- 日付は `YYYYMMDD` 形式で入力してください
- 例: `20250531`

### ログの確認

スクリプト実行時に詳細な情報が色付きで表示されます：
- 🔵 INFO: 情報メッセージ
- 🟢 SUCCESS: 成功メッセージ  
- 🔴 ERROR: エラーメッセージ
- 🟡 WARNING: 警告メッセージ

## 📄 ライセンス

このプロジェクトは自由に使用・改変できます。