function root = getProjectRoot()
% getProjectRoot Returns the repository root folder for this project.
%   This helper is used to resolve relative data and results directories
%   from within src/ when the project is organized into subfolders.
    [root, ~, ~] = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
