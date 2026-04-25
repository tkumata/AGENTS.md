# Repository Guidline

## Harness

停止前に必ず以下を守ること:

1. `.agent-hooks/state/logs/check.log` または build.log が存在する場合は確認すること。
2. check が失敗した場合、警告の抑制や lint の回避ではなく、原因そのものを修正すること。
3. `make check` に成功し、その後 `make build` に成功するまではタスク完了として停止しないこと。
