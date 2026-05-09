clear;
close all;

simulation_results_file = 'Output/A_law.mat';
simulation_data_content = load(simulation_results_file);
simulation_data = simulation_data_content.simOut;

wind_speed_output = simulation_data.get('wind');

wind_speed = squeeze(wind_speed_output.Data);
time = wind_speed_output.Time;

%% Time-domain plot
figure
plot(time, wind_speed, 'LineWidth', 2);
grid on;
xlabel('Time (s)');
ylabel('Wind Speed (m/s)');
title('Wind speed evolution in time');

%% Frequency-domain analysis (FFT)
% Sampling parameters
dt = mean(diff(time));      % Sampling time
Fs = 1/dt;                  % Sampling frequency
N = length(wind_speed);     % Number of samples

% Remove mean (recommended)
wind_speed = wind_speed - mean(wind_speed);

% FFT computation
Y = fft(wind_speed);
P2 = abs(Y/N);              
P1 = P2(1:floor(N/2)+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:floor(N/2))/N;    % Frequency vector (Hz)

% Frequency-domain plot (0–0.1 Hz only)
figure
plot(f, P1, 'LineWidth', 2);
grid on;
xlim([0 0.3]);

xlabel('Frequency (Hz)');
ylabel('Amplitude');
title('Frequency decomposition of wind speed');
