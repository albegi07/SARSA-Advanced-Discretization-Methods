classdef QLearningAgent < handle
    % QLearningAgent Q-learning agent class.
    %
    % Detailed Description:
    %   This class is designed to train a Q learning agent for control of a wind turbine
    %
    % Notes:
    %   This class is created in order to facilitate the implementation of federated learning algorithms in Matlab
    %
    % Author:
    %   Alberto Gil Macia, agm945@alumno.uned.es
    %
    % Version:
    %   1.0 18/01/2025 Initial version
    properties      
        index
        ActionMapper       % Action mapper to map actions to indices
        
        QTable              % Q-table to store state-action values
        QTable_diff         % Q-table to store differences since last sync
        NumStates           % Number of states
        NumActions          % Number of actions
        LearningRate        % Learning rate (alpha)
        DiscountFactor      % Discount factor (gamma)
        Epsilon             % Exploration probability (epsilon)
        EpsilonDecay
        MinEpsilon
        Observer

        TrainingMode          % Flag to indicate if the agent is in production
    end
    
    methods
        % ---------------------------------------------------------------------
        function obj = QLearningAgent(learningRate, discountFactor, epsilon, epsilon_decay, min_epsilon, observer, action_mapper)
            obj.NumStates = observer.get_number_of_states();
            
            obj.ActionMapper = action_mapper;
            obj.NumActions = obj.ActionMapper.get_number_of_actions();
            
            obj.LearningRate = learningRate;
            obj.DiscountFactor = discountFactor;
            obj.Epsilon = epsilon;
            obj.EpsilonDecay = epsilon_decay;
            obj.TrainingMode = AgentMode.Training; % Default to training mode
            obj.MinEpsilon = min_epsilon;

            obj.Observer = observer;

            fprintf('Agent initialized\n');
                        
            obj.QTable = zeros(obj.NumStates, obj.NumActions);
            obj.QTable_diff = zeros(obj.NumStates, obj.NumActions);
        end

        % ---------------------------------------------------------------------
        function setAgentMode(obj, agentMode)
            % Set the agent to production mode (true) or training mode (false)
            obj.TrainingMode = agentMode;
        end

        function setEpsilon(obj, epsilon)
            obj.Epsilon = epsilon;
        end

        function setQTable(obj, QTable)
            obj.QTable = QTable;
        end

        % ---------------------------------------------------------------------
        function saveAgent(obj, model_name)
            % Save the Q-table and all hyperparameters for easier loading later
            name = strcat('models/', model_name, '.mat');
            
            agentData.QTable = obj.QTable;
            agentData.LearningRate = obj.LearningRate;
            agentData.DiscountFactor = obj.DiscountFactor;
            agentData.Epsilon = obj.Epsilon;
            agentData.EpsilonDecay = obj.EpsilonDecay;
            agentData.MinEpsilon = obj.MinEpsilon;
            agentData.NumStates = obj.NumStates;
            agentData.NumActions = obj.NumActions;
            
            save(name, 'agentData');
            fprintf('Agent saved to %s\n', name);
        end
        
        % ---------------------------------------------------------------------
        function idx = findMaxIndex(~, arr)
            % Find the index of the maximum value in an array
            maxVal = arr(1);
            idx = 1;
            
            for i = 2:length(arr)
                if arr(i) > maxVal
                    maxVal = arr(i);
                    idx = i;
                end
            end
        end
        
        % ---------------------------------------------------------------------
        function action = chooseAction(obj, observation, observer)
            % Method to choose an action using epsilon-greedy policy
            state = observer.map_to_Q_table_index(observation);
            if obj.TrainingMode == AgentMode.Production
                % In production: always take optimal action
                action_index = obj.findMaxIndex(obj.QTable(state, :));
            else
                % Training mode: use epsilon-greedy
                if (rand < obj.NumActions*obj.Epsilon)
                    % Exploration: Choose a random action
                    action_index = randi(obj.NumActions);
                else
                    % Exploitation: Choose the action with the highest Q-value
                    action_index = obj.findMaxIndex(obj.QTable(state, :));
                end
            end

            obj.Epsilon = max(obj.MinEpsilon, obj.Epsilon * obj.EpsilonDecay);
            action = obj.ActionMapper.map_action_index_to_action(action_index);
        end
        
        % ---------------------------------------------------------------------
        function QTable = getModel(obj)
            QTable = obj.QTable;
        end
        
        % ---------------------------------------------------------------------
        function clearAgent(obj)
            obj.QTable = zeros(obj.NumStates, obj.NumActions);
        end
        
        % ---------------------------------------------------------------------
        function obj = updateGlobalModel(obj)
            % Send difference in the Q table to the federated learning and reset the table
            federatedServer = FederatedServer.getInstance();
            federatedServer.updateGlobalModel(obj.QTable_diff);
            
            obj.QTable_diff = zeros(obj.NumStates, obj.NumActions);
        end
        
        % ---------------------------------------------------------------------
        function obj = updateQTable(obj, observation, action, reward, nextObservation, observer)
            % Method to update the Q-table using the Q-learning update rule

            % Actions and observations mapping part
            state = observer.map_to_Q_table_index(observation);
            nextState = observer.map_to_Q_table_index(nextObservation);
            actionIndex = obj.ActionMapper.map_action_to_action_index(action);
            
            % Q learning table update part
            maxNextQ = obj.findMaxIndex(obj.QTable(nextState, :));
            tableIncrement = obj.LearningRate * (reward + obj.DiscountFactor * maxNextQ - obj.QTable(state, actionIndex));

            obj.QTable(state, actionIndex) = obj.QTable(state, actionIndex) + tableIncrement;
            
            % Federated learning part
            obj.QTable_diff(state, actionIndex) = obj.QTable_diff(state, actionIndex) + tableIncrement;
        end
    end
end