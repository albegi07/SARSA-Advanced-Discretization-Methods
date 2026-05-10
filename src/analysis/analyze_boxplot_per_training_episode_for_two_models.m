clear;
close all;

result_data_1 = 'training_results/sarsa_exponential_150_episodes20251231_161906.mat';
result_data_2 = 'training_results/sarsa_exponential_150_episodes_weibull20260118_174017.mat';

data1 = load(result_data_1);  
ResultData1 = data1.simResults;

data2 = load(result_data_2);  
ResultData2 = data2.simResults;

boxplot_x_1 = [];
boxplot_g_1 = [];


boxplot_x_2 = [];
boxplot_g_2 = [];

% Loop for ResultData1 (every 10 episodes)
for i = 1:numel(ResultData1)
    if mod(i,10) ~= 0
        continue
    end
    power_output = squeeze(ResultData1(i).get('power_output').Data(1,1,200:end));
    boxplot_x_1 = [boxplot_x_1; power_output(:)];
    boxplot_g_1 = [boxplot_g_1; i * ones(numel(power_output),1)];
end

% Loop for ResultData2 (every 10 episodes)
for i = 1:numel(ResultData2)
    if mod(i,10) ~= 0
        continue
    end
    power_output = squeeze(ResultData2(i).get('power_output').Data(1,1,200:end));
    boxplot_x_2 = [boxplot_x_2; power_output(:)];
    boxplot_g_2 = [boxplot_g_2; i * ones(numel(power_output),1)];
end


figure;

boxplot(boxplot_x_1, boxplot_g_1,'Colors', 'b', 'Widths', 0.3)
hold on
boxplot(boxplot_x_2, boxplot_g_2, 'Colors', 'r', 'Widths', 0.3)

h = yline(1.5e6, '--k', 'Desired Power = 1.5 MW', 'LineWidth', 0.6, ...
      'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment','bottom');
uistack(h, 'top');  % bring the line on top of boxplots

xlabel('Episode')
ylabel('Power Output (W)')
title('Power Output Distribution per Episode')

plot(NaN,NaN,'b','LineWidth',2);
plot(NaN,NaN,'g','LineWidth',2);
legend({'Desired output', 'Exponential','Exponential Weibull'}, 'Location','best');

