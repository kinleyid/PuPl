function pupl_init(varargin)

%   Command line arguments
% 'noUI': don't initialize the user interface
% 'noGlobals': don't initialize global variables
%   Example
% >> pupl_init noui

fprintf('Version 1.0\n');

% Navigate to directory containing this very function
previousDir = pwd;
cd(fileparts(which('pupl_init.m')));

if ~any(strcmpi(varargin, 'noGlobals'))
    fprintf('Initializing global variables...\n')
    globalVariables = {
        'eyeData'
        'eventLogs'};
    globalValues = {
        'struct([])'
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
    addpath('UI')
    pupl_UI
end

% Navigate back to the user's directory
cd(previousDir);

end