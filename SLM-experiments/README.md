# SLM-experiments

Early SLM (Spatial Light Modulator) experiment scripts and grating diffraction efficiency measurements. These scripts were developed during the initial exploration phase preceding the beam-shaping work in [SLM-beam-shaping](../SLM-beam-shaping).

## Simulation Scripts

| File | Description |
|------|-------------|
| `DFT_2D.m` | 2D DFT demo applying a quadratic phase and computing discrete Fourier transform |
| `FT_1D.m` | 1D Fourier-transform GS algorithm for 1D beam shaping into a super-Gaussian |
| `Propagation_simulation.m` | Fresnel propagation simulation using the transfer-function method (`propTF`) |
| `SLM_chi2_gridsearch.m` | Grid search over cavity model parameters (mirror reflectivity `r`, PSF width `w`) using chi-squared fitting |
| `Simulation.m` | Full SLM simulation sweeping grating `max_phase`; saves GIFs and CSVs per run in auto-numbered folders |
| `Test_paper_power.m` | Reproduces the paper cavity model, sweeping `max_phase` from 1 to 248 and recording zero/first/second-order intensities |
| `calibrated_center.m` | Generates an annular ring + central bright-spot phase pattern, displays on SLM, acquires a CCD snapshot |
| `show_hologram_on_slm.m` | Function to display a phase hologram on the SLM's dedicated monitor (second screen) |

## Measurement Data

Six repeated CCD intensity measurements at **first** and **second** diffraction orders as a function of grating phase amplitude (0–248, step 2). Each run records 13 CCD pixel positions along the diffraction axis.

| Files | Description |
|-------|-------------|
| `grating_intensity_data_order1_1.csv` – `_6.csv` | CCD intensity at 1st diffraction order, 6 measurement runs |
| `grating_intensity_data_order2_1.csv` – `_6.csv` | CCD intensity at 2nd diffraction order, 6 measurement runs |

### CSV Format

```
GratingPhaseAmplitude, (row,col_1), (row,col_2), ..., (row,col_13)
0, ...
2, ...
...
248, ...
```

Each row corresponds to one grating phase amplitude value. The column headers give the CCD pixel coordinates `(row, col)` of the sampled positions.

## Setup

- Laser: 447 nm
- Focal length: 300 mm
- SLM resolution: 1080 × 1080, pixel pitch 8 µm
- CCD: PointGrey, pixel size 2.2 µm
- Grating type: blazed, 12 levels
