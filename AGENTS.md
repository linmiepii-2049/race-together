# AGENTS.md

## 核心職責

理解任務和調度

## 本次任務規則

[總則]

- 只修改「本次任務允許的檔案清單」，禁止動其他檔案與未授權的 config。
- 技術棧：Godot 4.x + GDScript。
- 場景結構：每個場景一個 .tscn 檔，對應的腳本放同目錄或 scripts/ 子目錄。
- 命名慣例：場景/節點用 PascalCase，腳本檔用 snake_case.gd，信號用 snake_case。
- Autoload 只放全域狀態管理器（GameManager、EventBus），禁止塞業務邏輯。
- 資源路徑一律用 res:// 開頭，禁止硬編碼絕對路徑。
- 信號優先：節點間通訊優先用信號（signal），避免直接 get_node() 跨層級取用。
- 輸入處理：統一在 _unhandled_input() 或 InputMap，禁止散落在多個節點的 _input()。
- 狀態機：角色/AI 狀態用顯式狀態機模式，禁止用一堆 if-else 判斷狀態。

## 禁區

- 禁止在 _process() 或 _physics_process() 中做複雜運算或資源載入。
- 禁止用 get_tree().get_nodes_in_group() 後直接修改，須先檢查節點是否有效。
- 禁止在 Autoload 中直接操作特定場景節點（用信號通訊）。
- 禁止硬編碼魔術數字，數值設定放 Resource 或 const。
- 禁止用 call_deferred() 繞過生命週期問題而不理解根因。

## Mock 邊界

- 只 mock 外部 I/O（檔案存取、網路）；遊戲邏輯不 mock。
- Mock 必須在 teardown 時清除狀態，禁止跨測試污染。
- Integration test 對真實場景跑；unit test 對獨立腳本跑。

## Coverage 要求

- 門檻：不設門檻，保持靈活，3 個月後重評（原型驗證階段）。
- 新增核心邏輯函式建議有對應測試，但不強制。

## 行為準則

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

**1. Think Before Coding** — Don't assume. Don't hide confusion. Surface tradeoffs.

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

**2. Simplicity First** — Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

**3. Surgical Changes** — Touch only what you must. Clean up only your own mess.

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

**4. Goal-Driven Execution** — Define success criteria. Loop until verified.

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

## 執行守衛

（任一觸發立即中止，不依賴模型自判）

- **步數上限**：單次任務最多 50 步，超過強制中止並回報當前狀態。
- **Token 預算**：累計 token 達 90% 時警告並加速收束，100% 強制中止。
