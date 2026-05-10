clear;
close all;

%% 1. Configuration & Data Loading
result_data_1 = 'training_results/sarsa_A_1_8_150_episodes_weibull20260125_181157.mat';
result_data_2 = 'training_results/sarsa_A_150_episodes_weibull20260118_183326.mat';
result_data_3 = 'training_results/sarsa_A_0_6_150_episodes_weibull20260125_181712.mat'; % Update with your filename

% Load data into a cell array for easier iteration
files = {result_data_1, result_data_2, result_data_3};
num_files = length(files);
ResultSets = cell(1, num_files);

for i = 1:num_files
    data = load(files{i});
    ResultSets{i} = data.simResults;
end

%% 2. Simulation Parameters
num_episodes = 150;
episodes = 1:num_episodes;
window_size = 10;

% Pre-allocate matrices (rows = episodes, columns = datasets)
mean_power = zeros(num_episodes, num_files);
std_power  = zeros(num_episodes, num_files);

%% 3. Data Processing
for f = 1:num_files
    for i = 1:num_episodes
        % Extract data from the f-th dataset
        power_output = squeeze(ResultSets{f}(i).get('power_output').Data(1,1,200:end));
        n = length(power_output);
        
        if n < 2
            mean_power(i, f) = NaN;
            std_power(i, f)  = NaN;
        else
            mean_power(i, f) = mean(power_output);
            std_power(i, f)  = std(power_output);
        end
    end
end

%% 4. Smoothing and Plotting Setup
colors = [
    0.0, 0.4, 0.8;  % Blue
    0.9, 0.1, 0.1;  % Red
    0.2, 0.6, 0.2   % Green
];

labels = {
    'SARSA (A=1.8)', ...
    'SARSA (A=1.016)', ...
    'SARSA (A=0.6)'
};

target_power = 1.5e6;
tol = 0.01 * target_power; % ±1% tolerance

figure;
set(gcf, 'Position', [100 100 880 520]);
hold on;

plots = gobjects(1, num_files); % Store plot handles for legend

for f = 1:num_files
    % Smooth the mean and ±1 SD bounds
    s_mean  = movmean(mean_power(:, f), window_size, 'omitnan');
    s_upper = movmean(mean_power(:, f) + std_power(:, f), window_size, 'omitnan');
    s_lower = movmean(mean_power(:, f) - std_power(:, f), window_size, 'omitnan');
    
    % Shaded SD Area
    fill([episodes, fliplr(episodes)], ...
         [s_upper; flipud(s_lower)]', ...
         colors(f, :), 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    
    % Mean Line
    plots(f) = plot(episodes, s_mean, 'Color', colors(f, :), 'LineWidth', 2.1, ...
                   'DisplayName', labels{f});
    
    % ────────────── Detect first irreversible convergence ──────────────
    in_band = abs(s_mean - target_power) <= tol;
    conv_ep = NaN;
    for k = 1:num_episodes
        if in_band(k) && all(in_band(k:end))
            conv_ep = k;
            break;
        end
    end
    
    % Mark convergence episode
    if ~isnan(conv_ep)
        xline(conv_ep, ':', 'Color', colors(f, :), 'LineWidth', 1.6);
        plot(conv_ep, s_mean(conv_ep), 'o', 'Color', colors(f, :), ...
            'MarkerFaceColor', colors(f, :));
        text(conv_ep+1, s_mean(conv_ep), sprintf('Ep %d', conv_ep), 'Color', colors(f, :));
    end
end

%% 5. Target and 1% band
% Desired power reference
yline(target_power, '--k', 'Desired Power = 1.5 MW', ...
    'LineWidth', 1.2, 'LabelHorizontalAlignment', 'left');

% Shade ±1% tolerance band
fill([0 num_episodes num_episodes 0], ...
     [target_power-tol target_power-tol target_power+tol target_power+tol], ...
     [0.8 0.8 0.8], 'FaceAlpha', 0.25, 'EdgeColor', 'none');

yline(target_power+tol, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
yline(target_power-tol, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);

%% 6. Formatting
xlabel('Training Episode', 'FontSize', 13);
ylabel('Average Power Output (MW)', 'FontSize', 13);
title('Smoothed Mean Power per Episode \pm 1 Standard Deviation', 'FontSize', 14);

legend(plots, 'Location', 'southeast', 'FontSize', 11);
grid on;
xlim([0 num_episodes]);
set(gca, 'FontSize', 11);

% Convert Y-axis to MW for readability
ticks = get(gca, 'YTick');
set(gca, 'YTickLabel', ticks/1e6);

