clear; close all; clc;
projectRoot = getProjectRoot();

%% Configuration & Setup
% Folder name from your image
folder = fullfile(projectRoot, 'mu_comparison'); 

% Define the three methods identified in the file names
methods = {'mu_weibull_5020', 'mu_weibull_10020', 'mu_weibull_409620'};
method_labels = {'\mu=50', '\mu=100', '\mu=4096'};

files = dir(fullfile(folder, 'mu_weibull_*.mat'));

P_ref = 1.5;         
nBoot = 1000;        
alpha = 0.05;        

% Pre-allocate for 3 methods (1 column for each method)
rmse_mean = nan(numel(methods), 1);
ci_lower  = nan(numel(methods), 1);
ci_upper  = nan(numel(methods), 1);

fprintf('Processing files...\n');

%% Data Extraction Loop
for mi = 1:numel(methods)
    all_p = [];
    current_tag = methods{mi};
    
    for i = 1:numel(files)
        fname = files(i).name;
        
        % Match the specific method tag in the filename
        if ~contains(fname, current_tag), continue; end
        
        try
            data = load(fullfile(folder, fname));
            % Access simOut variable
            p = squeeze(data.simOut.get('power_output').Data);
            
            % Remove transient (first 300 indices)
            if numel(p) > 300, p = p(300:end); end
            
            % Accumulate data (assuming multiple files per tag might exist)
            all_p = [all_p; p(:) / 1e6]; % Convert to MW
        catch
            continue; 
        end
    end
    
    if isempty(all_p)
        warning('No data found for tag: %s', current_tag);
        continue; 
    end
    
    % Bootstrap RMSE Calculation
    rmse_func = @(x) sqrt(mean((x - P_ref).^2));
    rmse_mean(mi) = rmse_func(all_p);
    
    bootstat = bootstrp(nBoot, rmse_func, all_p);
    ci = quantile(bootstat, [alpha/2, 1 - alpha/2]);
    ci_lower(mi) = ci(1);
    ci_upper(mi) = ci(2);
end

%% Visualization 1: Single Group Bar (Absolute RMSE)
figure('Color','w','Name','RMSE_Bar_Chart','Position', [200 200 500 450]);
b = bar(rmse_mean, 'FaceColor', 'flat', 'EdgeColor', 'none');

% Assign a unique color to each bar
b.CData(1,:) = [0.2 0.4 0.6]; % Blueish
b.CData(2,:) = [0.8 0.3 0.3]; % Reddish
b.CData(3,:) = [0.3 0.7 0.3]; % Greenish

hold on;
% Plot Error Bars
errorbar(1:numel(methods), rmse_mean, rmse_mean - ci_lower, ...
    ci_upper - rmse_mean, 'k.', 'LineWidth', 1.5);

set(gca, 'XTickLabel', method_labels, 'FontName', 'Times New Roman');
ylabel('RMSE [MW]'); 
grid on;
title('Method Comparison: RMSE with 95% Bootstrap CI');

%% Visualization 2: Polar Performance Plot
% Normalizing against Method 0.6 as the baseline (1.0)
baseline_idx = 1; 
efficiency = rmse_mean(baseline_idx) ./ rmse_mean;

% Close the circle for the polar plot
theta = linspace(0, 2*pi, numel(methods) + 1);
data_plot = [efficiency; efficiency(1)];

figure('Color','w','Name','Radar_Efficiency');
pax = polaraxes;
hold on;

polarplot(pax, theta, data_plot, '-o', 'LineWidth', 2.5, ...
    'Color', [0.4 0.2 0.6], 'MarkerFaceColor', [0.4 0.2 0.6]);

% Formatting Polar Axes
pax.ThetaTick = rad2deg(theta(1:end-1));
pax.ThetaTickLabel = method_labels;
pax.RTickLabel = cellstr(num2str(pax.RTick', '%.2f')); 
pax.GridAlpha = 0.3;

title({'Relative Efficiency (1.0 = Baseline: 0.6)', 'Larger Area = Better Performance'}, ...
    'FontSize', 12, 'FontName', 'Times New Roman');