% main - Trains and evaluates a Q-learning agent for wind turbine control
%
% Detailed Description:
%   Uses the Simulink environment to train an evaluate the model. The results are visualized in the relevant figures
%
% Author:
%   Alberto Gil Macia, albegi07@ucm.es
%
% Version:
%   1.0 18/01/2025 Initial version
%   1.0 22/12/2025 Refactor code
% -------------------------------------------------------------------------

clear;
close all;

projectRoot = getProjectRoot();
addpath(genpath(fullfile(projectRoot, 'src')));

WindTurbineParametersLoader

% Define the Simulink model environment
simulinkEnvName = 'ControllerSimulation';

% Remove the state of the previous agent by deleting the instance from the Singleton
AgentsFactory.getInstance().clearAgents();
AgentsFactory.resetInstance();

AgentsFactory.getInstance().load_agent(fullfile(projectRoot, 'models', 'sarsa_agent_A_1_8_weibull.mat'));

AgentsFactory.getInstance().setAgentsMode(AgentMode.Production);
simOut = sim(simulinkEnvName, 'StartTime', '0', 'StopTime', '400');


timestamp = datetime('now','Format','yyyyMMdd_HHmmss');
filename = fullfile(projectRoot, 'ModelAnalysisOutput', "A_law_weibull" + string(timestamp) + ".mat");
save(filename, 'simOut');
