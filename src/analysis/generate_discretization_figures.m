clear; close all;

%% ------------------ Generation functions for P_error ------------------
function sequence = generate_sequence_uniform()
    sequence = -1500000:(3000000/30):1500000;
end

function sequence = generate_sequence_quadratic()
    range = -15:1:15;
    sequence = 7000 * range .* abs(range); % signed quadratic
end

function sequence = generate_sequence_exponential()
    k = 0.80477;
    range = -15:1:15;
    sequence = 10 * sign(range) .* (exp(k * abs(range)) - 1);
end

function sequence = generate_sequence_mu_law()
    x = -15:1:15;
    x_normalized = x / max(x);

    % Set the mu parameter (standard value for 8-bit compression)
    mu = 50;
    sequence = 1500000 .* (sign(x_normalized) .* (((1+mu).^(abs(x_normalized)))/ mu));
end

function sequence = generate_sequence_A_law()
    A = 1.8;  % keep original discretization
    y = -15:1:15;  % exact points
    x = zeros(size(y));
    threshold = 1 / (1 + log(A));
    for i = 1:length(y)
        abs_y = abs(y(i));
        sign_y = sign(y(i));
        if abs_y <= threshold
            x_i = (abs_y * (1 + log(A))) / A;
        else
            x_i = exp(abs_y * (1 + log(A)) - 1) / A;
        end
        x(i) = x_i * sign_y;
    end
    sequence = x;
end

function closest = approximate_to_sequence(sequence, n)
    [~, idx] = min(abs(sequence - n));
    closest = sequence(idx);
end

%% ------------------ Precompute sequences ------------------
seq_uniform = generate_sequence_uniform();
seq_quadratic = generate_sequence_quadratic();
seq_exponential = generate_sequence_exponential();
seq_mu = generate_sequence_mu_law();
seq_a = generate_sequence_A_law();

%% ------------------ P_error Discretization Plots ------------------
methods = {'uniform', 'mu_law', 'a_law'};
titles = {'Uniform', 'μ-Law', 'A-Law'};
colors = {[0, 0.4470, 0.7410], [0.8500, 0.3250, 0.0980], [0.9290, 0.6940, 0.1250]};

for i = 1:length(methods)
    method = methods{i};
    title_str = titles{i};
    
    switch method
        case 'uniform'
            seq = seq_uniform;
        case 'mu_law'
            seq = seq_mu;
        case 'a_law'
            seq = seq_a;
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
    
    plot(x, y, 'LineWidth', 2, 'Color', colors{i});
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

disp('All P_error discretization methods have been plotted in separate figures.');
