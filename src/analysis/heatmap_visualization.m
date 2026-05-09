clear;
close all;

%% =======================
%  LOAD UNIFORM WIND DATA
% =======================
data_exp_u  = load('Output/exponential.mat');
data_uni_u  = load('Output/uniform.mat');
data_quad_u = load('Output/quadratic.mat');
data_mu_u   = load('Output/mu_law.mat');
data_A_u    = load('Output/A_law.mat');

ResExpU  = data_exp_u.simOut;
ResUniU  = data_uni_u.simOut;
ResQuadU = data_quad_u.simOut;
ResMuU   = data_mu_u.simOut;
ResAU    = data_A_u.simOut;

%% =======================
%  LOAD WEIBULL WIND DATA
% =======================
data_exp_w  = load('Output/exponential_weibull20260119_204340.mat');
data_uni_w  = load('Output/uniform_weibull20260119_204943.mat');
data_quad_w = load('Output/quadratic_weibull20260125_101149.mat');
data_mu_w   = load('Output/mu_law_weibull20260125_101352.mat');
data_A_w    = load('Output/A_law_weibull20260125_101441.mat');

ResExpW  = data_exp_w.simOut;
ResUniW  = data_uni_w.simOut;
ResQuadW = data_quad_w.simOut;
ResMuW   = data_mu_w.simOut;
ResAW    = data_A_w.simOut;

idx = 1;   % Ignore transient

%% =======================
%  EXTRACT POWER (MW)
% =======================
getP = @(Res) squeeze(Res.get('power_output').Data(1,1,idx:end)) / 1e6;

% Uniform wind
p_exp_u  = getP(ResExpU);
p_uni_u  = getP(ResUniU);
p_quad_u = getP(ResQuadU);
p_mu_u   = getP(ResMuU);
p_A_u    = getP(ResAU);

% Weibull wind
p_exp_w  = getP(ResExpW);
p_uni_w  = getP(ResUniW);
p_quad_w = getP(ResQuadW);
p_mu_w   = getP(ResMuW);
p_A_w    = getP(ResAW);

%% =======================
%  RMSE COMPUTATION
% =======================
P_ref = mean(p_exp_u);   % use rated power if available

rmse = @(p) sqrt(mean((p - P_ref).^2));

J = [ ...
    rmse(p_exp_u),  rmse(p_exp_w);
    rmse(p_uni_u),  rmse(p_uni_w);
    rmse(p_quad_u), rmse(p_quad_w);
    rmse(p_mu_u),   rmse(p_mu_w);
    rmse(p_A_u),    rmse(p_A_w) ];

%% =======================
%  HEATMAP (JOURNAL READY)
% =======================
error_labels = { ...
    'Exponential', ...
    'Uniform', ...
    'Quadratic', ...
    '\mu-law', ...
    'A-law' };

wind_labels = { ...
    'Uniform wind', ...
    'Weibull wind' };

figure('Color','w','Position',[300 300 520 420]);

h = heatmap(wind_labels, error_labels, J);

% --- Appearance
h.Colormap = parula;                % perceptually uniform
h.ColorbarVisible = 'on';
h.CellLabelFormat = '%.3f';
h.FontName = 'Times New Roman';
h.FontSize = 11;

% --- Axis labels
h.XLabel = 'Wind speed discretization';
h.YLabel = 'Power error discretization';

% --- Title
h.Title = 'RMSE of Power Output';

% --- Improve contrast of numbers
h.CellLabelColor = 'k';

%% =======================
%  EXPORT (VECTOR PDF)
% =======================
set(gcf,'PaperPositionMode','auto');
print(gcf,'RMSE_Heatmap','-dpdf','-painters');
