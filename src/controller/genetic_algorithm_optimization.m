% % Genetic Algorithm Optimization of the Control Gains
% Lower and upper bounds of the decision variables
% [learningRate, discountFactor, epsilon, epsilon_decay, min_epsilon]
projectRoot = getProjectRoot();
addpath(genpath(fullfile(projectRoot, 'src')));

WindTurbineParametersLoader

LB = [ 0.1,  0.3,  0.01, 0.8, 0.0001];
UB = [ 0.5,  0.97, 0.5, 0.999, 0.02];

% Initial guess ( to initialise the search near a feasible point )
K0 = [0.2, 0.5, 0.3, 0.996, 0.005];

opts = optimoptions('ga','Display','iter', ...
    'PopulationSize',15,'MaxGenerations',20, ...
    'InitialPopulationRange',[LB;UB], ...
    'InitialPopulationMatrix',K0, 'PlotFcn', @gaplotbestf);

% No nonlinear constrains
nonlcon = [];

% Starts GA
[Kopt, Jbest] = ga(@fitness_function, 5, [], [], [], [], LB, UB, nonlcon, opts);

fprintf('LearningRate=%.4f  DiscountFactor=%.4f  Epsilon=%.4f  EpsilonDecay=%.4f  MinEpsilon=%.4f   J=%.6g\n',Kopt, Jbest);

% Best solution
% assignin('base','K11',Kopt(1));
% assignin('base','K12',Kopt(2));
% assignin('base','K21',Kopt(3));
% assignin('base','K22',Kopt(4));
% sim('GA_Based_Controller','FastRestart','on');