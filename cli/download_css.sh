#!/bin/bash

# Marp Themeダウンロードスクリプト
# 使用方法: ./download_css.sh <source_key>

set -euo pipefail

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.yaml"

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
    echo "使用方法: $0 <theme_key>"
    echo ""
    echo "オプション:"
    echo "  --list, -l    利用可能なテーマキー一覧を表示"
    echo "  --help, -h    このヘルプメッセージを表示"
    echo ""
    echo "例:"
    echo "  $0 bootstrap    # Bootstrap CSS をダウンロード"
    echo "  $0 tailwind     # Tailwind CSS をダウンロード"
    echo "  $0 --list       # 利用可能なキー一覧を表示"
}

# 利用可能なテーマキー一覧を表示
show_themes() {
    print_info "利用可能なテーマキー:"
    echo ""
    
    if ! command -v yq &> /dev/null; then
        print_error "yq コマンドが見つかりません。インストールしてください: brew install yq"
        exit 1
    fi
    
    yq eval '.theme | to_entries | .[] | "  " + .key + " - " + .value.description' "$CONFIG_FILE"
}

# 依存関係をチェック
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
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

# 設定ファイルの存在確認
check_config_file() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "設定ファイルが見つかりません: $CONFIG_FILE"
        exit 1
    fi
}

# テーマキーの存在確認
check_theme_key() {
    local theme_key="$1"
    
    if ! yq eval ".theme | has(\"$theme_key\")" "$CONFIG_FILE" | grep -q "true"; then
        print_error "テーマキー '$theme_key' が見つかりません"
        echo ""
        show_themes
        exit 1
    fi
}

# URLとディレクトリ情報を取得
get_config_values() {
    local theme_key="$1"
    
    URL=$(yq eval ".theme.${theme_key}.url" "$CONFIG_FILE")
    THEME_DIR=$(yq eval ".theme_directory" "$CONFIG_FILE")
    FILE_EXT=$(yq eval ".theme.${theme_key}.extension" "$CONFIG_FILE")
    
    # 相対パスを絶対パスに変換
    if [[ "$THEME_DIR" == ../* ]]; then
        THEME_DIR="${SCRIPT_DIR}/${THEME_DIR}"
    fi
    
    THEME_DIR=$(realpath "$THEME_DIR" 2>/dev/null || echo "$THEME_DIR")
}

# ディレクトリの作成
ensure_directory() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        print_info "ディレクトリを作成します: $dir"
        mkdir -p "$dir"
    fi
}

# ファイルをダウンロード
download_file() {
    local theme_key="$1"
    local url="$2"
    local output_file="$3"
    
    print_info "ダウンロード開始: $theme_key"
    print_info "URL: $url"
    print_info "保存先: $output_file"
    
    # 既存ファイルの確認
    if [ -f "$output_file" ]; then
        print_warning "既存のファイルを上書きします: $output_file"
    fi
    
    # ダウンロード実行
    if curl -L -f -o "$output_file" "$url" --connect-timeout 30 --max-time 300; then
        local file_size=$(du -h "$output_file" | cut -f1)
        print_success "ダウンロード完了: $output_file (サイズ: $file_size)"
    else
        print_error "ダウンロードに失敗しました: $url"
        # 失敗した場合は空のファイルを削除
        [ -f "$output_file" ] && rm -f "$output_file"
        exit 1
    fi
}

# メイン処理
main() {
    # 引数の解析
    case "${1:-}" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --list|-l)
            check_config_file
            check_dependencies
            show_themes
            exit 0
            ;;
        "")
            print_error "引数が指定されていません"
            echo ""
            show_usage
            exit 1
            ;;
        *)
            THEME_KEY="$1"
            ;;
    esac
    
    # 事前チェック
    check_config_file
    check_dependencies
    check_theme_key "$THEME_KEY"
    
    # 設定値の取得
    get_config_values "$THEME_KEY"
    
    # 出力ファイルパスの構築
    OUTPUT_FILE="${THEME_DIR}/${THEME_KEY}${FILE_EXT}"
    
    # ディレクトリの確保
    ensure_directory "$THEME_DIR"
    
    # ダウンロード実行
    download_file "$THEME_KEY" "$URL" "$OUTPUT_FILE"
}

# スクリプト実行
main "$@"
