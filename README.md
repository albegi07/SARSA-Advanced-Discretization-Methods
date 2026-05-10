# Q-Learning Wind Turbine Control

This repository contains MATLAB code for wind turbine control using SARSA and post-analysis scripts for evaluating discretization methods.

## Overview

The codebase includes:
- `src/controller/` — agent implementations, training scripts, and Simulink integration
- `src/analysis/` — statistical evaluation and visualization for model comparisons
- `src/` — core helpers and project setup utilities
- data folders such as `training_results/`, `results_weibull/`, and `results_A_law_cmp/`

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
   - `train_agent`
   - `run_agent`

## Recommended workflow

- Use `setupProject.m` to add source directories to the MATLAB path.
- Run controller training and evaluation from `src/controller/`.
- Run statistical analysis from `src/analysis/` once result files are available.

## Notes

- The discretization method used in ObservationMapper.m must match that of the agent that is trained/evaluated.

## License

This project is released under the MIT License. See `LICENSE` for details.
