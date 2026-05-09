clear; close all; clc;
projectRoot = getProjectRoot();

%% Configuration & Setup
folder = fullfile(projectRoot, 'Q-Learning/ModelAnalysisOutput');
models = {'exponential', 'uniform', 'quadratic', 'mu_law', 'A_law'};
wind_types = {'Uniform Wind', 'Weibull Wind'}; 
files = dir(fullfile(folder, '*.mat'));
P_ref = 1.5;         
nBoot = 1000;        
alpha = 0.05;        
rmse_mean = nan(numel(models), numel(wind_types));
ci_lower  = nan(numel(models), numel(wind_types));
ci_upper  = nan(numel(models), numel(wind_types));

fprintf('Processing files...\n');

%% Data Extraction Loop
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
                p = squeeze(data.simOut.get('power_output').Data);
                if numel(p) > 300, p = p(300:end); end
                all_p = [all_p; p(:) / 1e6];
            catch, continue; end
        end
        if isempty(all_p), continue; end
        
        rmse_func = @(x) sqrt(mean((x - P_ref).^2));
        rmse_mean(mi, wi) = rmse_func(all_p);
        
        % Bootstrap for CI
        bootstat = bootstrp(nBoot, rmse_func, all_p);
        ci = quantile(bootstat, [alpha/2, 1 - alpha/2]);
        ci_lower(mi, wi) = ci(1);
        ci_upper(mi, wi) = ci(2);
    end
end

%% Visualization 1: Grouped Bar (Absolute RMSE)
figure('Color','w','Name','RMSE_Bar_Chart','Position', [100, 100, 600, 500]);
b = bar(rmse_mean, 'grouped', 'EdgeColor', 'none');
hold on;
colors = [0.2 0.4 0.6; 0.8 0.3 0.3]; % Blue for Uniform, Red for Weibull
for k = 1:numel(b), b(k).FaceColor = colors(k,:); end

for k = 1:numel(wind_types)
    xOffset = b(k).XEndPoints;
    errorbar(xOffset, rmse_mean(:,k), rmse_mean(:,k)-ci_lower(:,k), ...
        ci_upper(:,k)-rmse_mean(:,k), 'k.', 'LineWidth', 1.2);
end

set(gca, 'XTickLabel', models, 'TickLabelInterpreter', 'none');
ylabel('RMSE [MW]'); 
grid on;
legend(wind_types);
title('Model Comparison: RMSE (Lower is Better)');

%% Visualization 2: Corrected Radar Plot
% Find index for the baseline (Uniform model)
idx_uni = find(strcmp(models, 'uniform'));

if ~isempty(idx_uni)
    figure('Color','w','Name','Radar_Efficiency','Position', [750, 100, 600, 500]);
    
    % FIX: Calculate efficiency relative to a SINGLE global baseline
    % We use the Uniform Model + Uniform Wind as the 1.0 standard.
    % This ensures lower RMSE always results in higher Efficiency.
    baseline_val = rmse_mean(idx_uni, 1); 
    efficiency = baseline_val ./ rmse_mean;
    
    theta = linspace(0, 2*pi, numel(models) + 1);
    pax = polaraxes;
    hold on;
    
    for wi = 1:numel(wind_types)
        % Close the loop for the radar plot
        data_plot = [efficiency(:, wi); efficiency(1, wi)];
        
        polarplot(pax, theta, data_plot, '-o', 'LineWidth', 2.5, ...
            'Color', colors(wi, :), 'MarkerFaceColor', colors(wi, :));
    end
    
    % Formatting Polar Axes
    pax.ThetaTick = rad2deg(theta(1:end-1));
    pax.ThetaTickLabel = models;
    % Fix: Ensure RTicks are visible and sensible
    pax.GridAlpha = 0.2;
    set(gca, 'TickLabelInterpreter', 'none');
    
    title({'Relative Efficiency (Normalized to Uniform/Uniform Baseline)', ...
           'Larger Area = Better Performance (Lower RMSE)'}, 'FontSize', 11);
    legend(wind_types, 'Location', 'southoutside', 'Orientation', 'horizontal');
end