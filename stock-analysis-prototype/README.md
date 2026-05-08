# stock-analysis-prototype

股票分析自動化應用程式的早期原型，為 [Stock-Analysis-Automation-Application](https://github.com/Ivan931023/Stock-Analysis-Automation-Application) 的前身。

## 功能

- 輸入股票代碼與日期區間，自動從 Yahoo Finance 抓取歷史資料
- 計算並繪製技術指標：SMA、MACD、KD、RSI
- 多策略績效比較（buy-and-hold、趨勢跟隨、均線策略、動量策略）
- 透過 Google Cloud Vision OCR + OpenAI GPT-4 對圖表進行自然語言分析
- 匯出 Excel 分析報表

## 版本說明

此為 API 整合版本，分為桌面 GUI 客戶端（`frontend.py`）與 Flask 後端伺服器（`server.py`）兩種前端介面。`website/` 為對應的 Web 前端。

> **注意**：GPT API 已整合完成，但桌面 GUI 版本圖表顯示空間不足以同時呈現四張圖。

## 檔案結構

```
stock-analysis-prototype/
├── server.py          # Flask 後端伺服器，提供股票資料分析 API
├── frontend.py        # Tkinter 桌面 GUI 客戶端
└── website/           # Web 前端介面
    ├── index.html
    ├── script.js
    └── style.css
```

## 相依套件

```
flask, yfinance, pandas, matplotlib, xlsxwriter, TA-Lib, openai, google-cloud-vision
```
