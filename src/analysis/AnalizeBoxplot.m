clear;
close all;

result_data_1 = 'results/sarsa_exponential_150_episodes20251231_161906.mat';

data1 = load(result_data_1);  
ResultData1 = data1.simResults;


boxplot_x_1 = [];
boxplot_g_1 = [];

% Loop for ResultData1 (every 10 episodes)
for i = 1:numel(ResultData1)
    if mod(i,10) ~= 0
        continue
    end
    power_output = squeeze(ResultData1(i).get('power_output').Data(1,1,200:end));
    boxplot_x_1 = [boxplot_x_1; power_output(:)];
    boxplot_g_1 = [boxplot_g_1; i * ones(numel(power_output),1)];
end



figure;

boxplot(boxplot_x_1, boxplot_g_1,'Colors', 'b', 'Widths', 0.3)
hold on

h = yline(1.5e6, '--k', 'Desired Power = 1.5 MW', 'LineWidth', 0.6, ...
      'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment','bottom');
uistack(h, 'top');  % bring the line on top of boxplots

xlabel('Episode')
ylabel('Power Output (W)')
title('Power Output Distribution per Episode')

plot(NaN,NaN,'b','LineWidth',2);
legend({'Desired output', 'Training results'}, 'Location','best');

