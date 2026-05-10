% main - Trains and evaluates a Q-learning agent for wind turbine control

clear;
close all;

projectRoot = getProjectRoot();

WindTurbineParametersLoader

% Define the Simulink model environment
simulinkEnvName = 'ControllerSimulation';

% Remove the state of the previous agent by deleting the instance from the Singleton
AgentsFactory.getInstance().clearAgents();
AgentsFactory.resetInstance();

AgentsFactory.getInstance().load_agent(fullfile(projectRoot, 'trained_models', 'sarsa_agent_A_1_8.mat'));

AgentsFactory.getInstance().setAgentsMode(AgentMode.Production);
simOut = sim(simulinkEnvName, 'StartTime', '0', 'StopTime', '400');


%timestamp = datetime('now','Format','yyyyMMdd_HHmmss');
%filename = fullfile(projectRoot, 'ModelAnalysisOutput', "A_law_weibull" + string(timestamp) + ".mat");
%save(filename, 'simOut');
