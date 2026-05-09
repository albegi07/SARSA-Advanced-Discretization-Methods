% AgentsFactory Federated server class.
%
% Detailed Description:
% Takes the Q-learning models from the agent and averages them to create a global model
%
% Author:
% Alberto Gil Macia, albegi07@ucm.es
%
% Version:
% 1.0 18/01/2025 Initial version
% 2.0 23/12/2025 Refactor code

classdef AgentsFactory < handle
    properties (Access = private)
        agent
    end

    methods (Access = private)
        % ---------------------------------------------------------------------
        function obj = AgentsFactory()
            % Private constructor for singleton
            learningRate = 0.4844;
            discountFactor = 0.3109;
            epsilon = 0.3416;
            epsilon_decay = 0.9370;
            observer = ObservationMapper();
            action_mapper = ActionMapper();
            min_epsilon = 0.0005;
            obj.agent = SARSAAgent(learningRate, discountFactor, epsilon, epsilon_decay, min_epsilon, observer, action_mapper); 
            fprintf('Agents factory created.\n');
        end

        % function obj = AgentsFactory()
        %     % Private constructor for singleton
        %     observer = ObservationMapper();
        %     action_mapper = ActionMapper();
        % 
        %     % Load the agent
        % 
        %     data = load('models/sarsa_agent.mat', 'agentData');
        %     agentData = data.agentData;
        % 
        %     obj.agent = SARSAAgent( ...
        %         agentData.LearningRate, ...
        %         agentData.DiscountFactor, ...
        %         agentData.Epsilon, ...
        %         agentData.EpsilonDecay, ...
        %         agentData.MinEpsilon, ...
        %         observer, ...
        %         action_mapper);
        % 
        %     obj.agent.QTable = agentData.QTable;
        %     fprintf('Agent loaded.\n');
        % end
    end

    methods (Static)
        % ---------------------------------------------------------------------
        function obj = getInstance()
            % Static method to get the singleton instance
            persistent localObj
            if isempty(localObj)
                localObj = AgentsFactory();
            end
            obj = localObj;
        end

        

        % ---------------------------------------------------------------------
        function resetInstance()
            % Resets the singleton instance.
            clear AgentsFactory.getInstance
        end
    end

    methods
        % ---------------------------------------------------------------------
        function setAgentsMode(obj, agentMode)
            obj.agent.setAgentMode(agentMode);
        end

        % ---------------------------------------------------------------------
        function setEpsilon(obj, epsilon)
            obj.agent.setEpsilon(epsilon);
        end

        % ---------------------------------------------------------------------
        function agent = getAgent(obj)
            agent = obj.agent;
        end

        % ---------------------------------------------------------------------
        function clearAgents(obj)
            obj.agent.clearAgent();
        end

        % ---------------------------------------------------------------------
        function saveAgents(obj, model_name)
            obj.agent.saveAgent(model_name);
        end

        % ---------------------------------------------------------------------
        function createAgent(obj, learning_rate, discount_factor, epsilon, epsilon_decay, min_epsilon)
            observer = ObservationMapper();
            action_mapper = ActionMapper();
            obj.agent = QLearningAgent(learning_rate, discount_factor, epsilon, epsilon_decay, min_epsilon, observer, action_mapper);
        end

        function load_agent(obj, model_name)
            data = load(model_name, 'agentData');
            agentData = data.agentData;

            obj.agent.setQTable(agentData.QTable);
            fprintf('Agent loaded.\n');
        end
    end
end