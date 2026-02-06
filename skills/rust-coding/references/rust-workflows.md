# Rust 実装レシピ

## 使い分けの目安
- CLI は `clap`、Web サーバは `axum` を基本とする。
- バイナリは `anyhow`、ライブラリは `thiserror` を基本とする。

## CLI の最小構成
狙いは最小の実行可能性と、入出力の明確化。

```rust
use clap::Parser;

#[derive(Parser, Debug)]
struct Args {
    #[arg(long)]
    input: String,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    run(args)
}

fn run(args: Args) -> anyhow::Result<()> {
    println!("{}", args.input);
    Ok(())
}
```

## Web サーバの最小構成
狙いはルーティングとエラー変換の骨格を先に固めること。

```rust
use axum::{routing::get, Router};

async fn health() -> &'static str {
    "ok"
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/health", get(health));
    axum::Server::bind(&"0.0.0.0:3000".parse().unwrap())
        .serve(app.into_make_service())
        .await
        .unwrap();
}
```

## エラー設計の方針
- 公開 API を持つならエラー型を小さく定義し、境界で変換する。
- 表示用は短く、原因追跡用は `source` で残す。

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("not found")]
    NotFound,
    #[error("io error")]
    Io(#[from] std::io::Error),
}
```

## テストの方針
- 純粋関数は単体テストに寄せる。
- ファイル I/O や HTTP は `tests/` で統合テストに寄せる。

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn smoke() {
        assert_eq!(2 + 2, 4);
    }
}
```

## 実行コマンドの目安
- `cargo fmt`
- `cargo clippy -- -D warnings`
- `cargo test`
