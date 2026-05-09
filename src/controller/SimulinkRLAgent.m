% Simulink system for reinforcement learning agent
%
% Detailed Description:
%   Implements the interface between the Simulink RL subsystem and the
%   Matlab implementation
%
% Author:
%   Alberto Gil Macia, albegi07@ucm.es
%
% Version:
%   1.0 18/01/2025 Initial version
%   2.0 23/12/2025 Refactor code
classdef SimulinkRLAgent< matlab.System
    
    properties (Access = private)
        prevAction 
        prevState
        agent_factory
        observer
    end
    
    methods (Access = protected)
        % ---------------------------------------------------------------------
        function setupImpl(obj)
            obj.agent_factory = AgentsFactory.getInstance();
            obj.observer = ObservationMapper();
                        
            obj.prevAction = 0.0;
            obj.prevState = double([0, 0]);
        end
        
        % ---------------------------------------------------------------------
        function sts = getSampleTimeImpl(obj, ~)
            sts = createSampleTime(obj,'Type','Discrete','SampleTime',0.3);
        end
        
        % ---------------------------------------------------------------------
        % function pitch = stepImpl(obj, P_error, WindSpeed, Reward)
        %     agent = obj.agent_factory.getAgent();
        % 
        %     % Q-learning update part
        %     state = [P_error, WindSpeed];            
        %     agent = agent.updateQTable(obj.prevState, obj.prevAction, Reward,  state, obj.observer);
        % 
        %     % Get the next action
        %     pitch = agent.chooseAction(state, obj.observer);
        % 
        %     obj.prevAction = pitch;
        %     obj.prevState = state;
        % end

        function pitch = stepImpl(obj, P_error, WindSpeed, Reward)

            agent = obj.agent_factory.getAgent();

            % Current state
            state = [P_error, WindSpeed];

            % Choose next action (SARSA requirement)
            nextAction = agent.chooseAction(state, obj.observer);

            % Update Q-table using SARSA
            agent.updateQTable( ...
                obj.prevState, ...
                obj.prevAction, ...
                Reward, ...
                state, ...
                nextAction, ...
                obj.observer);

            % Move to next state-action pair
            obj.prevState  = state;
            obj.prevAction = nextAction;

            pitch = nextAction;
        end

        
        % ---------------------------------------------------------------------
        function resetImpl(obj)
            % Initialize / reset internal properties
            obj.prevAction = 0;
            obj.prevState = [0, 0];
        end
    end
end
