function J = ITAE(K)
% K = [learningRate, discountFactor, epsilon, epsilon_decay, min_epsilon]
LearningRate = K(1);
DiscountFactor = K(2);
Epsilon = K(3);
EpsilonDecay = K(4);
MinEpsilon = K(5);

% Remove the state of the previous agent by deleting the instance from the Singleton
AgentsFactory.getInstance().clearAgents();
AgentsFactory.resetInstance();

AgentsFactory.getInstance().createAgent(LearningRate, DiscountFactor, Epsilon, EpsilonDecay, MinEpsilon);

% clear S

AgentsFactory.getInstance().setAgentsMode(AgentMode.Training);
AgentsFactory.getInstance().setEpsilon(Epsilon);
out = sim('ControllerSimulation', 'StartTime', '0', 'StopTime', '3000');
% out = sim('ControllerSimulation','ReturnWorkspaceOutputs','on');

itae = squeeze(out.get('iae').Data(1,1, 1:end));        
J = itae(end);

fprintf('LearningRate=%.4f  DiscountFactor=%.4f  Epsilon=%.4f  EpsilonDecay=%.4f  MinEpsilon=%.4f    J=%.6g \n',K, J)
end


