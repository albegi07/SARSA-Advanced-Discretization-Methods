% ============================================================================
% WILCOXON TESTS: METHOD COMPARISON WITHIN WIND CONDITIONS (FIXED)
% ============================================================================
clear; close all; clc;

try
    projectRoot = getProjectRoot();
catch
    projectRoot = pwd;
end

%% ==================== CONFIGURATION ====================
folder = fullfile(projectRoot, 'Q-Learning/ModelAnalysisOutput');
models = {'exponential', 'uniform', 'quadratic', 'mu_law', 'A_law'};
wind_types = {'uniform', 'weibull'};
P_ref = 1.5;        % Reference power [MW]
alpha = 0.05;       % Significance level
files = dir(fullfile(folder, '*.mat'));

fprintf('==================================================\n');
fprintf('WILCOXON TESTS WITHIN WIND CONDITIONS\n');
fprintf('==================================================\n\n');

%% ==================== METRIC DEFINITIONS ====================
rmse_func = @(p) sqrt(mean((p-P_ref).^2));

%% ==================== DATA EXTRACTION ====================
fprintf('Extracting data...\n');
data_by_wind = struct();
for wi = 1:numel(wind_types)
    wind_key = sprintf('wind_%s', wind_types{wi});
    data_by_wind.(wind_key) = struct();
    
    for mi = 1:numel(models)
        all_p = [];
        for i = 1:numel(files)
            fname = files(i).name;
            if ~contains(lower(fname), lower(models{mi})), continue; end
            isWeibull = contains(lower(fname), 'weibull');
            if (wi == 2 && ~isWeibull) || (wi == 1 && isWeibull), continue; end
            
            try
                data = load(fullfile(folder, fname));
                p = squeeze(data.simOut.get('power_output').Data);
                if numel(p) > 300, p = p(300:end); end
                all_p = [all_p; p(:)/1e6]; % Convert to MW
            catch; continue; end
        end
        
        if ~isempty(all_p)
            data_by_wind.(wind_key).(models{mi}).power = all_p;
        end
    end
end

%% ==================== WILCOXON TESTS PER WIND TYPE ====================
all_test_results = cell(0, 8);
test_idx = 1;

for wi = 1:numel(wind_types)
    wind_key = sprintf('wind_%s', wind_types{wi});
    wind_data = data_by_wind.(wind_key);
    methods = fieldnames(wind_data);
    N_methods = numel(methods);
    
    fprintf('\n--- WIND TYPE: %s ---\n', wind_types{wi});
    
    for i = 1:N_methods
        for j = i+1:N_methods
            p1 = wind_data.(methods{i}).power;
            p2 = wind_data.(methods{j}).power;
            
            % FIXED: Switched to ranksum (Mann-Whitney U) 
            % No resampling needed, handles unequal lengths perfectly
            [p_val, ~, stats] = ranksum(p1, p2, 'alpha', alpha);
            
            % Effect size (Rank-biserial correlation approximation for ranksum)
            r = stats.zval / sqrt(numel(p1) + numel(p2));
            
            % Significance Tag
            if p_val < 0.001, sig = '***';
            elseif p_val < 0.01, sig = '**';
            elseif p_val < 0.05, sig = '*';
            else, sig = 'ns'; end
            
            % RMSE Comparison
            r1 = rmse_func(p1); r2 = rmse_func(p2);
            better = methods{i}; if r2 < r1, better = methods{j}; end
            
            fprintf('  [%s vs %s] p=%.4f %s | Better: %s\n', ...
                methods{i}, methods{j}, p_val, sig, better);
            
            all_test_results(test_idx, :) = {wind_types{wi}, methods{i}, methods{j}, ...
                p_val, stats.zval, r, better, sig};
            test_idx = test_idx + 1;
        end
    end
end

%% ==================== VISUALIZATION: SIGNIFICANCE MATRIX ====================
figure('Position', [100 200 1100 500], 'Color', 'w');
for wi = 1:numel(wind_types)
    wind_key = sprintf('wind_%s', wind_types{wi});
    wind_data = data_by_wind.(wind_key);
    methods = fieldnames(wind_data);
    N_methods = numel(methods);
    
    p_matrix = nan(N_methods, N_methods);
    for i = 1:N_methods
        for j = 1:N_methods
            if i == j, p_matrix(i,j) = 1; continue; end
            p1 = wind_data.(methods{i}).power;
            p2 = wind_data.(methods{j}).power;
            p_matrix(i,j) = ranksum(p1, p2);
        end
    end
    
    subplot(1, 2, wi);
    imagesc(p_matrix);
    colormap(gca, 'hot'); colorbar; clim([0 0.1]);
    set(gca, 'XTick', 1:N_methods, 'XTickLabel', methods, 'YTick', 1:N_methods, 'YTickLabel', methods, 'TickLabelInterpreter', 'none');
    xtickangle(45);
    title(sprintf('P-values: %s Wind', wind_types{wi}));
    
    % Annotations
    for i = 1:N_methods
        for j = 1:N_methods
            if i ~= j
                text(j, i, sprintf('%.3f', p_matrix(i,j)), 'Color', 'w', ...
                    'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 8);
            end
        end
    end
end

%% ==================== SUMMARY & SAVE ====================
results_table = cell2table(all_test_results, 'VariableNames', ...
    {'Wind_Type', 'Method1', 'Method2', 'p_value', 'Z', 'r', 'Better_Method', 'Sig'});
writetable(results_table, 'wilcoxon_wind_condition_results.csv');
fprintf('\nDone. Results saved to CSV.\n');