# SLM-beam-shaping

MATLAB codebase for Spatial Light Modulator (SLM) beam shaping experiments. Implements analytic flat-top beam conversion, Gerchberg–Saxton (GS) hologram generation, and Metropolis/simulated annealing optimization of Zernike wavefront correction.

## Overview

The system uses a phase-only SLM (1080×1080 pixels, 8 µm pitch) illuminated by a 447 nm Gaussian beam (≈3.45 mm 1/e² radius). A blazed grating separates the shaped first diffraction order from the zero order, and a 300 mm focal-length lens performs the Fourier transform. A PointGrey CCD (2.2 µm pixel) records the output intensity.

## File Index

| File | Description |
|------|-------------|
| **Main experiment scripts** | |
| `Analytic_flattop_beam.m` | Full pipeline: sets beam/grating/Zernike parameters, captures CCD image, compares with analytic simulation, computes RMS variance |
| `Analytic_flattop_beam_fast.m` | Streamlined version of above without the analysis/comparison section |
| `Analytic_flattop_beam_simulated_annealing.m` | Metropolis algorithm optimization of Zernike coefficients to minimize RMS variance against analytic target |
| `Code_backup.m` | Backup of the simulated annealing script with file-saving enabled |
| `GS_algorithm_experiment.m` | Gerchberg–Saxton hologram generation followed by experimental CCD capture |
| `GS_algorithm_simulation.m` | Pure simulation GS algorithm, no hardware required |
| `GS_modified_experiment.m` | Modified GS with signal/noise region separation — experimental version |
| `GS_modified_simulation.m` | Modified GS simulation, plots convergence of signal-region intensity |
| `Test1.m` | Sweeps blazed grating amplitude vs. CCD intensity at a fixed pixel, saves GIF |
| `Test2.m` | Same sweep at three pixel positions simultaneously with ROI averaging |
| `Test_SLM_position.m` | Tests SLM phase pattern alignment on screen across position offsets |
| `Test_paper.m` | Simulates SLM model from paper: comprehensive phase modulator model |
| `Test_para.m` | Parameter scratchpad |
| `Simulate_experiment_flattop.m` | Standalone simulation of full flat-top beam experiment (no hardware) |
| **Simulation functions** | |
| `Simulate_flattop.m` | Simulate flat-top beam (rectangular) for given parameters; returns zoomed-in intensity |
| `Simulate_flattop_circle.m` | Simulate circular flat-top beam |
| `Simulate_flattop_fast.m` | Fixed-parameter fast version of `Simulate_flattop` |
| `Simulate_phase_pattern.m` | Simulate arbitrary phase pattern applied to SLM |
| **Phase generation** | |
| `Blazed_grating_rotate.m` | Generate rotated blazed grating phase pattern (integer levels) |
| `Grating_phase.m` | Wrapper: calls `Blazed_grating_rotate` and converts to radians |
| `Rectangle_analytic_phase.m` | Analytic phase for rectangular flat-top beam (separable x/y, erf-based) |
| `Circle_analytic_phase.m` | Analytic phase for circular flat-top beam |
| `Zernike_phase.m` | Wrapper: generate padded Zernike phase map from coefficients |
| `Zernike_polynomial_superposition.m` | Superposition of Zernike polynomials on a polar grid (legacy, rho/theta inputs) |
| `Zernike_polynomial_superposition_ver2.m` | Improved Zernike superposition operating on pixel coordinates with pupil masking |
| `Zernike_polynomial_ver2.m` | Single Zernike polynomial evaluation with OSA/ANSI normalization |
| `zernike_polynomial.m` | Original Zernike polynomial (unnormalized) |
| **Fourier optics** | |
| `DFT.m` | Centered 2D DFT: `fftshift(fft2(ifftshift(u)))` |
| `IDFT.m` | Centered 2D IDFT: `fftshift(ifft2(ifftshift(u)))` |
| `Angle_0_2pi.m` | Extract phase angle remapped to [0, 2π] |
| `padding.m` | Zero-pad a smaller matrix into a larger grid |
| `pupil.m` | Generate circular pupil mask on unit disk |
| **CCD / hardware** | |
| `CCD_snapshot.m` | Script: displays phase on SLM, configures PointGrey CCD, takes N averaged snapshots |
| `Snapshot.m` | Function version of CCD snapshot (averages N frames) |
| `Check_shutter.m` | Auto-adjusts CCD shutter speed to keep peak intensity in [88%, 99.9%] of range |
| `Find_beam.m` | Finds beam centroid on CCD using `imfindcircles` |
| `Find_beam_simulation.m` | Simulation version of beam finding (no hardware) |
| **Utilities** | |
| `Find_number.m` | Count total Zernike polynomial terms up to radial order n |
| `Gaussian_beam.m` | Generate normalized Gaussian input beam field on SLM grid |
| `Mask.m` | Find bounding box indices of region above threshold |
| `RMS_var.m` | RMS variance normalized by mean intensity (%) |
| `RMS_var_ver2.m` | RMS variance without mean normalization (%) |
| `Generate_GIF.m` | Append figure frame to an animated GIF file |
| `imagesc_turbo.m` | Quick `imagesc` with turbo colormap, colorbar, and axis image |
| `move_image_on_screen.m` | Display phase pattern on SLM monitor at specified pixel offset |

## Workflow

### Flat-top beam shaping (analytic method)
1. Set beam, grating, and Zernike parameters in `Analytic_flattop_beam.m`
2. Run the script — it places the hologram on the SLM, captures CCD image, and overlays the analytic prediction
3. Optionally run `Analytic_flattop_beam_simulated_annealing.m` to auto-optimize Zernike coefficients

### Holographic beam shaping (GS algorithm)
1. Define target intensity pattern in `GS_algorithm_experiment.m` or `GS_algorithm_simulation.m`
2. Run GS iterations to converge hologram phase
3. Place phase on SLM and capture CCD image

### Pure simulation
Use `Simulate_experiment_flattop.m` or `Simulate_flattop.m` to verify results without hardware.

## Dependencies
- MATLAB Image Processing Toolbox (`imfindcircles`, `imshow`)
- MATLAB Image Acquisition Toolbox (`videoinput`, PointGrey driver) — hardware scripts only
- All `.m` files in this folder must be on the MATLAB path
