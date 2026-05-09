% ============================================================================
% PUBLICATION-READY VISUALS: WILCOXON RMSE (FIXED LATEX LEGEND)
% ============================================================================
clear; close all; clc;
rng('default'); 

try
    projectRoot = getProjectRoot();
catch
    projectRoot = pwd;
end

%% ==================== CONFIGURATION ====================
folder = fullfile(projectRoot, 'Q-Learning/ModelAnalysisOutputSine_0_02_rad_s');
advanced_models = {'exponential', 'quadratic', 'mu_law', 'A_law'};
baseline_model = 'uniform';
wind_types = {'uniform', 'weibull'};
P_ref = 1.5;        
alpha = 0.05;       
files = dir(fullfile(folder, '*.mat'));

%% ==================== DATA EXTRACTION ====================
data_container = struct();
all_models = [{baseline_model}, advanced_models];

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
                all_p = [all_p; p(:)/1e6]; 
            catch, continue; end
        end
        if ~isempty(all_p)
            key = sprintf('%s_%s', wind_types{wi}, all_models{mi});
            data_container.(key).abs_err = abs(all_p - P_ref); 
        end
    end
end

%% ==================== WILCOXON CALCULATION vs. UNIFORM ====================
stats_results = []; 
for wi = 1:numel(wind_types)
    base_key = sprintf('%s_%s', wind_types{wi}, baseline_model);
    if ~isfield(data_container, base_key), continue; end
    err_base = data_container.(base_key).abs_err;
    
    for mi = 1:numel(advanced_models)
        test_key = sprintf('%s_%s', wind_types{wi}, advanced_models{mi});
        if ~isfield(data_container, test_key), continue; end
        err_test = data_container.(test_key).abs_err;
        
        n = min([numel(err_base), numel(err_test), 1000]);
        s_base = randsample(err_base, n);
        s_test = randsample(err_test, n);
        
        [p_val, ~, stats] = signrank(s_test, s_base);
        r = 0; if isfield(stats, 'zval'), r = stats.zval / sqrt(n); end
        stats_results = [stats_results; {wind_types{wi}, advanced_models{mi}, p_val, r}];
    end
end

%% ==================== VISUALIZATION (LATEX COMPATIBLE) ====================
fig = figure('Name', 'Wilcoxon RMSE Analysis', 'Color', 'w', 'Units', 'inches', 'Position', [1 1 8.5 5.5]);
hold on;

% Professional Blue Palette
blue_shades = [
    0.65, 0.81, 0.94;  % Exponential
    0.41, 0.65, 0.86;  % Quadratic
    0.15, 0.44, 0.70;  % Mu-Law
    0.03, 0.22, 0.45   % A-Law
];
markers = {'s', '^', 'd', 'p'};

% LaTeX formatted labels for the legend
model_labels_latex = {'Exponential', 'Quadratic', '$\mu$-Law', 'A-Law'};

% Zero line (Uniform Baseline)
yline(0, 'k-', 'LineWidth', 2, 'Color', [0.3 0.3 0.3], 'HandleVisibility', 'off');
text(0.55, 0.05, 'UNIFORM BASELINE', 'FontSize', 9, 'FontWeight', 'bold', ...
    'Color', [0.4 0.4 0.4], 'Interpreter', 'none');

% Plot markers and collect handles for legend
h = gobjects(numel(advanced_models), 1);
for mi = 1:numel(advanced_models)
    h(mi) = scatter(nan, nan, 120, blue_shades(mi,:), markers{mi}, 'Filled', 'MarkerEdgeColor', 'k');
end

for wi = 1:numel(wind_types)
    fill([wi-0.42, wi+0.42, wi+0.42, wi-0.42], [-2 -2 2 2], [0.97 0.97 0.97], ...
        'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    for mi = 1:numel(advanced_models)
        idx = strcmp(stats_results(:,1), wind_types{wi}) & strcmp(stats_results(:,2), advanced_models{mi});
        if any(idx)
            r_val = stats_results{idx, 4};
            p_val = stats_results{idx, 3};
            x_pos = wi + (mi - (numel(advanced_models)+1)/2) * 0.16;
            
            scatter(x_pos, r_val, 150, blue_shades(mi,:), markers{mi}, 'Filled', 'MarkerEdgeColor', [0.1 0.1 0.1]);
            
            if p_val < alpha
                star_y = r_val + sign(r_val)*0.05;
                text(x_pos, star_y, '*', 'FontSize', 24, 'Color', [0.8 0 0], ...
                    'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            end
        end
    end
end

% CRITICAL: SET INTERPRETER TO LATEX FOR ALL TEXT OBJECTS
set(gca, 'TickLabelInterpreter', 'latex', 'FontSize', 12);
set(gca, 'XTick', 1:numel(wind_types), 'XTickLabel', {'\textbf{UNIFORM WIND}', '\textbf{WEIBULL WIND}'});

ylabel('Wilcoxon Effect Size ($r$) [$\Delta$ RMSE]', 'Interpreter', 'latex', 'FontSize', 14);
title('RMSE Performance Shift relative to Uniform Discretization', 'Interpreter', 'latex', 'FontSize', 16);

% Fix Legend LaTeX
lgd = legend(h, model_labels_latex, 'Location', 'northeastoutside', 'Box', 'on');
set(lgd, 'Interpreter', 'latex', 'FontSize', 12);

grid on; box on; set(gca, 'Layer', 'top');
all_r = cell2mat(stats_results(:, 4));
ylim([min(all_r)-0.2, max(all_r)+0.2]);