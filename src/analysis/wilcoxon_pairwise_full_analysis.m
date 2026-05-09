% WILCOXON RANK-SUM TEST: RMSE & POWER ANALYSIS
clear; close all; clc;

projectRoot = getProjectRoot();
folder = fullfile(projectRoot, 'Q-Learning', 'ModelAnalysisOutput');
models = {'exponential', 'uniform', 'quadratic', 'mu_law', 'A_law'};
wind_types = {'uniform', 'weibull'};

fontName = 'Times New Roman';
fontSize = 10;
set(groot, 'DefaultTextInterpreter', 'latex');
set(groot, 'DefaultAxesTickLabelInterpreter', 'latex');
set(groot, 'DefaultLegendInterpreter', 'latex');
files = dir(fullfile(folder, '*.mat'));

TARGET_POWER_MW = 1.5; 



data_container = struct();

sampleFile = dir(fullfile(folder, '*exponential*.mat'));
if ~isempty(sampleFile)
    sample_data = load(fullfile(folder, sampleFile(1).name));
    sample_p = squeeze(sample_data.simOut.get('power_output').Data);
    fprintf('Sample data inspection (%s):\n', sampleFile(1).name);
    fprintf('  Size: %s\n', mat2str(size(sample_p)));
    fprintf('  First 20 values: %s\n', mat2str(sample_p(1:min(20, numel(sample_p)))'));
    fprintf('  Unique values in data: %d\n', numel(unique(sample_p)));
end

for mi = 1:numel(models)
    for wi = 1:numel(wind_types)
        all_rmse = [];
        all_mean_p = [];
        loaded_files = {};
        
        for i = 1:numel(files)
            fname = files(i).name;
            if ~contains(lower(fname), lower(models{mi})), continue; end
            isWeibull = contains(lower(fname), 'weibull');
            if (wi == 2 && ~isWeibull) || (wi == 1 && isWeibull), continue; end
            
            try
                data = load(fullfile(folder, fname));
                p = squeeze(data.simOut.get('power_output').Data);
                if numel(p) > 300, p = p(300:end); end
                p = p(:) / 1e6; % Convert to MW
                
                mean_power = mean(p);
                run_rmse = sqrt(mean((p - TARGET_POWER_MW).^2)); 
                
                all_mean_p = [all_mean_p; mean_power];
                all_rmse = [all_rmse; run_rmse];
                loaded_files{end+1} = fname;
            catch
                continue; 
            end
        end
        
        if ~isempty(all_rmse)
            key = sprintf('%s_%s', models{mi}, wind_types{wi});
            data_container.(key).rmse = all_rmse; 
            data_container.(key).mean_p = all_mean_p; 
            data_container.(key).wind = wind_types{wi};
            cleanModel = upper(strrep(models{mi}, '_', '-'));
            data_container.(key).label = ['\textrm{', cleanModel, ' (', upper(wind_types{wi}(1)), ')}'];
            
            fprintf('\n%s (%s):\n', cleanModel, wind_types{wi});
            for f = 1:numel(loaded_files)
                fprintf('  %s\n', loaded_files{f});
            end
        end
    end
end

keys = fieldnames(data_container);
N = length(keys);
isUniformModel = startsWith(keys, 'uniform_');
labels = cellfun(@(k) data_container.(k).label, keys, 'UniformOutput', false);
cleanLabels = regexprep(labels, '^\\textrm\{(.*)\}$', '$1');

fprintf('\n\nDetailed Group Statistics:\n');
fprintf('Group RMSE Stats:\n');
for k = 1:N
    rmse_vals = data_container.(keys{k}).rmse;
    mean_p_vals = data_container.(keys{k}).mean_p;
    fprintf('%s: RMSE Mean=%.6f, Std=%.6f, RMSE values=[', cleanLabels{k}, mean(rmse_vals), std(rmse_vals));
    fprintf('%.6f ', rmse_vals);
    fprintf(']\n');
    fprintf('       MeanP Mean=%.6f, Std=%.6f, MeanP values=[', mean(mean_p_vals), std(mean_p_vals));
    fprintf('%.6f ', mean_p_vals);
    fprintf(']\n');
end

%% ==================== FIG 1: DUAL VIOLIN PLOT (POWER & RMSE) ====================
f1 = figure('Units', 'inches', 'Position', [1, 1, 14, 7], 'Color', 'w');
maxWidth = 0.3;

ax1 = subplot(1, 2, 1); hold(ax1, 'on');
ax2 = subplot(1, 2, 2); hold(ax2, 'on');

for k = 1:N
    % --- Plot Power ---
    yP = data_container.(keys{k}).mean_p;
    if ~isempty(yP)
        [f, xi] = ksdensity(yP, 'NumPoints', 100);
        f = f / max(f) * maxWidth;
        patch([k-f, fliplr(k+f)], [xi, fliplr(xi)], [0.3 0.5 0.9], 'FaceAlpha', 0.4, 'Parent', ax1);
        scatter(ax1, k + (rand(size(yP))-0.5)*0.05, yP, 12, [0.2 0.2 0.2], 'filled', 'MarkerFaceAlpha', 0.3);
    end
    
    % --- Plot RMSE ---
    yR = data_container.(keys{k}).rmse;
    if ~isempty(yR)
        % Using 'positive' support because RMSE cannot be < 0
        [f, xi] = ksdensity(yR, 'NumPoints', 100, 'Support', 'positive', 'BoundaryCorrection', 'reflection');
        f = f / max(f) * maxWidth;
        patch([k-f, fliplr(k+f)], [xi, fliplr(xi)], [0.8 0.3 0.3], 'FaceAlpha', 0.4, 'Parent', ax2);
        scatter(ax2, k + (rand(size(yR))-0.5)*0.05, yR, 12, [0.2 0.2 0.2], 'filled', 'MarkerFaceAlpha', 0.3);
    end
end

set(ax1, 'XTick', 1:N, 'XTickLabel', cleanLabels, 'XTickLabelRotation', 45, 'TickLabelInterpreter', 'latex');
ylabel(ax1, 'Mean Power Output [MW]', 'Interpreter', 'latex');
title(ax1, '\textbf{(a) Power Performance Distribution}', 'Interpreter', 'latex');
grid(ax1, 'on');

set(ax2, 'XTick', 1:N, 'XTickLabel', cleanLabels, 'XTickLabelRotation', 45, 'TickLabelInterpreter', 'latex');
ylabel(ax2, 'RMSE [MW]', 'Interpreter', 'latex');
title(ax2, '\textbf{(b) Tracking Error (RMSE) Distribution}', 'Interpreter', 'latex');
grid(ax2, 'on');

sgtitle('\textbf{Statistical Analysis of Discretization Models}', 'Interpreter', 'latex', 'FontSize', 14);

%% ==================== TABLE EXPORT (WILCOXON ON RMSE) ====================
fprintf('Group RMSE Stats:\n');
for k = 1:N
    rmse = data_container.(keys{k}).rmse;
    fprintf('%s: Mean=%.4f, Std=%.4f, N=%d\n', cleanLabels{k}, mean(rmse), std(rmse), numel(rmse));
end

tableData = {};

uniformIndices = find(isUniformModel);

for i = 1:numel(uniformIndices)
    uIdx = uniformIndices(i); % This is our Group A (Uniform)
    
    for j = 1:N
        if uIdx == j, continue; end
        
        % Optional: Only compare within the same wind type (e.g., Uniform-U vs Expo-U)
        % if ~strcmp(data_container.(keys{uIdx}).wind, data_container.(keys{j}).wind), continue; end

        [p_val, ~, stats] = ranksum(data_container.(keys{uIdx}).rmse, ...
                                    data_container.(keys{j}).rmse, ...
                                    'method', 'approximate');
        
        z_val = stats.zval;
        n1 = numel(data_container.(keys{uIdx}).rmse);
        n2 = numel(data_container.(keys{j}).rmse);
        r_val = abs(z_val) / sqrt(n1 + n2);
        
        if p_val < 0.001, sig = '***';
        elseif p_val < 0.01, sig = '**';
        elseif p_val < 0.05, sig = '*';
        else, sig = 'n.s.'; end
        
        tableData = [tableData; {cleanLabels{uIdx}, cleanLabels{j}, z_val, p_val, r_val, sig}];
    end
end

StatSummaryTable = cell2table(tableData, 'VariableNames', ...
    {'Reference_Group', 'Comparison_Group', 'Z_Stat', 'p_Value', 'Effect_Size_r', 'Sig'});

disp(StatSummaryTable);
writetable(StatSummaryTable, 'Wilcoxon_RMSE_Reference_Uniform.csv');