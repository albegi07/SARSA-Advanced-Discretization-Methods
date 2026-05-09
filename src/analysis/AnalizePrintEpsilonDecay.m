epsilon0 = 0.3;
epsilon_decay = 0.99;
Ts = 0.2;

t = 1:0.1:200;

% Continuous decay rate
lambda = log(epsilon_decay) / Ts;

% ODE definition
odefun = @(t, e) lambda * e;

% Solve ODE
[t_out, epsilon_out] = ode45(odefun, t, epsilon0);

% Print final epsilon value
fprintf('Final epsilon: %.6f\n', epsilon_out(end));

% Plot epsilon decay
figure;
plot(t_out, epsilon_out, 'LineWidth', 2);
xlabel('Time');
ylabel('Epsilon');
title('Epsilon Decay over Time');
grid on;
