clear;
close all;

projectRoot = getProjectRoot();
addpath(genpath(fullfile(projectRoot, 'src')));

%% =======================
%  SETTINGS & PATHS
% =======================
folderPath = fullfile(projectRoot, 'results_weibull_3'); 
distTypes = {'exponential', 'uniform', 'quadratic', 'mu_law', 'A_law'};
P_ref = 1.5;  
idx_start = 300; 

%% =======================
%  DATA LOADING
% =======================
ResMatrix = cell(2, 5);
for d = 1:numel(distTypes)
    uFiles = dir(fullfile(folderPath, [distTypes{d}, '*2026*.mat']));
    uFiles = uFiles(~contains({uFiles.name}, 'weibull', 'IgnoreCase', true));
    ResMatrix{1, d} = loadAndAverage(folderPath, uFiles);
    
    wFiles = dir(fullfile(folderPath, [distTypes{d}, '_weibull2026*.mat']));
    ResMatrix{2, d} = loadAndAverage(folderPath, wFiles);
end

%% =======================
%  METRICS CALCULATION
% =======================
J_RMSE = zeros(5, 2); J_IAE = zeros(5, 2); 
J_RMSU = zeros(5, 2); J_TV  = zeros(5, 2); J_MPO = zeros(5, 2);

for w = 1:2 
    for m = 1:5 
        data = ResMatrix{w, m};
        if isempty(data), continue; end
        
        p = squeeze(data.get('power_output').Data(1,1,idx_start:end)) / 1e6;
        u = squeeze(data.get('theta_actuation').Data(1,1,idx_start:end));
        t = data.get('power_output').Time(idx_start:end);
        dt = mean(diff(t));
        
        J_RMSE(m, w) = sqrt(mean((p - P_ref).^2));
        J_IAE(m, w)  = sum(abs(p - P_ref)) * dt;
        J_RMSU(m, w) = sqrt(mean(u.^2));
        J_TV(m, w)   = sum(abs(diff(u)));
        J_MPO(m, w)  = mean(abs(p - P_ref)); 
    end
end


error_labels = {'Exponential','Uniform','Quadratic','\mu-law','A-law'};
wind_labels  = {'Uniform Wind','Weibull Wind'};
metrics      = {J_RMSE, J_IAE, J_RMSU, J_TV, J_MPO};
titles       = {'RMSE [MW]', 'IAE [MW·s]', 'RMS Control [rad]', 'TV Control [rad]', 'MPO [MW]'};

% Custom Blue-White-Red Colormap
custom_bwr = [linspace(0, 1, 128)', linspace(0, 1, 128)', linspace(1, 1, 128)';  % Deep Blue to White
              linspace(1, 1, 128)', linspace(1, 0, 128)', linspace(1, 0, 128)']; % White to Deep Red

for k = 1:numel(metrics)
    fig = figure('Color','w', 'Units', 'inches', 'Position', [2, 2, 5.5, 4.5]);
    
    current_data = metrics{k};
    h = heatmap(wind_labels, error_labels, current_data);
    
    h.Title = titles{k};
    h.FontName = 'Times New Roman';
    h.FontSize = 11;
    h.CellLabelFormat = '%.4f';
    h.GridVisible = 'off';
    
    if k == 5
        % MPO: Colors mapped strictly to the data range
        h.Colormap = custom_bwr;
        % Automatically sets limits to [min(data), max(data)]
        h.ColorLimits = [min(current_data(:)), max(current_data(:))]; 
    else
        % Other metrics using standard Parula, also mapped to data range
        h.Colormap = parula;
        h.ColorLimits = [min(current_data(:)), max(current_data(:))];
    end
end

%% =======================
%  HELPER FUNCTION
% =======================
function avgData = loadAndAverage(folder, fileList)
    if isempty(fileList)
        avgData = [];
        return;
    end
    fullPath = fullfile(folder, fileList(1).name);
    tmp = load(fullPath);
    avgData = tmp.simOut; 
end