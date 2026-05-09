clear;
close all;

result_data_1 = 'Output/exponential.mat';
result_data_2 = 'Output/uniform.mat';
result_data_3 = 'Output/quadratic.mat';
result_mu_law= 'Output/mu_law.mat';
result_A_law= 'Output/A_law.mat';

data1 = load(result_data_1);  
ResultData1 = data1.simOut;

data2 = load(result_data_2);  
ResultData2 = data2.simOut;

data3 = load(result_data_3);  
ResultData3 = data3.simOut;

data_mu_law = load(result_mu_law);  
ResultMuLaw= data_mu_law.simOut;

data_A_law = load(result_A_law);  
ResultALaw= data_A_law.simOut;

power_output_1 = squeeze(ResultData1.get('power_output').Data(1,1,200:end));
power_output_2 = squeeze(ResultData2.get('power_output').Data(1,1,200:end));
power_output_3 = squeeze(ResultData3.get('power_output').Data(1,1,200:end));
power_output_mu_law = squeeze(ResultMuLaw.get('power_output').Data(1,1,200:end));
power_output_A_law = squeeze(ResultALaw.get('power_output').Data(1,1,200:end));

% Convert from Watts to Megawatts
power_output_1 = power_output_1 / 1e6;
power_output_2 = power_output_2 / 1e6;
power_output_3 = power_output_3 / 1e6;
power_output_mu_law = power_output_mu_law / 1e6;
power_output_A_law = power_output_A_law / 1e6;

% Combine data
all_power = [power_output_1(:); power_output_2(:); power_output_3(:); power_output_mu_law(:); power_output_A_law(:)];

% Group labels
group = [ ...
    repmat({'Exponential'}, numel(power_output_1), 1); ...
    repmat({'Uniform'}, numel(power_output_2), 1); ...
    repmat({'Quadratic'}, numel(power_output_3), 1); ...
    repmat({'Mu-Law'}, numel(power_output_mu_law), 1); ...
    repmat({'A-Law'}, numel(power_output_A_law), 1) ...
];

% Plot boxplots
figure;
boxplot(all_power, group);
grid on;

ylabel('Power Output (MW)');
title('Comparison of Power Output Distributions');
