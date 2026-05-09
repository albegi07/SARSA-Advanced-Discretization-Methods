% setupProject Adds the project source folder to the MATLAB path.
% Run this once after opening the repository in MATLAB.
projectRoot = pwd;
addpath(genpath(fullfile(projectRoot, 'src')));
fprintf('Added project source path: %s\n', fullfile(projectRoot, 'src'));
