# Nuxt 指針

## 基本方針

- データ取得の責務をページとコンポーザブルで分離する。
- `useAsyncData` のキーを安定化し、重複取得を避ける。
- API 失敗時の画面状態をページ単位で明示する。

## 雛形

```vue
<script setup>
const query = ref('');
const { data, pending, error, refresh } = await useAsyncData(
  'items',
  () => $fetch('/api/items', { params: { q: query.value } }),
  { default: () => [] }
);

watch(query, () => {
  refresh();
});
</script>
```
