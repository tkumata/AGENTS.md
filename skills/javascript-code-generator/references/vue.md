# Vue 指針

## 基本方針

- 単一責務でコンポーネントを分割する。
- `props` は読み取り専用にし、更新は `emit` で親へ通知する。
- 非同期処理は `loading` と `error` を必ず状態化する。

## 雛形

```vue
<script setup>
import { ref } from 'vue';

const text = ref('');
const error = ref('');
const items = ref([]);

function addItem() {
  const value = text.value.trim();
  if (!value) {
    error.value = '入力してください';
    return;
  }
  error.value = '';
  items.value.push({ text: value, done: false });
  text.value = '';
}
</script>
```
