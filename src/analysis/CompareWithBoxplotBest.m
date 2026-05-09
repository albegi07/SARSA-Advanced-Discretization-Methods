clear;
close all;

projectRoot = getProjectRoot();
addpath(genpath(fullfile(projectRoot, 'src')));

% Directory containing the new results
data_dir = fullfile(projectRoot, 'BestMethodsComparison');

% Get all .mat files in the directory
files = dir(fullfile(data_dir, '*.mat'));

% Initialize cell arrays to store power output for each method
power_exp = {};
power_quad = {};
power_a = {};

% Loop through all files
for i = 1:length(files)
    filename = files(i).name;
    fullpath = fullfile(data_dir, filename);
    
    % Load the file
    data = load(fullpath);
    simOut = data.simOut;  
    
    % Extract power_output, trim to after transient (from time step 200 onward)
    power_raw = squeeze(simOut.get('power_output').Data(1,1,200:end));
    
    % Convert to Megawatts
    power_mw = power_raw / 1e6;
    
    % Classify and store
    if contains(lower(filename), 'exponential')
        power_exp{end+1} = power_mw(:);
    elseif contains(lower(filename), 'quadratic')
        power_quad{end+1} = power_mw(:);  
    elseif contains(lower(filename), {'a_law', 'alaw', 'a-law'})
        power_a{end+1} = power_mw(:);
    else
        warning('File %s does not match any known method - skipped.', filename);
    end
end

% Combine all individual runs into one vector per method
all_power_exp = vertcat(power_exp{:});
all_power_quad = vertcat(power_quad{:});
all_power_a = vertcat(power_a{:});

% Total combined data and group labels
all_power = [all_power_exp; all_power_quad; all_power_a];
group = [ ...
    repmat({'Exponential'}, numel(all_power_exp), 1); ...
    repmat({'Quadratic'}, numel(all_power_quad), 1); ...
    repmat({'A-Law'}, numel(all_power_a), 1) ...
];

% Create boxplot
figure;
h = boxplot(all_power, group, 'OutlierSize', 4, 'Symbol', 'o', 'Widths', 0.6);
grid on;
ylabel('Power Output (MW)');
xlabel('Discretization Method');
title('Comparison of Power Output Distributions Across Multiple Runs');

% Publication-ready styling
set(gca, 'FontSize', 12, 'LineWidth', 1);
box on;

% Add mean markers
hold on;
means = [mean(all_power_exp), mean(all_power_quad), mean(all_power_a)];
% Plotting means and storing the handle for a cleaner legend
p_mean = plot(1:3, means, 'd', 'MarkerSize', 8, 'MarkerFaceColor', 'red', 'MarkerEdgeColor', 'black');

% UPDATED LEGEND: This targets only the mean marker and places it inside to save space
legend(p_mean, 'Mean', 'Location', 'northeast'); 
hold off;

% Target value
target = 1.5;

% Calculate RMSE for each method
rmse_exp = sqrt(mean((all_power_exp - target).^2));
rmse_quad = sqrt(mean((all_power_quad - target).^2));
rmse_a = sqrt(mean((all_power_a - target).^2));

% Display results
fprintf('RMSE from 1.5MW:\n');
fprintf('Exponential: %.4f\n', rmse_exp);
fprintf('Quadratic:   %.4f\n', rmse_quad);
fprintf('A-Law:       %.4f\n', rmse_a);

% Identify the winner
[~, idx] = min([rmse_exp, rmse_quad, rmse_a]);
methods = {'Exponential', 'Quadratic', 'A-Law'};
fprintf('\n** The most consistent method is: %s **\n', methods{idx});