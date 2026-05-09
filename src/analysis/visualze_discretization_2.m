% Fixed visualization script for discretization methods
% Now includes Weibull wind speed discretization and its probability density function
% + Improved comparative PDF plot using controlled kernel bandwidth for clear, smooth curves

close all

% Generation functions for P_error (with quadratic fixed)
function sequence = generate_sequence_uniform()
    sequence = -1500000:(3000000/30):1500000;
end

function sequence = generate_sequence_quadratic()
    % Fixed: Signed quadratic to preserve negative values symmetrically
    range = -15:1:15;
    sequence = 7000 * range .* abs(range); % = 7000 * sign(range) .* range.^2
end

function sequence = generate_sequence_exponential()
    k = 0.80477;
    range = -15:1:15;
    sequence = 10 * sign(range) .* (exp(k * abs(range)) - 1);
end

function sequence = generate_sequence_mu_law()
    x = -15:1:15;
    x_normalized = x / max(abs(x));
    mu = 10096;
    sequence = 1500000 .* (sign(x_normalized) .* (((1 + mu).^(abs(x_normalized))) / mu));
end

function sequence = generate_sequence_A_law(~)
    A = 0.6;
    y = -15:1:15;
    x = zeros(size(y));
    
    threshold = 1 / (1 + log(A));
    target_limit = 1.5e06; % Your desired bound

    for i = 1:length(y)
        current_y = y(i);
        abs_y = abs(current_y);
        sign_y = sign(current_y);
        
        if abs_y <= threshold
            x_i = (abs_y * (1 + log(A))) / A;
        else
            x_i = exp(abs_y * (1 + log(A)) - 1) / A;
        end
        x(i) = x_i * sign_y;
    end

    % --- Normalization Step ---
    % Scale the values so the maximum absolute value is exactly 1.5e06
    current_max = max(abs(x));
    if current_max ~= 0
        sequence = x * (target_limit / current_max);
    else
        sequence = x; 
    end
end

function closest = approximate_to_sequence(sequence, n)
    [~, idx] = min(abs(sequence - n));
    closest = sequence(idx);
end

% ------------------ P_error Discretization Plots ------------------
methods = {'uniform',  'mu_law', 'a_law'};
titles = {'Uniform',  'μ-Law', 'A-Law'};
colors = {[0, 0.4470, 0.7410], [0.8500, 0.3250, 0.0980], [0.9290, 0.6940, 0.1250], ...
          [0.4940, 0.1840, 0.5560], [0.4660, 0.6740, 0.1880]};

for i = 1:length(methods)
    method = methods{i};
    title_str = titles{i};
    
    switch method
        case 'uniform'
            seq = generate_sequence_uniform();
        case 'quadratic'
            seq = generate_sequence_quadratic();
        case 'exponential'
            seq = generate_sequence_exponential();
        case 'mu_law'
            seq = generate_sequence_mu_law();
        case 'a_law'
            seq = generate_sequence_A_law();
    end
    
    seq = sort(seq);
    
    min_val = min(seq);
    max_val = max(seq);
    margin = 0.1 * (max_val - min_val);
    if margin == 0, margin = 1; end
    x_min = min_val - margin;
    x_max = max_val + margin;
    
    x = linspace(x_min, x_max, 15000);
    y = arrayfun(@(val) approximate_to_sequence(seq, val), x);
    
    figure('Position', [200, 200, 800, 600], 'Color', 'white');
    
    plot(x, y, 'LineWidth', 2, 'Color', [0, 0.4470, 0.7410]);
    hold on;
    plot(x, x, '--', 'LineWidth', 1.5, 'Color', [0.8500, 0.3250, 0.0980]);
    hold off;
    
    title([title_str ' Discretization'], 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('Continuous Value (P_{error})', 'FontSize', 14);
    ylabel('Quantized Value', 'FontSize', 14);
    grid on;
    axis tight;
    legend({'Quantized (Nearest Neighbor)', 'Identity (Continuous)'}, ...
           'Location', 'southeast', 'FontSize', 12);
    set(gca, 'FontSize', 13, 'LineWidth', 1.2);
end

disp('All five P_error discretization methods have been plotted in separate figures.');

% ------------------ Weibull Wind Speed Discretization ------------------
Nw = 21;
k = 60;
lambda = 11.7;
eta = 1;

i_p = 1:(Nw-1);
p_i = i_p / Nw;
wind_seq = eta * lambda * (-log(1 - p_i)).^(1/k);
wind_seq = sort(wind_seq);

min_val = 11;
max_val = max(wind_seq) * 1.05;
margin = 0.1 * (max_val - min_val);
x_min = min_val - margin;
x_max = max_val + margin;

x = linspace(x_min, x_max, 15000);
y = arrayfun(@(val) approximate_to_sequence(wind_seq, val), x);

figure('Position', [200, 200, 800, 600], 'Color', 'white');
plot(x, y, 'LineWidth', 2, 'Color', [0.4660, 0.6740, 0.1880]);
hold on;
plot(x, x, '--', 'LineWidth', 1.5, 'Color', [0.8500, 0.3250, 0.0980]);
hold off;

title('Weibull-Based Wind Speed Discretization (k=120, λ=11.7)', ...
      'FontSize', 16, 'FontWeight', 'bold');
xlabel('Continuous Wind Speed (m/s)', 'FontSize', 14);
ylabel('Quantized Wind Speed (m/s)', 'FontSize', 14);
grid on;
axis tight;
legend({'Quantized (Nearest Neighbor)', 'Identity (Continuous)'}, ...
       'Location', 'southeast', 'FontSize', 12);
set(gca, 'FontSize', 13, 'LineWidth', 1.2);

% Weibull PDF plot
figure('Position', [200, 200, 800, 600], 'Color', 'white');
x_pdf = linspace(11.0, 12.5, 2000);
pdf = (k / lambda) .* (x_pdf / lambda).^(k-1) .* exp( -(x_pdf / lambda).^k );

plot(x_pdf, pdf, 'LineWidth', 2, 'Color', [0.6350, 0.0780, 0.1840]);
hold on;
for i = 1:length(wind_seq)
    plot([wind_seq(i), wind_seq(i)], [0, max(pdf)*0.05], 'k-', 'LineWidth', 1.2);
end
hold off;

title('Weibull Wind Speed Distribution PDF (k=120, λ=11.7)', ...
      'FontSize', 16, 'FontWeight', 'bold');
xlabel('Wind Speed (m/s)', 'FontSize', 14);
ylabel('Probability Density', 'FontSize', 14);
grid on;
legend({'Weibull PDF', 'Discrete Bin Centers'}, 'Location', 'northeast', 'FontSize', 12);
set(gca, 'FontSize', 13, 'LineWidth', 1.2);

disp('Weibull plots created.');

% ------------------ Improved Comparative Empirical PDFs for P_error Methods ------------------
% ------------------ Corrected Comparative Density Plots ------------------
% Instead of ksdensity (which treats levels as data points), 
% we plot the "Level Density" = 1 / (local step size).
% ------------------ Smoothed Comparative PDF around Zero ------------------
% Focuses on the density of representation levels near the origin

sequences = {seq_uniform, seq_quadratic, seq_exponential, seq_mu, seq_a};
labels = {'Uniform', 'Quadratic', 'Exponential', 'μ-Law', 'A-Law'};

figure('Position', [300, 100, 1000, 600], 'Color', 'white');
hold on;

% Define a common fine grid for interpolation to ensure smooth plotting
x_smooth = linspace(-5e5, 5e5, 2000); 

for i = 1:length(sequences)
    seq = sequences{i};
    
    % 1. Calculate raw density (1 / step size)
    midpoints = (seq(1:end-1) + seq(2:end)) / 2;
    deltas = diff(seq);
    raw_density = 1 ./ deltas;
    
    % 2. Normalize raw density
    raw_density = raw_density / sum(raw_density .* deltas);
    
    % 3. Interpolate to the common grid and apply smoothing
    % Using 'pchip' interpolation to maintain the shape of the density
    density_interp = interp1(midpoints, raw_density, x_smooth, 'pchip', 0);
    
    % Apply a Gaussian-like smoothing filter (moving average)
    smooth_density = movmean(density_interp, 50); 
    
    plot(x_smooth, smooth_density, 'LineWidth', 3, 'Color', colors{i}, 'DisplayName', labels{i});
end

hold off;
title('Probability Density for Discretization Functions', 'FontSize', 16);
xlabel('P_{error} (W)', 'FontSize', 14);
ylabel('Probability Density', 'FontSize', 14);

% Limit the view to the region around zero
xlim([-4e5, 4e5]); 
grid on;
legend('Location', 'northeast', 'FontSize', 12);
set(gca, 'FontSize', 13, 'LineWidth', 1.2);

disp('Plot generated: Focus on zero with smoothed density curves.');