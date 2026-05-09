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
getMaxIdx = @(Res, signal) min(idx, size(Res.get(signal).Data,3));
maxIdx = min([getMaxIdx(ResExpU,'power_output'), getMaxIdx(ResExpW,'power_output')]);
idx = maxIdx;

%% =======================
%  HELPER FUNCTIONS
% =======================
getP = @(Res) squeeze(Res.get('power_output').Data(1,1,idx:end))/1e6;
getU = @(Res) squeeze(Res.get('theta_actuation').Data(1,1,idx:end));

P_ref = 1.5;  % MW
timeVec = ResExpU.get('power_output').Time(idx:end);
dt = mean(diff(timeVec));

rmse  = @(p) sqrt(mean((p-P_ref).^2));
iae   = @(p) sum(abs(p-P_ref)) * dt;
rms_u = @(u) sqrt(mean(u.^2));
tv_u  = @(u) sum(abs(diff(u)));
mpo   = @(p) mean(p-P_ref);

%% =======================
%  EXTRACT METRICS
% =======================
% Uniform wind
p_all_u = {getP(ResExpU), getP(ResUniU), getP(ResQuadU), getP(ResMuU), getP(ResAU)};
u_all_u = {getU(ResExpU), getU(ResUniU), getU(ResQuadU), getU(ResMuU), getU(ResAU)};

% Weibull wind
p_all_w = {getP(ResExpW), getP(ResUniW), getP(ResQuadW), getP(ResMuW), getP(ResAW)};
u_all_w = {getU(ResExpW), getU(ResUniW), getU(ResQuadW), getU(ResMuW), getU(ResAW)};

Nmethods = numel(p_all_u);

J_RMSE = zeros(Nmethods,2);
J_IAE  = zeros(Nmethods,2);
J_RMSU = zeros(Nmethods,2);
J_TV   = zeros(Nmethods,2);
J_MPO  = zeros(Nmethods,2);

for m = 1:Nmethods
    % Uniform wind
    J_RMSE(m,1) = rmse(p_all_u{m});
    J_IAE(m,1)  = iae(p_all_u{m});
    J_RMSU(m,1) = rms_u(u_all_u{m});
    J_TV(m,1)   = tv_u(u_all_u{m});
    J_MPO(m,1)  = mpo(p_all_u{m});
    
    % Weibull wind
    J_RMSE(m,2) = rmse(p_all_w{m});
    J_IAE(m,2)  = iae(p_all_w{m});
    J_RMSU(m,2) = rms_u(u_all_w{m});
    J_TV(m,2)   = tv_u(u_all_w{m});
    J_MPO(m,2)  = mpo(p_all_w{m});
end

%% =======================
%  DISPLAY RESULTS
% =======================
metricsNames = {'RMSE [MW]', 'IAE [MW·s]', 'RMS Control [rad]', 'Total Variation [rad]', 'MPO [MW]'};
metricsMatrices = {J_RMSE, J_IAE, J_RMSU, J_TV, J_MPO};
wind_labels = {'Uniform','Weibull'};
method_labels = {'Exponential','Uniform','Quadratic','\mu-law','A-law'};

for k = 1:numel(metricsMatrices)
    fprintf('\n=== %s ===\n', metricsNames{k});
    T = array2table(metricsMatrices{k},'VariableNames',wind_labels,'RowNames',method_labels);
    disp(T);
end
