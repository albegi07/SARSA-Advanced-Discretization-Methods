clear;
close all;

projectRoot = getProjectRoot();
addpath(genpath(fullfile(projectRoot, 'src')));

%% =======================
%  LOAD UNIFORM WIND DATA
% =======================
uniformFiles = {'exponential.mat', 'uniform.mat', 'quadratic.mat', 'mu_law.mat', 'A_law.mat'};
ResUni = cell(size(uniformFiles));

for k = 1:numel(uniformFiles)
    fpath = fullfile(projectRoot, 'Output', uniformFiles{k});
    if ~isfile(fpath)
        error('File not found: %s', fpath);
    end
    data = load(fpath);
    ResUni{k} = data.simOut;
end

% Assign readable names
[ResExpU, ResUniU, ResQuadU, ResMuU, ResAU] = ResUni{:};

%% =======================
%  LOAD WEIBULL WIND DATA
% =======================
weibullFiles = {'exponential_weibull20260119_204340.mat', ...
                'uniform_weibull20260119_204943.mat', ...
                'quadratic_weibull20260125_101149.mat', ...
                'mu_law_weibull20260125_101352.mat', ...
                'A_law_weibull20260125_101441.mat'};
ResWei = cell(size(weibullFiles));

for k = 1:numel(weibullFiles)
    fpath = fullfile(projectRoot, 'Output', weibullFiles{k});
    if ~isfile(fpath)
        error('File not found: %s', fpath);
    end
    data = load(fpath);
    ResWei{k} = data.simOut;
end

[ResExpW, ResUniW, ResQuadW, ResMuW, ResAW] = ResWei{:};

%% =======================
%  IGNORE TRANSIENT
% =======================
idx = 300;  % default transient
% Ensure idx does not exceed simulation length
getMaxIdx = @(Res, signal) min(idx, size(Res.get(signal).Data,3));
maxIdx = min([getMaxIdx(ResExpU,'power_output'), getMaxIdx(ResExpW,'power_output')]);
idx = maxIdx;

%% =======================
%  EXTRACT POWER & CONTROL INPUT
% =======================
% Helper functions
getP = @(Res) squeeze(Res.get('power_output').Data(1,1,idx:end)) / 1e6;       % MW
getU = @(Res) squeeze(Res.get('theta_actuation').Data(1,1,idx:end));         % control input

% Uniform wind
p_exp_u  = getP(ResExpU); u_exp_u  = getU(ResExpU);
p_uni_u  = getP(ResUniU); u_uni_u  = getU(ResUniU);
p_quad_u = getP(ResQuadU); u_quad_u = getU(ResQuadU);
p_mu_u   = getP(ResMuU);   u_mu_u   = getU(ResMuU);
p_A_u    = getP(ResAU);    u_A_u    = getU(ResAU);

% Weibull wind
p_exp_w  = getP(ResExpW);  u_exp_w  = getU(ResExpW);
p_uni_w  = getP(ResUniW);  u_uni_w  = getU(ResUniW);
p_quad_w = getP(ResQuadW); u_quad_w = getU(ResQuadW);
p_mu_w   = getP(ResMuW);   u_mu_w   = getU(ResMuW);
p_A_w    = getP(ResAW);    u_A_w    = getU(ResAW);

%% =======================
%  REFERENCE
% =======================
P_ref = 1.5;  % MW

%% =======================
%  METRICS DEFINITION
% =======================
% Time step for IAE (assume uniform sampling)
% We pick dt from one of the simulations
timeVec = ResExpU.get('power_output').Time(idx:end);
dt = mean(diff(timeVec));

rmse  = @(p) sqrt(mean((p-P_ref).^2));
timeVec = ResExpU.get('power_output').Time(idx:end);
dt = mean(diff(timeVec));        % time step
iae   = @(p) sum(abs(p-P_ref)) * dt;
rms_u = @(u) sqrt(mean(u.^2));
tv_u = @(u) sum(abs(diff(u)));  % Total Variation of control input
mpo   = @(p) mean(p - P_ref);       % Mean Power Offset

%% =======================
%  CREATE METRIC MATRICES
% =======================
% RMSE
J_RMSE = [ ...
    rmse(p_exp_u),  rmse(p_exp_w);
    rmse(p_uni_u),  rmse(p_uni_w);
    rmse(p_quad_u), rmse(p_quad_w);
    rmse(p_mu_u),   rmse(p_mu_w);
    rmse(p_A_u),    rmse(p_A_w)];

% IAE
J_IAE = [ ...
    iae(p_exp_u),  iae(p_exp_w);
    iae(p_uni_u),  iae(p_uni_w);
    iae(p_quad_u), iae(p_quad_w);
    iae(p_mu_u),   iae(p_mu_w);
    iae(p_A_u),    iae(p_A_w)];

% RMS Control Input
J_RMSU = [ ...
    rms_u(u_exp_u),  rms_u(u_exp_w);
    rms_u(u_uni_u),  rms_u(u_uni_w);
    rms_u(u_quad_u), rms_u(u_quad_w);
    rms_u(u_mu_u),   rms_u(u_mu_w);
    rms_u(u_A_u),    rms_u(u_A_w)];

% MPO
J_MPO = [ ...
    mpo(p_exp_u),  mpo(p_exp_w);
    mpo(p_uni_u),  mpo(p_uni_w);
    mpo(p_quad_u), mpo(p_quad_w);
    mpo(p_mu_u),   mpo(p_mu_w);
    mpo(p_A_u),    mpo(p_A_w)];

% Total Variation of Control Input
J_TV = [ ...
    tv_u(u_exp_u),  tv_u(u_exp_w);
    tv_u(u_uni_u),  tv_u(u_uni_w);
    tv_u(u_quad_u), tv_u(u_quad_w);
    tv_u(u_mu_u),   tv_u(u_mu_w);
    tv_u(u_A_u),    tv_u(u_A_w)];


%% =======================
%  HEATMAP LABELS
% =======================
error_labels = {'Exponential','Uniform','Quadratic','\mu-law','A-law'};
wind_labels  = {'Uniform wind','Weibull wind'};

%% =======================
%  CREATE FIGURES
% =======================
metrics   = {J_RMSE, J_IAE, J_RMSU, J_TV, J_MPO};
titles    = {'RMSE of Power Output [MW]', ...
             'IAE of Power Output [MW·s]', ...
             'RMS of Control Input [rad]', ...
             'Total Variation of Control Input [rad]', ...
             'Mean Power Offset (MPO) [MW]'};
filenames = {'RMSE_Heatmap','IAE_Heatmap','RMS_Control_Heatmap', 'TV_Control_Heatmap', 'MPO_Heatmap'};

for k = 1:5
    figure('Color','w','Position',[300 300 520 420]);
    h = heatmap(wind_labels, error_labels, metrics{k});
    
    % Formatting
    h.ColorbarVisible = 'on';
    if k == 5
        h.CellLabelFormat = '%.2e';  % Use scientific notation for IAE & MPO
    else
        h.CellLabelFormat = '%.4f';
    end
    h.FontName = 'Times New Roman';
    h.FontSize = 11;
    xlabel(h, 'Wind speed discretization');
    ylabel(h, 'Power error discretization');
    h.Title  = titles{k};
    h.GridVisible = 'off';
    h.CellLabelColor = 'k';
    
    % Colormap
    if k == 5
        % Diverging colormap for MPO
        n = 256; % number of colors
        h.Colormap = [linspace(0,1,n)', linspace(0,0,n)', linspace(1,0,n)'];  
        % this creates a simple blue-to-red colormap
    else
        h.Colormap = parula;
    end

    
    % Save each figure as vector PDF
    set(gcf,'PaperPositionMode','auto');
    print(gcf, filenames{k}, '-dpdf','-painters');
end
