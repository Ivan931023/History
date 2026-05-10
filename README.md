# History

個人專案歷史紀錄，涵蓋光學實驗量測、SLM 校正與控制、以及股票分析原型開發。

---

## 目錄結構

### `SLM-experiments/`
SLM（Spatial Light Modulator）繞射效率量測資料。

記錄不同 Grating Phase Amplitude（0–248，步距 2）下，各 CCD 像素位置的光強度值。

| 檔案 | 說明 |
|------|------|
| `grating_intensity_data_order1_1.csv` ~ `order1_6.csv` | 一階繞射量測，共 6 組 |
| `grating_intensity_data_order2_1.csv` ~ `order2_6.csv` | 二階繞射量測，共 6 組 |

- order1_1 ~ order1_5：CCD row 1035，columns 785–1985（step 100）
- order1_6 及 order2_x：CCD row 1430，columns 800–2000（step 100）

---

### `SLM-calibration/`
SLM 相位校正與繞射效率擬合（原 `SLM-fitting/`）。

包含用於校正 SLM 相位響應的 MATLAB 腳本與彙總資料。

| 檔案 | 說明 |
|------|------|
| `intensity_vs_grating_order1_total.csv` | 一階各次量測彙總平均 |
| `intensity_vs_grating_order2_total.csv` | 二階各次量測彙總平均 |
| `*.m` | MATLAB 擬合腳本（Gaussian beam、DFT、grating phase 等）|

---

### `SLM-beam-shaping/`
SLM 光束整形控制程式（原 `SLM-code/SLM_code/`）。

包含 MATLAB 腳本，用於產生相位圖樣、控制 SLM 顯示光束整形圖案。

---

### `stock-analysis-prototype/`
股票分析 API 整合原型（原 `final-project/API integrate/`）。

早期股票資料擷取與分析功能的雛形實作。

---

## 原始資料夾

以下為原始資料夾，保留供參照：

- `dash/` — SLM 實驗原始資料（含 PNG 圖像、XLSX、CSV 量測檔）
- `SLM-fitting/` — 原始校正腳本與資料
- `SLM-code/` — 原始 SLM 控制程式碼
- `final-project/` — 原始股票分析專案
