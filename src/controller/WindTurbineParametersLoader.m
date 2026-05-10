% LQR Controller (5-state linearization) for Wind Turbine (matches writeup)
clear; close all; clc;

projectRoot = getProjectRoot();
addpath(genpath(fullfile(projectRoot, 'src')));

% Load Cp data (same as you had)
load(fullfile(projectRoot, 'WindCpData.mat'), 'Bgrid', 'TSRgrid', 'CpData')

% --- turbine & model params ----------------
GBRatio = 88;               % gear ratio
GBEff = 1.0;                % gearbox efficiency (unused except for clarity)
GenEff = 0.95;              % generator efficiency (eta_g)
Jgen = 53;                  % generator inertia about HSS (kg*m^2)
Jrot = 3e6;                 % rotor inertia about LSS (kg*m^2)
J_r = Jrot + Jgen * GBRatio^2;  % equivalent inertia about low-speed shaft (kg*m^2)
R = 35;                     % rotor radius (m)
A_rotor = pi * R^2;         % rotor swept area
rho = 1.225;                % air density (kg/m^3)

K_theta = 1.43;             % pitch actuator gain
T_theta = 0.36;             % pitch actuator time constant (s)
tau = 0.2;                  % effective wind speed time constant (s)
tau_T = 0.1;                % high-speed shaft torque dynamics time constant (s)

PRated = 1.5e6;             % rated power (W)
wRatedHSS = 1800 * (2*pi/60);   % HSS rated rad/s
wRatedLSS = wRatedHSS / GBRatio; 
GenTRated = PRated / (wRatedHSS * GenEff);
T_hs = GenTRated;           % realistic steady-state HSS torque (N*m)
WindRated = 11.2;           % rated wind (m/s)

% Find Cp maximum and operating beta/TSR (as in your code)
CpMax = max(CpData, [], 'all');
[i_cp, j_cp] = find(CpData == CpMax, 1);
TSRopt = TSRgrid(i_cp);
Bopt = Bgrid(j_cp);