# How to Use Formatter, Linter

前提として `Embed-C-Setup.md` で環境を構築済みであること。

## 1. フォーマッタ (clang-format)

### 全ファイル整形 (上書き)

```bash
find . -name '*.c' -o -name '*.h' -o -name '*.cpp' | xargs clang-format -i
```

### 差分だけ整形 (Git 前提)

```bash
git diff --name-only | grep -E '\.(c|h|cpp)$' | xargs clang-format -i
```

### チェックのみ (CI / fail させたい)

```bash
clang-format --dry-run --Werror $(git ls-files '*.c' '*.h' '*.cpp')
```

## 2. cppcheck (軽量・安定)

通常チェック

```bash
cppcheck --enable=all --inconclusive --std=c11 --quiet src
```

長際チェック (CI)

```bash
cppcheck --enable=all --inconclusive --std=c11 --force --inline-suppr --error-exitcode=1 src
```

compile_commands.json を使う場合 (精度↑)

```bash
cppcheck --project=compile_commands.json
```

## 3. clang-tidy (精度高・やや重い)

※ `compile_commands.json` 必須

### 単発

```bash
clang-tidy src/main.c -p .
```

### 全体 (推奨形)

```bash
run-clang-tidy -p . -quiet
```

### エラーで落とす

```bash
run-clang-tidy -p . -quiet | tee tidy.log
test ! -s tidy.log
```

## 4. clangd (直接叩かない)

clangd は LSP なのでコマンド実行用途には使わない。
→ エージェント用途では無視で OK

## 5. 実用ワンライナー (おすすめ)

### フルチェック (整形 + lint)

```bash
clang-format -i $(git ls-files '*.c' '*.h' '*.cpp') \
&& cppcheck --project=build/compile_commands.json --enable=all --inconclusive --error-exitcode=1 \
&& run-clang-tidy -p build -quiet
```

## 6. Makefile 化 (AI エージェント向け)

これが一番扱いやすい。

```Makefile
format:
        clang-format -i $(shell git ls-files '*.c' '*.h' '*.cpp')

lint:
        cppcheck --enable=all --inconclusive --std=c11 --error-exitcode=1 src

tidy:
        run-clang-tidy -p . -quiet

check: format lint
```

AI エージェントには

```bash
make check
```

だけ実行させればいい。

## 7. 重要な設計ポイント

- 終了コードで判定できること
  - `--error-exitcode=1` が重要
- 入力を固定すること
  - `git ls-files` を使う (ゴミファイル回避)
- `compile_commands.json` を使えるなら使う
  - clang 系の精度が跳ね上がる
