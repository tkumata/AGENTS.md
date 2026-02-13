# AngularJS 指針

## 基本方針

- 既存が `controllerAs` を使っているなら統一する。
- `$scope` への直接代入を最小化し、`vm` 経由で状態を管理する。
- API 呼び出しはサービスへ分離し、コントローラを薄く保つ。

## 雛形

```js
angular.module('app').controller('TodoController', function TodoController(todoService) {
  var vm = this;
  vm.items = [];
  vm.error = '';
  vm.add = add;

  function add(text) {
    if (!text || !text.trim()) {
      vm.error = '入力してください';
      return;
    }
    vm.error = '';
    vm.items.push({ text: text.trim(), done: false });
    todoService.save(vm.items);
  }
});
```
