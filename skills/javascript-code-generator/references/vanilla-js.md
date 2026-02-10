# Vanilla JS 指針

## 基本方針

- `querySelector` の多重呼び出しを避け、必要要素は初期化時にキャッシュする。
- イベント委譲でハンドラ数を抑える。
- DOM 変更はまとめて行い、不要な再計算を減らす。

## 雛形

```js
function createController({ root, onSubmit }) {
  const form = root.querySelector('[data-form]');
  const input = root.querySelector('[data-input]');
  const error = root.querySelector('[data-error]');

  function setError(message) {
    error.textContent = message || '';
  }

  function handleSubmit(event) {
    event.preventDefault();
    const value = input.value.trim();
    if (!value) {
      setError('入力してください');
      return;
    }
    setError('');
    onSubmit(value);
  }

  form.addEventListener('submit', handleSubmit);

  return {
    destroy() {
      form.removeEventListener('submit', handleSubmit);
    },
  };
}
```
