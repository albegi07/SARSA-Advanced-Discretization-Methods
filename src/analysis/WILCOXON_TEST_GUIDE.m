% ============================================================================
% WILCOXON SIGNED-RANK TEST ANALYSIS SUITE
% ============================================================================
% Documentation and usage guide for Wilcoxon test scripts
%
% This suite replaces bootstrap confidence interval analysis with 
% statistical hypothesis testing using the Wilcoxon signed-rank test,
% providing p-values, effect sizes, and rigorous statistical comparisons
% ============================================================================

%% OVERVIEW
% The Wilcoxon signed-rank test is a non-parametric alternative to paired t-tests
% that tests whether two related samples differ significantly. Unlike bootstrap 
% confidence intervals which provide estimation, Wilcoxon tests provide:
%
% ✓ Statistical significance testing (p-values)
% ✓ Effect size estimates (rank-biserial correlation r)
% ✓ Comparison of paired discretization methods
% ✓ Robustness to non-normal distributions
%
% Key advantages over bootstrap CIs:
% - Tests for significant DIFFERENCES between methods
% - No parametric assumptions required
% - Standard effect sizes suitable for meta-analysis
% - Multiple testing correction options (Bonferroni, Benjamini-Hochberg)

%% FILES IN THIS SUITE
%
% 1. wilcoxon_pairwise_full_analysis.m
%    ├─ Purpose: Comprehensive pairwise Wilcoxon tests
%    ├─ Key outputs:
%    │  ├─ P-value matrix heatmap
%    │  ├─ Z-statistics heatmap
%    │  ├─ Power output distributions
%    │  └─ CSV: wilcoxon_rmse_results.csv
%    └─ Best for: Quick overview of method differences
%
% 2. wilcoxon_effect_size_analysis.m
%    ├─ Purpose: Detailed analysis with effect sizes for multiple metrics
%    ├─ Key outputs:
%    │  ├─ Metric comparison visualization
%    │  ├─ P-value vs Effect size scatter
%    │  ├─ Tests for: RMSE, IAE, RMS Actuation, Total Variation
%    │  └─ CSV: wilcoxon_effect_size_results.csv
%    └─ Best for: Multi-metric comparison with effect interpretation
%
% 3. wilcoxon_within_wind_conditions.m
%    ├─ Purpose: Compare methods separately for each wind type
%    ├─ Key outputs:
%    │  ├─ RMSE bar plots per wind condition
%    │  ├─ Significance heatmaps per condition
%    │  ├─ Power distribution overlays
%    │  └─ CSV: wilcoxon_wind_condition_results.csv
%    └─ Best for: Understanding wind-condition-specific performance
%
% 4. wilcoxon_statistical_summary.m
%    ├─ Purpose: Publication-ready statistical summary with corrections
%    ├─ Key outputs:
%    │  ├─ Descriptive statistics table
%    │  ├─ Multiple testing corrections:
%    │  │  ├─ Raw p-values
%    │  │  ├─ Bonferroni correction
%    │  │  └─ Benjamini-Hochberg FDR
%    │  ├─ Comprehensive visualization
%    │  ├─ CSV: wilcoxon_comprehensive_results.csv
%    │  └─ CSV: wilcoxon_descriptive_statistics.csv
%    └─ Best for: Publication and final statistical reporting
%
% 5. wilcoxon_trend_analysis.m
%    ├─ Purpose: Consistency of method rankings across conditions
%    ├─ Key outputs:
%    │  ├─ Performance matrix and ranking heatmaps
%    │  ├─ Head-to-head consistency analysis
%    │  ├─ Overall winner determination
%    │  └─ CSV: wilcoxon_consistency_analysis.csv
%    │         wilcoxon_win_summary.csv
%    └─ Best for: Identifying robust "best" methods

%% QUICK START GUIDE

% Step 1: Run the comprehensive summary (recommended first)
%    >> wilcoxon_statistical_summary
%    This gives you the overall picture with corrections

% Step 2: Explore effect sizes and multiple metrics
%    >> wilcoxon_effect_size_analysis
%    Understand the magnitude of differences

% Step 3: Analyze consistency across conditions
%    >> wilcoxon_trend_analysis
%    Identify methods that are consistently good

% Step 4: Deep dive into specific wind conditions
%    >> wilcoxon_within_wind_conditions
%    Compare methods for uniform vs weibull wind

% Step 5: Detailed pairwise analysis
%    >> wilcoxon_pairwise_full_analysis
%    Examine specific method pairs in detail

%% INTERPRETING RESULTS

% P-VALUES:
% ├─ p < 0.001: Highly significant (***)
% ├─ p < 0.01:  Very significant (**)
% ├─ p < 0.05:  Significant (*)
% └─ p ≥ 0.05:  Not significant (ns)

% EFFECT SIZES (Rank-Biserial Correlation r):
% ├─ |r| < 0.1:  Negligible effect
% ├─ 0.1 ≤ |r| < 0.3:  Small effect
% ├─ 0.3 ≤ |r| < 0.5:  Medium effect
% └─ |r| ≥ 0.5:  Large effect

% Z-STATISTICS:
% ├─ Larger |Z|: More extreme difference
% ├─ Sign indicates direction (positive/negative)
% └─ Generally |Z| > 1.96 indicates p < 0.05

% MULTIPLE TESTING CORRECTIONS:
% ├─ Raw: No correction (but likely has false positives)
% ├─ Bonferroni: Very conservative, use for < 10 comparisons
% └─ BH-FDR: Balanced, recommended for > 10 comparisons

%% DATA REQUIREMENTS

% The scripts expect:
% ├─ Folder: 'ModelAnalysisOutput' (or specify in script)
% ├─ File format: .mat files with simOut object
% ├─ simOut fields:
% │  ├─ 'power_output': Time series data
% │  └─ 'theta_actuation': Control action data
% ├─ Data structure: Assumes 100 Hz sampling (dt = 0.01s)
% ├─ Transient removal: First 300 samples removed
% └─ Wind types detected: Contains 'weibull' or not

% Expected filename pattern:
%    [method]_[optional_weibull][date_time].mat
%    Examples:
%    - exponential20260125_101149.mat
%    - exponential_weibull20260125_101149.mat

%% OUTPUT FILES

% CSV Files (Spreadsheet format, easy to import):
% ├─ wilcoxon_rmse_results.csv
% │  └─ Method1 | Method2 | p_value | Z_stat | Significance
% ├─ wilcoxon_effect_size_results.csv
% │  └─ Metric | Method1 | Method2 | p_value | Z_stat | r | Cohen's d | Sig
% ├─ wilcoxon_wind_condition_results.csv
% │  └─ Wind_Type | Method1 | Method2 | p_value | Z_stat | r | Better_Method | Sig
% ├─ wilcoxon_comprehensive_results.csv
% │  └─ Comparison | p_raw | p_bonf | p_bh | Z_stat | Effect_r | Effect_Interp | Sig_Raw
% ├─ wilcoxon_descriptive_statistics.csv
% │  └─ Method | N | Mean_RMSE | Std_RMSE | Min | Max | Median | Q1 | Q3
% ├─ wilcoxon_consistency_analysis.csv
% │  └─ Method1 | Method2 | Wins_M1 | Wins_M2 | Winner | Mean_pval | Min_pval | Max_pval
% └─ wilcoxon_win_summary.csv
%    └─ Method | Wins | AvgRank

% Figure Files (.fig format in MATLAB):
% ├─ Figure 1: P-value and Z-statistic heatmaps
% ├─ Figure 2: Power distribution histograms
% ├─ Figure 3: Normalized metric comparisons
% ├─ Figure 4: P-value vs Effect size scatter
% ├─ Figure 5: Comprehensive results landscape
% ├─ Figure 6: RMSE comparisons by wind condition
% ├─ Figure 7: Wilcoxon significance matrices
% ├─ Figure 8: Power distributions
% ├─ Figure 9: Performance and rank heatmaps
% └─ Figure 10: Consistency analysis plots

%% CUSTOMIZATION

% To modify scripts for your data:
%
% 1. Change folder path:
%    folder = 'YourFolderName';
%
% 2. Change model names:
%    models = {'method1', 'method2', 'method3'};
%
% 3. Change wind types:
%    wind_types = {'condition1', 'condition2'};
%
% 4. Change reference power:
%    P_ref = 1.5;  % In MW
%
% 5. Change significance level:
%    alpha = 0.05;  % 95% confidence
%
% 6. Change metrics:
%    Add new @(x) function definitions after metric definitions section

%% COMMON ISSUES & SOLUTIONS

% Q: "No data found" error
% A: Check folder path exists and contains .mat files with correct structure
%    Verify filenames contain model names defined in 'models' array
%
% Q: Very low p-values, no variation
% A: Might indicate different scaling between samples
%    Check that power is in consistent units (MW)
%    Verify transient removal is appropriate (line: if numel(p) > 300)
%
% Q: Effect sizes all close to 0
% A: Methods might genuinely have similar performance
%    Consider combining methods or using different metrics
%    Check sample sizes are adequate (N > 30 recommended)
%
% Q: Want to test specific metrics only
% A: Modify the metrics section or create a subset:
%    Comment out metrics you don't need in metric definitions
%    Or create a custom script based on existing templates

%% STATISTICAL THEORY NOTES

% Wilcoxon Signed-Rank Test:
% ├─ Null hypothesis: Two samples have same distribution
% ├─ Alternative: Distributions differ
% ├─ Paired test: Based on differences between paired observations
% ├─ Non-parametric: No assumption of normality
% ├─ Test statistic: Sum of ranks of positive differences
% ├─ Z-transformation: Uses normal approximation for large N
% └─ Assumes: Symmetric distribution of differences

% Effect Size (Rank-Biserial Correlation):
% ├─ Formula: r = 1 - (2R / (N(N+1)))
% ├─ Where R = number of positive differences
% ├─ Range: -1 to 1 (like Pearson correlation)
% └─ Interpretation: Same as Cohen's d equivalent

% Multiple Testing Correction:
% ├─ Bonferroni: p_corrected = min(p * m, 1)
% ├─ BH-FDR: Controls false discovery rate (recommended)
% └─ Use when making many comparisons to avoid Type I errors

%% REFERENCES

% Wilcoxon, F. (1945). Individual comparisons by ranking methods. 
% Biometrics, 1(6), 80-83.
%
% Field, A., & Wilcox, R. (2017). Discovering statistics using R.
% Sage Publications. (Chapters on non-parametric tests)
%
% Benjamini, Y., & Hochberg, Y. (1995). Controlling the false discovery 
% rate: A practical and powerful approach to multiple testing. 
% Journal of the Royal Statistical Society, 57(1), 289-300.

%% VERSION HISTORY

% Version 1.0 (2026-05-02)
% ├─ Created 5-script suite
% ├─ Comprehensive statistical analysis
% └─ Publication-ready output formats

%% CONTACT & FEEDBACK

% For issues or improvements, review:
% ├─ Data format requirements
% ├─ Script configuration section
% └─ Console output for error messages

% ============================================================================
