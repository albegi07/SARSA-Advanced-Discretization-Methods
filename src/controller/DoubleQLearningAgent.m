classdef DoubleQLearningAgent < handle
    % QLearningAgent Double Q-learning agent class.
    %
    % Detailed Description:
    % This class is designed to train a Double Q learning agent for control of a wind turbine
    %
    % Notes:
    % This class is created in order to facilitate the implementation of federated learning algorithms in Matlab
    %
    % Author:
    % Alberto Gil Macia, agm945@alumno.uned.es
    %
    % Version:
    % 1.0 18/01/2025 Initial version

    properties
        index
        ActionMapper % Action mapper to map actions to indices
        QTable % Q-table to store state-action values (sum of QTableA and QTableB)
        QTable_diff % Q-table to store differences since last sync
        QTableA % First Q-table for Double Q-Learning
        QTableB % Second Q-table for Double Q-Learning
        NumStates % Number of states
        NumActions % Number of actions
        LearningRate % Learning rate (alpha)
        DiscountFactor % Discount factor (gamma)
        Epsilon % Exploration probability (epsilon)
        EpsilonDecay
        TrainingMode % Flag to indicate if the agent is in production
    end

    methods
        % ---------------------------------------------------------------------
        function obj = DoubleQLearningAgent(learningRate, discountFactor, epsilon, epsilon_decay, index, numbe_of_states)
            obj.index = index;
            % Initialize observation and action mappers needed to map observations and action to the Q table
            obj.NumStates = numbe_of_states;
            obj.ActionMapper = ActionMapper();
            obj.NumActions = obj.ActionMapper.get_number_of_actions();
            obj.LearningRate = learningRate;
            obj.DiscountFactor = discountFactor;
            obj.Epsilon = epsilon;
            obj.EpsilonDecay = epsilon_decay;
            obj.TrainingMode = AgentMode.Training; % Default to training mode
            fprintf('Agent initialized\n');
            obj.QTableA = zeros(obj.NumStates, obj.NumActions);
            obj.QTableB = zeros(obj.NumStates, obj.NumActions);
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
        % ---------------------------------------------------------------------
        function saveAgent(obj)
            % Save the Q-table to a file
            name = strcat('model', string(obj.index), '.mat'); % Correct string concatenation
            QTableVar = obj.QTable; % Extract the QTable to save
            save(name, 'QTableVar'); % Save the QTable variable
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
            obj.Epsilon = max(0.002, obj.EpsilonDecay * obj.Epsilon);
            action = obj.ActionMapper.map_action_index_to_action(action_index);
        end
        % ---------------------------------------------------------------------
        function QTable = getModel(obj)
            QTable = obj.QTable;
        end
        % ---------------------------------------------------------------------
        function clearAgent(obj)
            obj.QTableA = zeros(obj.NumStates, obj.NumActions);
            obj.QTableB = zeros(obj.NumStates, obj.NumActions);
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
            % Method to update the Q-table using the Double Q-learning update rule
            % Actions and observations mapping part
            state = observer.map_to_Q_table_index(observation);
            nextState = observer.map_to_Q_table_index(nextObservation);
            actionIndex = obj.ActionMapper.map_action_to_action_index(action);
            % Double Q learning table update part
            if rand < 0.5
                % Update QTableA
                action_next = obj.findMaxIndex(obj.QTableA(nextState, :));
                maxNextQ = obj.QTableB(nextState, action_next);
                tableIncrement = obj.LearningRate * (reward + obj.DiscountFactor * maxNextQ - obj.QTableA(state, actionIndex));
                obj.QTableA(state, actionIndex) = obj.QTableA(state, actionIndex) + tableIncrement;
            else
                % Update QTableB
                action_next = obj.findMaxIndex(obj.QTableB(nextState, :));
                maxNextQ = obj.QTableA(nextState, action_next);
                tableIncrement = obj.LearningRate * (reward + obj.DiscountFactor * maxNextQ - obj.QTableB(state, actionIndex));
                obj.QTableB(state, actionIndex) = obj.QTableB(state, actionIndex) + tableIncrement;
            end
            obj.QTable(state, actionIndex) = obj.QTableA(state, actionIndex) + obj.QTableB(state, actionIndex);
            % Federated learning part
            obj.QTable_diff(state, actionIndex) = obj.QTable_diff(state, actionIndex) + tableIncrement;
        end
    end
end