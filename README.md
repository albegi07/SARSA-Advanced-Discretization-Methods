# Q-Learning Wind Turbine Control

This repository contains MATLAB code for wind turbine control using Q-learning and post-hoc analysis scripts for evaluating discretization methods.

## Overview

The codebase includes:
- `src/controller/` — agent implementations, training scripts, and Simulink integration
- `src/analysis/` — statistical evaluation and visualization for model comparisons
- `src/` — core helpers and project setup utilities
- data folders such as `ModelAnalysisOutput/`, `Output/`, and `results/`

This project is organized for reproducible research and includes analysis routines for wind power tracking performance.

## Requirements

- MATLAB (R2020a or later recommended)
- Simulink
- Statistics and Machine Learning Toolbox
- Existing `.mat` results files for analysis scripts

## Setup

1. Open MATLAB and set the current folder to the repository root.
2. Run:
   ```matlab
   setupProject
   ```
3. Run one of the main scripts from the MATLAB command window:
   - `main`
   - `run_agent`
   - `wilcoxon_pairwise_full_analysis`

## Recommended workflow

- Use `setupProject.m` to add source directories to the MATLAB path.
- Run controller training and evaluation from `src/controller/`.
- Run statistical analysis from `src/analysis/` once result files are available.

## Notes

- `getProjectRoot.m` resolves file locations relative to the repository root.
- The repository includes existing analysis results and plot outputs in the data directories.

## License

This project is released under the MIT License. See `LICENSE` for details.
