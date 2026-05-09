classdef AgentMode < int32
    % AgentMode Enumeration class to define the mode of the agent.
    %
    % Enumeration Values:
    %   Training   - The agent is in training mode.
    %   Production - The agent is in production mode.
    
    enumeration
        Training   (0)  % Training mode
        Production (1)  % Production mode
    end
end