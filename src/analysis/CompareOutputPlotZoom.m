clear;
close all;
clc;

% -----------------------------
% Load result files
% -----------------------------
result_data_1 = 'Output/exponential.mat';
result_data_2 = 'Output/uniform.mat';
result_data_3 = 'Output/quadratic.mat';
result_mu_law = 'Output/mu_law.mat';
result_A_law  = 'Output/A_law.mat';

data1   = load(result_data_1);
data2   = load(result_data_2);
data3   = load(result_data_3);
data_mu = load(result_mu_law);
data_A  = load(result_A_law);

ResultData1 = data1.simOut;
ResultData2 = data2.simOut;
ResultData3 = data3.simOut;
ResultMuLaw = data_mu.simOut;
ResultALaw  = data_A.simOut;

% -----------------------------
% Ignore initial transient
% -----------------------------
idx = 200;

% -----------------------------
% Extract power (MW) and time
% -----------------------------
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

% -----------------------------
% Time window of interest
% -----------------------------
t_start = 100;
t_end   = 110;

mask1 = (t1 >= t_start) & (t1 <= t_end);
mask2 = (t2 >= t_start) & (t2 <= t_end);
mask3 = (t3 >= t_start) & (t3 <= t_end);
mask4 = (t4 >= t_start) & (t4 <= t_end);
mask5 = (t5 >= t_start) & (t5 <= t_end);

% -----------------------------
% Plot
% -----------------------------
figure;
hold on;
grid on;

plot(t1(mask1), p1(mask1), 'LineWidth', 1.2);
plot(t2(mask2), p2(mask2), 'LineWidth', 1.2);
plot(t3(mask3), p3(mask3), 'LineWidth', 1.2);
plot(t4(mask4), p4(mask4), 'LineWidth', 1.2);
plot(t5(mask5), p5(mask5), 'LineWidth', 1.2);

xlabel('Time (s)');
ylabel('Power Output (MW)');
title('Power Output vs Time (100–110 s)');

legend( ...
    'Exponential', ...
    'Uniform', ...
    'Quadratic', ...
    'Mu-Law', ...
    'A-Law', ...
    'Location', 'best' ...
);
