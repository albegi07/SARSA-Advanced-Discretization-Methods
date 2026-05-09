clear;
close all;

result_data = 'results/results_20251223_194027.mat';

data = load(result_data);  
ResultData = data.simResults;

boxplot_x = [];
boxplot_g = [];

for i = 1:numel(ResultData)
    power_output = squeeze(ResultData(i).get('power_output').Data(1,1,200:end));
    boxplot_x = [boxplot_x; power_output(:)];
    boxplot_g = [boxplot_g; i * ones(numel(power_output),1)];
end

figure;

boxplot(boxplot_x, boxplot_g,'Colors', 'b', 'Widths', 0.3)
hold on
h = yline(1.5e6, '--r', 'Desired Power = 1.5 MW', 'LineWidth', 2, ...
      'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment','bottom');
uistack(h, 'top');  % bring the line on top of boxplots

xlabel('Episode')
ylabel('Power Output')
title('Power Output Distribution per Episode')

plot(NaN,NaN,'b','LineWidth',2);
legend({'Result 1', 'Desired output'}, 'Location','best');

