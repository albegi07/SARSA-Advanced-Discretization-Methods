classdef ActionMapper
    % ActionMapper Q-learning agent class.

    properties
        action_space
    end
    
    methods
        % Constructor to initialize the Q-learning agent
        function obj = ActionMapper()
            obj.action_space = 0:0.1:10;
        end

        function number_of_actions = get_number_of_actions(obj)
            number_of_actions = length(obj.action_space);
        end

        function action_space = get_action_space(obj)
            action_space = obj.action_space;
        end

        % Generate exponential sequence for the states of P_error
        function action_index  = map_action_to_action_index(obj, action)
            action_index = find(obj.action_space == action, 1);
        end

        function action = map_action_index_to_action(obj, Q_table_index)
            action = obj.action_space(Q_table_index);
        end
    end
end
