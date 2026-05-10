classdef ObservationMapper < handle
    % ObservationMapper for Q-learning agent class.

    properties
        p_error_sequence
        wind_sequence
        state_space
    end
    
    methods
        % ---------------------------------------------------------------------
        function obj = ObservationMapper()
            obj.p_error_sequence = obj.generate_sequence_A_law();
            obj.wind_sequence = obj.generate_weibull_wind_sequence(20, 60, 11.7, 1); % 11.3:0.03:11.9; % 
            obj.state_space = obj.generateCombinations(obj.p_error_sequence, obj.wind_sequence);
        end

       % ---------------------------------------------------------------------
        function sequence = generate_sequence_uniform(~)
            sequence = -1500000:(3000000/30):1500000;
            %sequence = -1:1:1;
        end

        % ---------------------------------------------------------------------
        function sequence = generate_sequence_quadratic(~)
            % Generates a combined sequence of square and exponential values.
            range = -15:1:15;
            sequence = 7000 * range.^2;
        end


        % ---------------------------------------------------------------------
        function sequence = generate_sequence_exponential(~)
            % Generates a symmetric signed exponential sequence
            k = 0.80477;                % Growth rate
            range = -15:1:15;        % Includes negative and positive
            
            % Signed exponential: preserves sign, expands magnitude exponentially
            sequence = 10*sign(range) .* (exp(k * abs(range)) - 1);
        end

        % ---------------------------------------------------------------------
        function sequence = generate_sequence_mu_law(~)
            % Generates a combined sequence of square and exponential values.
            x = -15:1:15;
            x_normalized = x / max(x);

            % Set the mu parameter (standard value for 8-bit compression)
            mu = 50;
            sequence = 1500000 .* (sign(x_normalized) .* (((1+mu).^(abs(x_normalized)))/ mu));
        end

        function sequence = generate_sequence_A_law(~)
            A = 1.8;
            y = -15:1:15;
            x = zeros(size(y));
            
            threshold = 1 / (1 + log(A));
            target_limit = 1.5e06; % Your desired bound
        
            for i = 1:length(y)
                current_y = y(i);
                abs_y = abs(current_y);
                sign_y = sign(current_y);
                
                if abs_y <= threshold
                    x_i = (abs_y * (1 + log(A))) / A;
                else
                    x_i = exp(abs_y * (1 + log(A)) - 1) / A;
                end
                x(i) = x_i * sign_y;
            end
        
            % --- Normalization Step ---
            % Scale the values so the maximum absolute value is exactly 1.5e06
            current_max = max(abs(x));
            if current_max ~= 0
                sequence = x * (target_limit / current_max);
            else
                sequence = x; 
            end
        end


        % ---------------------------------------------------------------------
        function sequence = generate_weibull_wind_sequence(~, Nw, k, lambda, eta)
            if nargin < 5
                eta = 1;
            end

            % Generate uniform probabilities for interior points (avoid p=0 and p=1)
            i_p = 1:(Nw-1);
            p_i = i_p / Nw;

            % Inverse CDF of Weibull: quantile function
            sequence = eta * lambda * (-log(1 - p_i)).^(1/k);

            % Optionally sort (already sorted) and ensure row vector
            sequence = sequence(:)';
        end


        % ---------------------------------------------------------------------
        function combinations = generateCombinations(~, A, B)
            % Generate a grid for all combinations of A and B
            [A_grid, B_grid] = ndgrid(A, B);
            
            % Combine the grids into a single 3-column array
            combinations = [A_grid(:), B_grid(:)];
        end

        % ---------------------------------------------------------------------
        function number_of_states = get_number_of_states(obj)
            number_of_states = size(obj.state_space, 1);
        end

        % ---------------------------------------------------------------------
        function state_space = get_state_space(obj)
            state_space = obj.state_space;
        end
        
        % ---------------------------------------------------------------------
        function Q_table_state  = map_to_Q_table_index(obj, observation)
            % Generate exponential sequence for the states of P_error
            p_error = observation(1);
            wind_speed = observation(2);

            p_error_disc = obj.approximate_to_sequence(obj.p_error_sequence, p_error);
            wind_speed_disc = obj.approximate_to_sequence(obj.wind_sequence, wind_speed);

            Q_table_state = obj.findPairIndex( ...
                obj.state_space, ...
                [p_error_disc, wind_speed_disc] );
        end

        % ---------------------------------------------------------------------
        function index = findTripleIndex(~, array, triple)
            if size(triple,1) > 1
                error('Input must be a row vector [a b c].');
            end
            index = find( ...
                array(:,1) == triple(1) & ...
                array(:,2) == triple(2) & ...
                array(:,3) == triple(3), ...
                1 );
        end

        % ---------------------------------------------------------------------
        function index = findPairIndex(~, array, pair)
            % Ensure the input pair is a row vector
            if size(pair, 1) > 1
                error('Input pair must be a row vector.');
            end
            
            % Find the index of the row matching the pair
            index = find(array(:, 1) == pair(1) & array(:, 2) == pair(2), 1);
        end
        
        % ---------------------------------------------------------------------
        function closest_number = approximate_to_sequence(~, sequence, n)
            % Aproximate the continuous value n to the closest value in the sequence
            differences = abs(sequence - n);
            [~, idx] = min(differences);
            closest_number = sequence(idx);
        end
    end
end
