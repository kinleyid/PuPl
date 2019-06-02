function pupl_init(varargin)

%   Command line arguments
% 'noUI': don't initialize the user interface
% 'noGlobals': don't initialize global variables
% 'noAddOns': don't initialize toolboxes
%   Example
% >> pupl_init noui noaddons

fprintf('Version 0.9\n');
fprintf('Visit <a href="github.com/kinleyid/pupillometry-pipeline">github.com/kinleyid/pupillometry-pipeline</a> for updates\n');

% Navigate to directory containing this very function
previousDir = pwd;
cd(fileparts(which('pupl_init.m')))
addpath(pwd)

% Add built-in subdirectories
fprintf('Loading source...\n')
for subdir = {'base' 'UI' 'file' 'process' 'trials' 'experiment' 'plot' 'stats' 'dev'}
    cd(subdir{:})
    addpath(genpath(pwd)) % Add folder and subfolders
    cd('..')
end

if ~any(strcmpi(varargin, 'noGlobals'))
    fprintf('Initializing global variables...\n')
    globalVariables = {
        'eyeData'};
    globalValues = {
        'struct([])'};
    for i = 1:numel(globalVariables)
        evalin('base',...
            sprintf('global %s; %s = %s;', globalVariables{i}, globalVariables{i}, globalValues{i}));
    end
end

if ~any(strcmpi(varargin, 'noUI'))
    global userInterface
    if isgraphics(userInterface)
        fprintf('Closing previous user interface...\n')
        delete(userInterface)
    end
    fprintf('Initilizing user interface...\n')
    pupl_UI
end

if ~any(strcmpi(varargin, 'noAddOns'))
    cd add-ons
    fprintf('Loading add-ons:\n');
    folderContents = dir;
    for currFolder = reshape(folderContents([folderContents.isdir]), 1, [])
        if ~any(strcmp(currFolder.name, {'.' '..'}))
            fprintf('\t%s...\n', currFolder.name)
            cd(currFolder.name)
            addpath(genpath(pwd));
            run('./init.m');
            cd('..');
        end
    end
    cd('..');
end

% Navigate back to the user's directory
cd(previousDir)

fprintf('done\n')
end