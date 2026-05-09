%% Annex A - Computational Complexity of Discretization Methods
clear; clc; close all;

% --- Configuration & Parameters ---
P_min_range = linspace(0.1, 40, 1000); 
P_max = 5000;

set(0,'DefaultAxesFontSize',10);
set(0,'DefaultLineLineWidth',1.5);

% --- Data Generation ---

% 1. Uniform
Np_uniform = 5000 ./ P_min_range;

% 2. Exponential
psi = 0.57;
Np_exp = (1/psi) * log(5000 ./ P_min_range) + 1;

% 3. Quadratic
Np_quad = sqrt(5000 ./ P_min_range);

% 4. mu-law
mu = 4096;
Np_mu = 1 ./ ((log(P_min_range ./ 5000) ./ log(1 + mu)) + 1);

% 5. A-law
A = 1.016;
term1_a = (5000 * A * (1 + log(A))) ./ (P_min_range * A);
Np_alaw = (log(term1_a) - 1) ./ (1 + log(A));

%% --- FIGURE: Overall Comparison (Log Scale) ---

fig = figure('Name','Comprehensive Comparison','Color','w');

% Set figure size for LaTeX (in cm)
set(fig,'Units','centimeters');
set(fig,'Position',[0 0 12 8]); 

% Plot curves
semilogy(P_min_range, Np_uniform,'b','DisplayName','Uniform'); hold on;
semilogy(P_min_range, Np_quad,'m--','DisplayName','Quadratic');
semilogy(P_min_range, Np_exp,'r-.','DisplayName','Exponential (\psi=0.57)');
semilogy(P_min_range, Np_mu,'k:','DisplayName','\mu-law (\mu=4096)');
semilogy(P_min_range, Np_alaw,'Color',[0.466 0.674 0.188], ...
         'LineWidth',2,'DisplayName','A-law (A=1.016)');

% Axis styling
grid on
grid minor
set(gca,'XDir','reverse','YMinorTick','on')

% Labels and title
xlabel('Minimum Error P_{min} [W]','FontWeight','bold')
ylabel('Number of States N_p (Log Scale)','FontWeight','bold')
title('Computational Complexity Comparison','FontSize',12)

% Legend inside the plot
legend('Location','northwest')

% Annotations
text(5,20000,'Uniform','Color','b','FontSize',9)
text(5,50,'Non-linear methods','Color',[0.3 0.5 0.3],'FontSize',9)

% Remove extra white margins
ax = gca;
ax.LooseInset = ax.TightInset;

% --- Export figure (vector PDF for LaTeX) ---
exportgraphics(fig,'complexity_comparison.pdf','ContentType','vector');