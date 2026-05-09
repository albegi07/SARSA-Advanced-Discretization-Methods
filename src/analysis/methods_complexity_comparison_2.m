%% Annex A - Computational Complexity of Discretization Methods
clear; clc; close all;

% --- Configuration & Parameters (Synchronized with ObservationMapper) ---
% We use the positive range (0 to 15) as requested
range_idx = 0:1:15; 
P_target = 1500000; % 1.5 MW from class
set(0, 'DefaultAxesFontSize', 10);
set(0, 'DefaultLineLineWidth', 1.5);

% --- Data Generation (Class Logic) ---

% 1. Uniform (3e6 total range / 30 steps = 100,000 step size)
Np_uniform = range_idx * (P_target / 15);

% 2. Exponential (k = 0.80477)
k_exp = 0.80477;
Np_exp = 10 * (exp(k_exp * range_idx) - 1);

% 3. Quadratic (7000 * x^2)
Np_quad = 7000 * range_idx.^2;

% 4. mu-law (mu = 50)
mu = 50;
x_norm = range_idx / max(range_idx);
Np_mu = P_target .* (((1+mu).^(x_norm)) / mu);

% 5. A-law (A = 1.8)
A = 1.8;
threshold = 1 / (1 + log(A));
x_alaw = zeros(size(range_idx));
for i = 1:length(range_idx)
    abs_y = range_idx(i) / max(range_idx);
    if abs_y <= threshold
        x_i = (abs_y * (1 + log(A))) / A;
    else
        x_i = exp(abs_y * (1 + log(A)) - 1) / A;
    end
    x_alaw(i) = x_i;
end
Np_alaw = x_alaw * (P_target / max(x_alaw));

%% --- FIGURE 1: Individual Methods (Tiled) ---
figure('Name', 'Individual Methods', 'Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.6 0.8]);
t = tiledlayout(3, 2, 'TileSpacing', 'Compact', 'Padding', 'Compact');

% Uniform
nexttile; plot(range_idx, Np_uniform, 'b'); title('Uniform'); 
grid on; ylabel('P_{error} [W]');

% Exponential
nexttile; plot(range_idx, Np_exp, 'r'); title('Exponential (k=0.80477)'); 
grid on; ylabel('P_{error} [W]');

% Quadratic
nexttile; plot(range_idx, Np_quad, 'm'); title('Quadratic (7000x^2)'); 
grid on; ylabel('P_{error} [W]'); xlabel('Discrete Index');

% mu-law
nexttile; plot(range_idx, Np_mu, 'k'); title('\mu-law (\mu=50)'); 
grid on; ylabel('P_{error} [W]'); xlabel('Discrete Index');

% A-law
nexttile; plot(range_idx, Np_alaw, 'Color', [0.466 0.674 0.188]); title('A-law (A=1.8)'); 
grid on; ylabel('P_{error} [W]'); xlabel('Discrete Index');

%% --- FIGURE 2: Overall Comparison (Log Scale) ---
figure('Name', 'Comprehensive Comparison', 'Color', 'w', 'Units', 'inches', 'Position', [2 2 7 5]);
semilogy(range_idx, Np_uniform, 'b', 'DisplayName', 'Uniform'); hold on;
semilogy(range_idx, Np_quad, 'm--', 'DisplayName', 'Quadratic');
semilogy(range_idx, Np_exp, 'r-.', 'DisplayName', 'Exponential');
semilogy(range_idx, Np_mu, 'k:', 'DisplayName', '\mu-law');
semilogy(range_idx, Np_alaw, 'Color', [0.466 0.674 0.188], 'LineWidth', 2, 'DisplayName', 'A-law');

grid on; grid minor;
xlabel('Discrete State Index', 'FontWeight', 'bold');
ylabel('Represented Power [W] (Log Scale)', 'FontWeight', 'bold');
title('Discretization Mapping Comparison', 'FontSize', 12);
legend('Location', 'northeastoutside');