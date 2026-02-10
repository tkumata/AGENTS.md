# React 指針

## 基本方針

- 状態の最小単位を保ち、派生値は計算で求める。
- 非同期処理は `loading/error/data` を分離して管理する。
- 副作用は `useEffect` に閉じ、依存配列を明示する。

## 雛形

```jsx
import { useState } from 'react';

export default function TodoForm() {
  const [text, setText] = useState('');
  const [error, setError] = useState('');
  const [items, setItems] = useState([]);

  function handleSubmit(event) {
    event.preventDefault();
    const value = text.trim();
    if (!value) {
      setError('入力してください');
      return;
    }
    setError('');
    setItems((prev) => [...prev, { text: value, done: false }]);
    setText('');
  }

  return (
    <form onSubmit={handleSubmit}>
      <input value={text} onChange={(e) => setText(e.target.value)} />
      <button type="submit">追加</button>
      {error && <p>{error}</p>}
    </form>
  );
}
```
