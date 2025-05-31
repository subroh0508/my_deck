#!/bin/bash

# Marp Markdownファイル雛形生成スクリプト
# 使用方法: ./new.sh [日付] [イベント名] [スライドタイトル] [発表者情報]

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.yaml"
TEMPLATE_FILE="${SCRIPT_DIR}/template.md"

# 色付きメッセージ用の関数
print_info() {
    echo -e "\033[34m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[31m[ERROR]\033[0m $1" >&2
}

print_warning() {
    echo -e "\033[33m[WARNING]\033[0m $1"
}

# 使用方法を表示
show_usage() {
    echo "使用方法: $0 [日付] [イベント名] [スライドタイトル] [発表者情報]"
    echo ""
    echo "パラメータ:"
    echo "  日付           YYYYMMDD形式（省略時は今日の日付）"
    echo "  イベント名     イベントの名前（省略時は 'EventTitle'）"
    echo "  スライドタイトル スライドのタイトル（省略時は 'DeckTitle'）"
    echo "  発表者情報     発表者の情報（省略時は 'にしこりさぶろ〜(@subroh_0508)'）"
    echo ""
    echo "オプション:"
    echo "  --theme <theme_key>  テーマ指定（デフォルト: graph_paper）"
    echo "  --help, -h          このヘルプメッセージを表示"
    echo ""
    echo "例:"
    echo "  $0 20250531 '技術勉強会' 'Marpの使い方' '田中太郎(@tanaka)'"
    echo "  $0 '' '勉強会' 'タイトル' ''  # 日付と発表者はデフォルト"
    echo "  $0                            # 全てデフォルト値"
    echo ""
    echo "出力ファイル: \${YYYY}/\${YYYYMMDD}_\${イベント名}.md"
}

# 依存関係をチェック
check_dependencies() {
    local missing_deps=()
    
    if ! command -v yq &> /dev/null; then
        missing_deps+=("yq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "以下の依存関係が不足しています:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "インストール方法:"
        echo "  brew install ${missing_deps[*]}"
        exit 1
    fi
}

# 設定ファイルとテンプレートファイルの存在確認
check_config_file() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "設定ファイルが見つかりません: $CONFIG_FILE"
        exit 1
    fi
}

check_template_file() {
    if [ ! -f "$TEMPLATE_FILE" ]; then
        print_error "テンプレートファイルが見つかりません: $TEMPLATE_FILE"
        exit 1
    fi
}

# 日付の妥当性をチェック
validate_date() {
    local date_str="$1"
    
    if [[ ! "$date_str" =~ ^[0-9]{8}$ ]]; then
        print_error "日付は YYYYMMDD 形式で入力してください: $date_str"
        exit 1
    fi
    
    # 日付の妥当性をチェック（dateコマンドを使用）
    if ! date -j -f "%Y%m%d" "$date_str" "+%Y-%m-%d" &>/dev/null; then
        print_error "無効な日付です: $date_str"
        exit 1
    fi
}

# テーマキーの存在確認
check_theme_key() {
    local theme_key="$1"
    
    if ! yq eval ".theme | has(\"$theme_key\")" "$CONFIG_FILE" | grep -q "true"; then
        print_error "テーマキー '$theme_key' が見つかりません"
        echo ""
        print_info "利用可能なテーマキー:"
        yq eval '.theme | to_entries | .[] | "  " + .key + " - " + .value.description' "$CONFIG_FILE"
        exit 1
    fi
}

# ディレクトリの作成
ensure_directory() {
    local dir="$1"
    local relative_dir="$2"
    
    if [ ! -d "$dir" ]; then
        print_info "ディレクトリを作成します: $relative_dir"
        mkdir -p "$dir"
    fi
}

# 日付を年月日に分割
parse_date() {
    local date_str="$1"
    YEAR="${date_str:0:4}"
    MONTH="${date_str:4:2}"
    DAY="${date_str:6:2}"
}

# Markdownファイルを生成
generate_markdown() {
    local date_str="$1"
    local event_name="$2"
    local slide_title="$3"
    local author="$4"
    local theme="$5"
    local output_file="$6"
    
    parse_date "$date_str"
    
    # テンプレートファイルを読み込んで変数置換
    sed -e "s/{{THEME}}/$theme/g" \
        -e "s/{{SLIDE_TITLE}}/$slide_title/g" \
        -e "s/{{AUTHOR}}/$author/g" \
        -e "s/{{EVENT_NAME}}/$event_name/g" \
        -e "s/{{YEAR}}/$YEAR/g" \
        -e "s/{{MONTH}}/$MONTH/g" \
        -e "s/{{DAY}}/$DAY/g" \
        "$TEMPLATE_FILE" > "$output_file"
}

# メイン処理
main() {
    # デフォルト値
    local date_str=""
    local event_name=""
    local slide_title=""
    local author=""
    local theme="graph_paper"
    
    # 引数の解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_usage
                exit 0
                ;;
            --theme)
                theme="$2"
                shift 2
                ;;
            *)
                # 位置引数の処理
                if [ -z "$date_str" ]; then
                    date_str="$1"
                elif [ -z "$event_name" ]; then
                    event_name="$1"
                elif [ -z "$slide_title" ]; then
                    slide_title="$1"
                elif [ -z "$author" ]; then
                    author="$1"
                else
                    print_error "引数が多すぎます"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # デフォルト値の設定
    if [ -z "$date_str" ] || [ "$date_str" = "" ]; then
        date_str=$(date "+%Y%m%d")
        print_info "日付が指定されていないため、今日の日付を使用します: $date_str"
    fi
    
    if [ -z "$event_name" ] || [ "$event_name" = "" ]; then
        event_name="EventTitle"
        print_info "イベント名が指定されていないため、デフォルト値を使用します: $event_name"
    fi
    
    if [ -z "$slide_title" ] || [ "$slide_title" = "" ]; then
        slide_title="DeckTitle"
        print_info "スライドタイトルが指定されていないため、デフォルト値を使用します: $slide_title"
    fi
    
    if [ -z "$author" ] || [ "$author" = "" ]; then
        author="にしこりさぶろ〜(@subroh_0508)"
        print_info "発表者情報が指定されていないため、デフォルト値を使用します: $author"
    fi
    
    # 事前チェック
    check_config_file
    check_template_file
    check_dependencies
    validate_date "$date_str"
    check_theme_key "$theme"
    
    # 出力ファイルパスの構築
    parse_date "$date_str"
    RELATIVE_OUTPUT_DIR="../$YEAR"
    RELATIVE_OUTPUT_FILE="${RELATIVE_OUTPUT_DIR}/${date_str}_${event_name}.md"
    
    # 絶対パスも作成（実際のファイル操作用）
    OUTPUT_DIR="${SCRIPT_DIR}/${RELATIVE_OUTPUT_DIR}"
    OUTPUT_DIR=$(realpath "$OUTPUT_DIR" 2>/dev/null || echo "$OUTPUT_DIR")
    OUTPUT_FILE="${OUTPUT_DIR}/${date_str}_${event_name}.md"
    
    # ディレクトリの確保
    ensure_directory "$OUTPUT_DIR" "$RELATIVE_OUTPUT_DIR"
    
    # 既存ファイルの確認
    if [ -f "$OUTPUT_FILE" ]; then
        print_warning "既存のファイルを上書きします: $RELATIVE_OUTPUT_FILE"
    fi
    
    # Markdownファイル生成
    print_info "Markdownファイルを生成します..."
    print_info "日付: $date_str (${YEAR}年${MONTH}月${DAY}日)"
    print_info "イベント名: $event_name"
    print_info "スライドタイトル: $slide_title"
    print_info "発表者: $author"
    print_info "テーマ: $theme"
    print_info "出力先: $RELATIVE_OUTPUT_FILE"
    
    generate_markdown "$date_str" "$event_name" "$slide_title" "$author" "$theme" "$OUTPUT_FILE"
    
    local file_size=$(du -h "$OUTPUT_FILE" | cut -f1)
    print_success "Markdownファイルの生成が完了しました: $RELATIVE_OUTPUT_FILE (サイズ: $file_size)"
}

# スクリプト実行
main "$@"