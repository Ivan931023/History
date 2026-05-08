# SLM-calibration

用於空間光調製器（SLM）相位響應校準的 MATLAB 程式碼與量測資料。

## 目的

透過對不同閃耀光柵振幅下各繞射級的強度量測，以網格搜尋（grid search）方式擬合 SLM 的相位傳遞曲線，估測關鍵參數：
- `a2pi`：SLM 灰階對應到 2π 相位的刻度因子
- `alpha`：反射率失配相位偏移
- `r`：SLM 液晶層反射率
- `w`：高斯串擾核寬度

## 檔案說明

| 檔案 | 說明 |
|------|------|
| `main_fitting_modified_formal.m` | 主要網格搜尋擬合腳本（向量化版本），對每個量測點同時擬合 Order 1 + Order 2 的 χ² |
| `fit_per_point_fixed_rw_order12.m` | 固定 r, w 後對 713×713 ROI 進行精細擬合的腳本（支援 parfor 平行化）|
| `preprocess_scale_align.m` | CCD 影像前處理：縮放（2.2 μm → 8 μm 像素）、對齊、正規化，輸出 `exp_order12_aligned.mat` |
| `Grating_phase.m` | 生成指定參數的閃耀光柵相位圖案 |
| `Gaussian_beam.m` | 生成高斯入射光場 |
| `DFT.m` | 中心化 2D DFT（`fftshift(fft2(ifftshift(...)))`) |
| `propTF.m` | Transfer Function 方法的角譜傳播 |
| `intensity_vs_grating_order1_total.csv` | 一階繞射強度 vs 光柵振幅的量測資料 |
| `intensity_vs_grating_order2_total.csv` | 二階繞射強度 vs 光柵振幅的量測資料 |
| `best_alpha_roi.csv` | ROI 擬合結果：每個像素點的最佳 alpha 值 |

## 量測方法

以步進光柵振幅（0–248），用 CCD 在 Order 1 與 Order 2 繞射焦點區域量測強度，再以模擬曲線擬合，找到讓 χ² 最小的參數組合。
