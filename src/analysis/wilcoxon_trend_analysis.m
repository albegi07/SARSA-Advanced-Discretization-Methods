% ============================================================================
% WILCOXON TEST TREND ANALYSIS: METHOD COMPARISON ACROSS CONDITIONS
% ============================================================================
% Analyzes trends in performance differences between discretization methods
% across multiple wind conditions and identifies consistent winners
% ============================================================================
clear; close all; clc;

% Resolve project root
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
fprintf('TREND ANALYSIS: METHOD COMPARISONS ACROSS CONDITIONS\n');
fprintf('==================================================\n\n');

%% ==================== METRIC DEFINITIONS ====================
rmse  = @(p) sqrt(mean((p-P_ref).^2));

%% ==================== DATA EXTRACTION ====================
fprintf('Extracting data from all conditions...\n');
all_data = struct();

for mi = 1:numel(models)
    for wi = 1:numel(wind_types)
        all_p = [];
        
        for i = 1:numel(files)
            fname = files(i).name;
            if ~contains(lower(fname), lower(models{mi})), continue; end
            isWeibull = contains(lower(fname), 'weibull');
            if (wi == 2 && ~isWeibull) || (wi == 1 && isWeibull), continue; end
            
            try
                data = load(fullfile(folder, fname));
                if ~isfield(data, 'simOut'), continue; end
                
                p_raw = data.simOut.get('power_output').Data;
                p = squeeze(p_raw);
                
                if numel(p) > 300
                    p = p(300:end);
                end
                
                p = p / 1e6; % MW
                all_p = [all_p; p(:)];
                
            catch
                continue;
            end
        end
        
        if ~isempty(all_p)
            key = sprintf('%s_%s', models{mi}, wind_types{wi});
            all_data.(key).power = all_p;
            all_data.(key).model = models{mi};
            all_data.(key).wind = wind_types{wi};
        end
    end
end

keys = fieldnames(all_data);

%% ==================== PERFORMANCE MATRIX ====================
fprintf('\nBuilding performance matrix...\n');
perf_matrix = nan(numel(models), numel(wind_types));
rank_matrix = nan(size(perf_matrix));

for mi = 1:numel(models)
    for wi = 1:numel(wind_types)
        key = sprintf('%s_%s', models{mi}, wind_types{wi});
        if isfield(all_data, key)
            perf_matrix(mi, wi) = rmse(all_data.(key).power);
        end
    end
end

% Rank within each condition (1=best)
for wi = 1:numel(wind_types)
    valid_idx = ~isnan(perf_matrix(:, wi));
    if any(valid_idx)
        [~, sorted_idx] = sort(perf_matrix(valid_idx, wi));
        rank_vals = nan(sum(valid_idx), 1);
        rank_vals(sorted_idx) = 1:sum(valid_idx);
        rank_matrix(valid_idx, wi) = rank_vals;
    end
end

disp(array2table(perf_matrix, 'RowNames', models, 'VariableNames', wind_types));

%% ==================== PAIRWISE CONSISTENCY ANALYSIS ====================
fprintf('\n==================================================\n');
fprintf('CONSISTENCY ACROSS CONDITIONS\n');
fprintf('==================================================\n\n');

consistency_results = cell(0, 8);
result_idx = 1;

for m1 = 1:numel(models)
    for m2 = m1+1:numel(models)
        wins_m1 = 0;
        wins_m2 = 0;
        pvals = nan(numel(wind_types), 1);
        
        fprintf('[%s vs %s]\n', models{m1}, models{m2});
        
        for wi = 1:numel(wind_types)
            key1 = sprintf('%s_%s', models{m1}, wind_types{wi});
            key2 = sprintf('%s_%s', models{m2}, wind_types{wi});
            
            if isfield(all_data, key1) && isfield(all_data, key2)
                p1 = all_data.(key1).power;
                p2 = all_data.(key2).power;
                
                % Use Rank-Sum for independence and varying lengths
                [p_val, ~] = ranksum(p1, p2, 'alpha', alpha);
                pvals(wi) = p_val;
                
                rmse1 = rmse(p1);
                rmse2 = rmse(p2);
                
                if rmse1 < rmse2
                    wins_m1 = wins_m1 + 1;
                else
                    wins_m2 = wins_m2 + 1;
                end
                
                sig_tag = ''; if p_val < 0.05, sig_tag = '*'; end
                fprintf('  %s: p=%.4f %s\n', wind_types{wi}, p_val, sig_tag);
            end
        end
        
        % Store results
        consistency_results{result_idx, 1} = models{m1};
        consistency_results{result_idx, 2} = models{m2};
        consistency_results{result_idx, 3} = wins_m1;
        consistency_results{result_idx, 4} = wins_m2;
        
        if wins_m1 > wins_m2, winner = models{m1};
        elseif wins_m2 > wins_m1, winner = models{m2};
        else, winner = 'Tied'; end
        
        consistency_results{result_idx, 5} = winner;
        consistency_results{result_idx, 6} = mean(pvals, 'omitnan');
        consistency_results{result_idx, 7} = min(pvals, [], 'omitnan');
        consistency_results{result_idx, 8} = max(pvals, [], 'omitnan');
        result_idx = result_idx + 1;
    end
end

%% ==================== WIN/LOSS ANALYSIS ====================
win_counts = zeros(numel(models), 1);
for i = 1:size(consistency_results, 1)
    winner = consistency_results{i, 5};
    if ~strcmp(winner, 'Tied')
        idx = find(strcmp(models, winner));
        win_counts(idx) = win_counts(idx) + 1;
    end
end

summary_table = table();
for m = 1:numel(models)
    summary_table.Method(m) = {models{m}};
    summary_table.Total_HeadToHead_Wins(m) = win_counts(m);
    summary_table.AvgRank(m) = mean(rank_matrix(m, :), 'omitnan');
end
summary_table = sortrows(summary_table, 'AvgRank', 'ascend');
fprintf('\nWINNER SUMMARY (By Rank):\n');
disp(summary_table);

%% ==================== VISUALIZATIONS ====================
figure('Position', [100 100 1100 500], 'Color', 'w');

% Performance Heatmap
subplot(1, 2, 1);
imagesc(perf_matrix);
colormap(gca, 'hot'); colorbar;
set(gca, 'XTick', 1:numel(wind_types), 'XTickLabel', wind_types, 'YTick', 1:numel(models), 'YTickLabel', models);
title('RMSE Performance Heatmap');

% Rank Heatmap
subplot(1, 2, 2);
imagesc(rank_matrix);
colormap(gca, 'summer'); colorbar;
set(gca, 'XTick', 1:numel(wind_types), 'XTickLabel', wind_types, 'YTick', 1:numel(models), 'YTickLabel', models);
title('Ranking (1=Best)');

%% ==================== SAVE RESULTS ====================
consistency_table = cell2table(consistency_results, 'VariableNames', ...
    {'Method1', 'Method2', 'Wins_M1', 'Wins_M2', 'Winner', 'Mean_P', 'Min_P', 'Max_P'});
writetable(consistency_table, 'wilcoxon_consistency_analysis.csv');
writetable(summary_table, 'wilcoxon_win_summary.csv');
fprintf('\nAnalysis complete. Files saved.\n');