# 組み込み C 言語セットアップ

## 1. Homebrew で入れるもの

```bash
brew update

# 必須
brew install llvm
brew install cppcheck

# あれば便利
brew install cmake
brew install bear   # compile_commands.json 生成用
```

Apple Clang ではなく Homebrew の LLVM を使うので、PATH を通す。

```bash
echo 'export PATH="/opt/homebrew/opt/llvm/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

確認

```bash
clangd --version
clang-format --version
cppcheck --version
```

## 2. VS Code 拡張 (最小構成)

必須:

- clangd (llvm-vs-code-extensions.vscode-clangd)
- C/C++ (ms-vscode.cpptools) ※ ESP-IDF や一部拡張との相性要員

任意:

- CMake Tools (ms-vscode.cmake-tools)
- ESP-IDF (espressif.esp-idf-extension)
- Error Lens (視認性向上)

結論:

👉 メインは clangd、cpptools は補助として残す

## 3. VS Code 設定 (settings.json)

```json
{
  // clangd を使う
  "C_Cpp.intelliSenseEngine": "disabled",

  // フォーマッタ
  "[c]": {
    "editor.defaultFormatter": "llvm-vs-code-extensions.vscode-clangd"
  },
  "[cpp]": {
    "editor.defaultFormatter": "llvm-vs-code-extensions.vscode-clangd"
  },

  // 保存時フォーマット
  "editor.formatOnSave": true,

  // clangd 設定
  "clangd.arguments": [
    "--background-index",
    "--clang-tidy",
    "--completion-style=detailed",
    "--header-insertion=iwyu"
  ],

  // cpptools は補助用途
  "C_Cpp.autocomplete": "Disabled",

  // include エラー抑制 (必要に応じて)
  "C_Cpp.errorSquiggles": "disabled"
}
```

## 4. .clang-format (プロジェクトルート)

組み込み向けで無難な設定：

```yaml
BasedOnStyle: LLVM
IndentWidth: 4
ColumnLimit: 100
UseTab: Never

BreakBeforeBraces: Allman

AllowShortIfStatementsOnASingleLine: false
AllowShortLoopsOnASingleLine: false

PointerAlignment: Left

SortIncludes: false
```

※ ESP-IDF も Pico SDK もこれで問題なし

## 5. cppcheck 実行設定 (VS Code タスク)

`.vscode/tasks.json`

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "cppcheck",
      "type": "shell",
      "command": "cppcheck",
      "args": [
        "--enable=all",
        "--inconclusive",
        "--std=c11",
        "--quiet",
        "--inline-suppr",
        "--force",
        "src"
      ],
      "group": "build",
      "problemMatcher": "$gcc"
    }
  ]
}
```

## 6. compile_commands.json (重要)

clangd の精度はこれで決まる。

### CMake の場合

```bash
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .
```

### Make / ESP-IDF の場合

```bash
bear -- make
```

ESP-IDF:

```bash
idf.py build
# → build/compile_commands.json が生成される (最近は標準対応)
```

## 7. マイコン別ポイント

### ESP32 (ESP-IDF)

- ESP-IDF 拡張を入れる
- `compile_commands.json` は build ディレクトリに出る
- clang-tidy は必要なら追加

### Raspberry Pi Pico

- CMake 前提なので `compile_commands.json` は簡単に出る
- clangd と相性良い

## 8. clang-tidy (必要な場合のみ)

```bash
brew install llvm  # 既に入っているなら OK
```

`.clang-tidy` 例:

```yaml
Checks: >
  -*,
  clang-analyzer-*,
  bugprone-*,
  performance-*,
  readability-*

WarningsAsErrors: ""
```

## 実行

実行するには `Embed-C-Check.md` を参照。
