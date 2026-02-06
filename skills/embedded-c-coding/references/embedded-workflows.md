# Embedded C Workflows

## モジュール構成

- `module/`
- `module/module.h`
- `module/module.c`
- `module/module_internal.h` が必要な場合のみ作成する。

### 例: 公開 API と内部実装

```c
// module.h
#pragma once
#include <stdint.h>
#include <stdbool.h>

typedef enum {
    MODULE_OK = 0,
    MODULE_ERR_TIMEOUT,
    MODULE_ERR_IO,
} module_status_t;

void module_init(void);
module_status_t module_read(uint8_t *out, uint16_t out_len);
```

```c
// module.c
#include "module.h"
#include "module_internal.h"

static bool module_ready;

void module_init(void) {
    module_ready = true;
}

module_status_t module_read(uint8_t *out, uint16_t out_len) {
    if (!module_ready || out == NULL || out_len == 0) {
        return MODULE_ERR_IO;
    }
    return MODULE_OK;
}
```

## エラーとログ

- 失敗時にログを出す。
- ログはビルド設定で無効化できるようにする。

```c
// log.h
#pragma once

#ifdef ENABLE_LOG
void log_write(const char *tag, const char *fmt, ...);
#define LOGE(tag, fmt, ...) log_write(tag, fmt, ##__VA_ARGS__)
#else
#define LOGE(tag, fmt, ...) ((void)0)
#endif
```

```c
if (status != MODULE_OK) {
    LOGE("module", "read failed: %d", (int)status);
}
```

## 割込み設計

- ISR は最小化する。
- メインループへ移すためにフラグやリングバッファを使う。

```c
static volatile bool rx_pending;

void ISR_RX(void) {
    rx_pending = true;
}

void main_loop(void) {
    if (rx_pending) {
        rx_pending = false;
        // ここで重い処理を行う
    }
}
```

## 共有データの保護

- 共有変数の更新は短いクリティカルセクションで行う。

```c
uint32_t read_counter_safe(void) {
    uint32_t v;
    disable_irq();
    v = g_counter;
    enable_irq();
    return v;
}
```

## タイムアウト

- 単調増加カウンタを基準にする。

```c
bool is_timeout(uint32_t start_ms, uint32_t now_ms, uint32_t timeout_ms) {
    return (uint32_t)(now_ms - start_ms) >= timeout_ms;
}
```

## HAL 分離

- ハード依存部は薄い層で閉じ込める。

```c
// hal_gpio.h
#pragma once
#include <stdbool.h>
void hal_gpio_write(uint8_t pin, bool level);
```

```c
// board_gpio.c
#include "hal_gpio.h"
void hal_gpio_write(uint8_t pin, bool level) {
    // ボード固有 API を呼ぶ
}
```

## Arduino IDE / Pico SDK の注意点

- 既存の初期化フローに合わせ、`setup()` / `loop()` または SDK の初期化順序を壊さない。
- 低レイヤの API 直接呼び出しは最小化し、ボード差分を吸収するラッパを作る。
