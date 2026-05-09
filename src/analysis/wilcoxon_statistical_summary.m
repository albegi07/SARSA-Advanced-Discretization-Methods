% ============================================================================
% TARGETED WILCOXON STATISTICAL SUMMARY (UNIFORM BASELINE ONLY)
% ============================================================================
clear; close all; clc;

% --- Data Path Setup ---
try
    projectRoot = getProjectRoot();
catch
    projectRoot = pwd; 
end
folder = fullfile(projectRoot, 'Q-Learning/ModelAnalysisOutput');
if ~exist(folder, 'dir'), error('Folder not found: %s', folder); end

% --- CONFIGURATION ---
baseline_model = 'uniform';
test_models = {'exponential', 'quadratic', 'mu_law', 'A_law'};
wind_types = {'uniform', 'weibull'};
P_ref = 1.5; 
alpha = 0.05;

%% ==================== DATA EXTRACTION ====================
data_container = struct();
all_models = [{baseline_model}, test_models];
files = dir(fullfile(folder, '*.mat'));

for mi = 1:numel(all_models)
    for wi = 1:numel(wind_types)
        all_p = [];
        for i = 1:numel(files)
            fname = files(i).name;
            if ~contains(lower(fname), lower(all_models{mi})), continue; end
            isWeibull = contains(lower(fname), 'weibull');
            if (wi == 2 && ~isWeibull) || (wi == 1 && isWeibull), continue; end
            
            try
                data = load(fullfile(folder, fname));
                p = squeeze(data.simOut.get('power_output').Data);
                if numel(p) > 300, p = p(300:end); end
                all_p = [all_p; p(:) / 1e6];
            catch; continue; end
        end
        if ~isempty(all_p)
            key = sprintf('%s_%s', all_models{mi}, wind_types{wi});
            data_container.(key).power = all_p;
        end
    end
end

%% ==================== TARGETED COMPARISONS ====================
results = table();
row = 1;
for wi = 1:numel(wind_types)
    w_type = wind_types{wi};
    base_key = sprintf('%s_%s', baseline_model, w_type);
    if ~isfield(data_container, base_key), continue; end
    
    for mi = 1:numel(test_models)
        test_key = sprintf('%s_%s', test_models{mi}, w_type);
        if ~isfield(data_container, test_key), continue; end
        
        [p_val, ~, stats] = ranksum(data_container.(base_key).power, data_container.(test_key).power);
        r = stats.zval / sqrt(numel(data_container.(base_key).power) + numel(data_container.(test_key).power));
        
        results.WindType{row} = w_type;
        results.Comparison{row} = sprintf('%s vs %s', baseline_model, test_models{mi});
        results.p_raw(row) = p_val;
        results.Effect_r(row) = r;
        row = row + 1;
    end
end

if isempty(results), error('No comparison data found. Check file naming.'); end
results.p_bonf = min(results.p_raw * height(results), 1);

%% ==================== PUBLICATION-READY PLOT ====================
% Use 'figure' without invisible modifiers to ensure it renders
figure('Color', 'w', 'Name', 'Statistical Analysis');
colors = [0.15 0.35 0.55; 0.85 0.45 0.25]; % Deep Blue and Burnt Orange

% Bar Chart
b = bar(results.Effect_r, 'FaceColor', 'flat');
for k = 1:height(results)
    b.CData(k,:) = colors(1 + strcmp(results.WindType{k}, 'weibull'), :);
end

% Visual Refinement
ax = gca;
ax.GridLineStyle = ':';
ax.GridAlpha = 0.4; % Fixed the 'Alpha' error
grid on;

ylabel('Effect Size (r)', 'FontWeight', 'bold');
set(ax, 'XTick', 1:height(results), 'XTickLabel', results.Comparison, 'TickLabelInterpreter', 'none');
xtickangle(45);

% Significance stars
hold on;
for i = 1:height(results)
    if results.p_bonf(i) < 0.05
        text(i, results.Effect_r(i) + sign(results.Effect_r(i))*0.02, '*', ...
            'HorizontalAlignment', 'center', 'FontSize', 15);
    end
end

% Clean Legend
h = [patch(NaN,NaN,colors(1,:)), patch(NaN,NaN,colors(2,:))];
legend(h, {'Uniform Wind', 'Weibull Wind'}, 'Location', 'best', 'Box', 'off');
title('Performance Comparison vs. Uniform Baseline');

disp('Results Table:');
disp(results);

