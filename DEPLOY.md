# Web 部署與多人信令

## 本機匯出（Web）

1. 在 Godot 編輯器安裝 **Export Templates**（與引擎同版本，例如 4.6.2），並勾選 **Web**。
2. 專案根目錄已有 `export_presets.cfg`（預設輸出到 `build/web/index.html`）。
3. 終端機執行：

```bash
mkdir -p build/web
godot --headless --path . --export-release "Web" build/web/index.html
```

4. 將 `build/web/` 整包上傳到任意 **靜態網站主機**（GitHub Pages、Netlify、S3 等）。

## GitHub Actions（自動匯出）

工作流程：`.github/workflows/web.yml`

- 每次推送到 `main` 或 `master` 會用 **Godot 4.6.2** 匯出 Web，並上傳 **Artifact** `web-export`。
- 若要在 **GitHub Pages** 發佈：在倉庫 **Settings → Pages** 將 **Source** 設為 **GitHub Actions**（不要選 branch）。首次推送後，到 **Actions** 分頁確認 `deploy` 工作成功；網址通常為 `https://<使用者>.github.io/<倉庫名>/`。

## 信令伺服器（多人必備）

瀏覽器必須連 **`wss://`**（HTTPS 網站上的遊戲不可再用 `ws://127.0.0.1`）。

1. 將 `signaling/` 部署到可長駐的 Node 環境（VPS、Railway、Fly.io 等），前面加 **TLS 反向代理**（Caddy / Nginx）暴露 `wss://`。
2. 在專案 `project.godot` 的 **`[racecar]` → `signaling_url_web`** 填入你的信令網址，再重新匯出 Web。  
   或：遊戲網址加上查詢參數，例如  
   `https://你的頁面/index.html?signal=wss%3A%2F%2Fsignal.example.com%2F`  
   （`signal` 的值需為 **URL 編碼** 後的 `wss://…`）。

本機桌面測試仍可使用大廳預設的 `ws://127.0.0.1:9080`（需 `cd signaling && npm start`）。

## 常見問題

- **匯出失敗：找不到 web_nothreads_release.zip**  
  代表本機未安裝對應版本的 Web export templates，請在 Godot 選單 **Editor → Manage Export Templates** 下載。
- **網頁上多人連不上**  
  檢查 `signaling_url_web` / `?signal=` 是否為 **wss**、憑證是否有效、以及信令行程是否真的在跑。
