clear;
close all;

result_data_1 = 'results/sarsa_exponential_150_episodes20251231_161906.mat';
result_data_2 = 'results/sarsa_exponential_150_episodes_weibull20260119_204005.mat';

data1 = load(result_data_1);  
ResultData1 = data1.simResults;

data2 = load(result_data_2);  
ResultData2 = data2.simResults;

% Assume 150 episodes
num_episodes = 150;
episodes = 1:num_episodes;

mean_power1 = zeros(num_episodes, 1);
std_power1  = zeros(num_episodes, 1);
mean_power2 = zeros(num_episodes, 1);
std_power2  = zeros(num_episodes, 1);

% ──────────────── Compute mean & std ────────────────
for i = 1:num_episodes
    % Dataset 1
    p = squeeze(ResultData1(i).get('power_output').Data(1,1,200:end));
    if numel(p) > 1
        mean_power1(i) = mean(p);
        std_power1(i)  = std(p);
    else
        mean_power1(i) = NaN;
        std_power1(i)  = NaN;
    end

    % Dataset 2
    p = squeeze(ResultData2(i).get('power_output').Data(1,1,200:end));
    if numel(p) > 1
        mean_power2(i) = mean(p);
        std_power2(i)  = std(p);
    else
        mean_power2(i) = NaN;
        std_power2(i)  = NaN;
    end
end

% ──────────────── Smoothing ────────────────
window_size = 10;

smoothed_mean1  = movmean(mean_power1, window_size, 'omitnan');
smoothed_upper1 = movmean(mean_power1 + std_power1, window_size, 'omitnan');
smoothed_lower1 = movmean(mean_power1 - std_power1, window_size, 'omitnan');

smoothed_mean2  = movmean(mean_power2, window_size, 'omitnan');
smoothed_upper2 = movmean(mean_power2 + std_power2, window_size, 'omitnan');
smoothed_lower2 = movmean(mean_power2 - std_power2, window_size, 'omitnan');

% ────────────────────────────────────────────────
%               Plotting
% ────────────────────────────────────────────────
figure;
set(gcf, 'Position', [100 100 880 520]);
hold on;

% Shaded STD – Dataset 1
fill([episodes, fliplr(episodes)], ...
     [smoothed_upper1; flipud(smoothed_lower1)]', ...
     [0 0.4 0.8], 'FaceAlpha', 0.18, 'EdgeColor', 'none');

p1 = plot(episodes, smoothed_mean1, 'Color', [0 0.4 0.8], ...
    'LineWidth', 2.1, 'DisplayName', 'SARSA (Exponential)');

% Shaded STD – Dataset 2
fill([episodes, fliplr(episodes)], ...
     [smoothed_upper2; flipud(smoothed_lower2)]', ...
     [0.9 0.1 0.1], 'FaceAlpha', 0.18, 'EdgeColor', 'none');

p2 = plot(episodes, smoothed_mean2, 'Color', [0.9 0.1 0.1], ...
    'LineWidth', 2.1, 'DisplayName', 'SARSA (Exponential + Weibull)');

% ──────────────── Target & ±1% band ────────────────
target_power = 1.5e6;
tol = 0.01 * target_power;

yline(target_power, '--k', 'Desired Power = 1.5 MW', ...
    'LineWidth', 1.2, 'LabelHorizontalAlignment', 'left');

% ±1% band
fill([0 num_episodes num_episodes 0], ...
     [target_power-tol target_power-tol target_power+tol target_power+tol], ...
     [0.8 0.8 0.8], 'FaceAlpha', 0.25, 'EdgeColor', 'none');

yline(target_power+tol, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
yline(target_power-tol, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1);

% ──────────────── Irreversible convergence detection ────────────────
in_band_1 = abs(smoothed_mean1 - target_power) <= tol;
in_band_2 = abs(smoothed_mean2 - target_power) <= tol;

conv_ep_1 = NaN;
conv_ep_2 = NaN;

for k = 1:num_episodes
    if in_band_1(k) && all(in_band_1(k:end))
        conv_ep_1 = k;
        break;
    end
end

for k = 1:num_episodes
    if in_band_2(k) && all(in_band_2(k:end))
        conv_ep_2 = k;
        break;
    end
end

% ──────────────── Mark convergence points ────────────────
if ~isnan(conv_ep_1)
    xline(conv_ep_1, ':', 'Color', [0 0.4 0.8], 'LineWidth', 1.6);
    plot(conv_ep_1, smoothed_mean1(conv_ep_1), 'o', ...
        'Color', [0 0.4 0.8], 'MarkerFaceColor', [0 0.4 0.8]);
    text(conv_ep_1+1, smoothed_mean1(conv_ep_1), ...
        sprintf('Ep %d', conv_ep_1), 'Color', [0 0.4 0.8]);
end

if ~isnan(conv_ep_2)
    xline(conv_ep_2, ':', 'Color', [0.9 0.1 0.1], 'LineWidth', 1.6);
    plot(conv_ep_2, smoothed_mean2(conv_ep_2), 'o', ...
        'Color', [0.9 0.1 0.1], 'MarkerFaceColor', [0.9 0.1 0.1]);
    text(conv_ep_2+1, smoothed_mean2(conv_ep_2), ...
        sprintf('Ep %d', conv_ep_2), 'Color', [0.9 0.1 0.1]);
end

% ──────────────── Cosmetics ────────────────
xlabel('Training Episode', 'FontSize', 13);
ylabel('Average Power Output (MW)', 'FontSize', 13);
title('Smoothed Mean Power per Episode ± 1 SD', 'FontSize', 14);

legend([p1 p2], 'Location', 'southeast', 'FontSize', 11);
grid on;
xlim([0 150]);
set(gca, 'YTickLabel', get(gca,'YTick')/1e6);
set(gca, 'FontSize', 11);

% Export
exportgraphics(gcf, 'power_output_comparison_std.pdf', ...
    'ContentType', 'vector', 'Resolution', 400);
