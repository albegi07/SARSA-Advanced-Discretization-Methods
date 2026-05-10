% main - Trains and evaluates a Q-learning agent for wind turbine control

clear;
close all;

projectRoot = getProjectRoot();
addpath(genpath(fullfile(projectRoot, 'src')));

WindTurbineParametersLoader

% Define the Simulink model environment
simulinkEnvName = 'ControllerSimulation';
numberOfIterations = 150;

% Remove the state of the previous agent by deleting the instance from the Singleton
AgentsFactory.getInstance().clearAgents();
AgentsFactory.resetInstance();

simResults(1, numberOfIterations) = Simulink.SimulationOutput;
powerData = cell(1, numberOfIterations);

boxpolot_x = [];
boxplot_g = [];

figure;

for i = 1:numberOfIterations
    AgentsFactory.getInstance().setAgentsMode(AgentMode.Training);
    AgentsFactory.getInstance().setEpsilon(0.3);
    sim(simulinkEnvName, 'StartTime', '0', 'StopTime', '300');
    
    AgentsFactory.getInstance().setAgentsMode(AgentMode.Production);
    AgentsFactory.getInstance().setEpsilon(0.3);
    simOut = sim(simulinkEnvName, 'StartTime', '0', 'StopTime', '200');

    power_output = squeeze(simOut.get('power_output').Data(1,1, 200:end));

    powerData{i} = power_output;

    boxpolot_x = [boxpolot_x; power_output(:)];
    boxplot_g = [boxplot_g; i * ones(numel(power_output),1)];

    cla
    boxplot(boxpolot_x, boxplot_g)
    xlabel('Episode')
    ylabel('Power Output')
    title('Power Output Distribution per Episode')

    drawnow

    simResults(i) = simOut;
end

%AgentsFactory.getInstance().saveAgents('sarsa_agent_A_1_8');

%timestamp = datetime('now','Format','yyyyMMdd_HHmmss');
%filename = fullfile(projectRoot, 'results', "sarsa_A_1_8_150_episodes" + string(timestamp) + ".mat");
%save(filename, 'simResults');
