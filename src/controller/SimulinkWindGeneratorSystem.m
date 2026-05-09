classdef SimulinkWindGeneratorSystem < matlab.System ...
                               & matlab.system.mixin.Propagates ...
                               & matlab.system.mixin.SampleTime
    
    % WindWeibullGenerator con filtro de primer orden y rate limiter
    
    properties(Nontunable)
        Scale = 11.7;      % Parámetro de escala Weibull (A)
        Shape =60;        % Parámetro de forma Weibull (B)
        Tau = 20;           % Constante de tiempo del filtro [s]
        MaxRate = 0.3;       % Máxima variación por paso [m/s]
        Ts = 1;          % Tiempo de muestreo [s]
        RandomTime = 5;
    end
    
    properties(DiscreteState)
        FilteredWindSpeed  % Estado del filtro (valor de salida anterior)
        targetWind
    end
    
    methods(Access = protected)
        
        function setupImpl(obj)
            % Inicializar el estado discreto
            obj.FilteredWindSpeed = random('Weibull', obj.Scale, obj.Shape);
            obj.targetWind = random('Weibull', obj.Scale, obj.Shape);
            rng('shuffle');
        end
        
        function windSpeed = stepImpl(obj,clock)
            % Generar nuevo valor objetivo de Weibull

            if (mod(floor(clock), obj.RandomTime) == 0)
                obj.targetWind = random('Weibull', obj.Scale, obj.Shape);
            end
            
            % Coeficiente del filtro de primer orden discreto
            % alpha = exp(-obj.Ts / obj.Tau);
            alpha = obj.Ts / (obj.Tau + obj.Ts);
            
            % Valor filtrado sin limitación de tasa
            unlimitedFiltered = alpha * obj.FilteredWindSpeed + ...
                                (1 - alpha) * obj.targetWind;
            
            % Aplicar limitación de tasa (±MaxRate m/s por paso)
            delta = unlimitedFiltered - obj.FilteredWindSpeed;
            deltaLimited = max(min(delta, obj.MaxRate), -obj.MaxRate);
            windSpeed = obj.FilteredWindSpeed + deltaLimited;
            
            % Actualizar estado discreto
            obj.FilteredWindSpeed = windSpeed;
        end
        
        function resetImpl(obj)
            obj.FilteredWindSpeed = random('Weibull', obj.Scale, obj.Shape);
            obj.targetWind = random('Weibull', obj.Scale, obj.Shape);
            rng('shuffle');
        end
        
        % Método corregido con 3 salidas: tamaño, tipo de datos, complejidad
        function [sz, dt, cp] = getDiscreteStateSpecificationImpl(obj, ~)
            sz = [1 1];    % Dimensión: escalar (1x1)
            dt = 'double'; % Tipo de datos: double
            cp = false;    % Complejidad: real (no complejo)
        end
        
        function sts = getSampleTimeImpl(obj)
            sts = createSampleTime(obj, 'Type', 'Discrete', ...
                                   'SampleTime', obj.Ts);
        end
        
        function out = getOutputSizeImpl(~)
            out = [1 1];
        end
        
        function out = getOutputDataTypeImpl(~)
            out = 'double';
        end
        
        function out = isOutputComplexImpl(~)
            out = false;
        end
        
        function out = isOutputFixedSizeImpl(~)
            out = true;
        end
    end
end