clear;
close all;

% Load result files
result_data_1 = 'Output/exponential.mat';
result_data_2 = 'Output/uniform.mat';
result_data_3 = 'Output/quadratic.mat';
result_mu_law = 'Output/mu_law.mat';
result_A_law  = 'Output/A_law.mat';

data1 = load(result_data_1);
data2 = load(result_data_2);
data3 = load(result_data_3);
data_mu = load(result_mu_law);
data_A  = load(result_A_law);

ResultData1 = data1.simOut;
ResultData2 = data2.simOut;
ResultData3 = data3.simOut;
ResultMuLaw = data_mu.simOut;
ResultALaw  = data_A.simOut;

idx = 1;   % Ignore transient

% Extract power (MW) and time for EACH case
sig1 = ResultData1.get('power_output');
p1 = squeeze(sig1.Data(1,1,idx:end)) / 1e6;
t1 = sig1.Time(idx:end);

sig2 = ResultData2.get('power_output');
p2 = squeeze(sig2.Data(1,1,idx:end)) / 1e6;
t2 = sig2.Time(idx:end);

sig3 = ResultData3.get('power_output');
p3 = squeeze(sig3.Data(1,1,idx:end)) / 1e6;
t3 = sig3.Time(idx:end);

sig4 = ResultMuLaw.get('power_output');
p4 = squeeze(sig4.Data(1,1,idx:end)) / 1e6;
t4 = sig4.Time(idx:end);

sig5 = ResultALaw.get('power_output');
p5 = squeeze(sig5.Data(1,1,idx:end)) / 1e6;
t5 = sig5.Time(idx:end);

% Plot
figure;
plot(t1, p1, 'LineWidth', 1.2); hold on;
plot(t2, p2, 'LineWidth', 1.2);
plot(t3, p3, 'LineWidth', 1.2);
plot(t4, p4, 'LineWidth', 1.2);
plot(t5, p5, 'LineWidth', 1.2);
grid on;

xlabel('Time (s)');
ylabel('Power Output (MW)');
title('Power Output vs Time for Different Distributions');

legend( ...
    'Exponential', ...
    'Uniform', ...
    'Quadratic', ...
    'Mu-Law', ...
    'A-Law', ...
    'Location', 'best' ...
);
