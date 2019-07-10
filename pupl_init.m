function pupl_init(varargin)

%   Command line arguments
% 'noUI': don't initialize the user interface
% 'noGlobals': don't initialize global variables
% 'noAddOns': don't initialize toolboxes
%   Example
% >> pupl_init noui noaddons

availableargs = {'noui' 'noglobals' 'noaddons'};
badargidx = ~ismember(lower(varargin), availableargs);
if any(badargidx)
    for ii = find(badargidx)
        fprintf('Error: unrecognized command line argument ''%s''\n', varargin{ii});
    end
    fprintf('Available arguments:\n');
    fprintf('\t''%s''\n', availableargs{:});
    return
end

currVersion = '1.0.0';
fprintf('PuPL, version %s\n', currVersion);
% Check for updates
try
    newestVersion = urlread('https://kinleyid.github.io/newest.txt');
    if ~strcmp(newestVersion, currVersion)
        fprintf('! A new version (%s) is out, go to github.com/kinleyid/pupillometry-pipeline to get it\n', newestVersion);
    else
        fprintf('You are using the latest version\n');
    end
catch
    fprintf('Error checking the web for a new version\n');
end

pdir = fileparts(which('pupl'));
addpath(pdir)

% Add built-in subdirectories
fprintf('Loading source');
for subdir = {'base' 'UI' 'file' 'tools' 'process' 'trials' 'experiment' 'plot'}
    addpath(genpath(fullfile(pdir, subdir{:}))) % Add folder and subfolders
    fprintf('.');
end
if strcontains(varargin, 'dev')
    addpath(genpath(fullfile(pdir, 'dev')))
end
fprintf('\n');

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
    fprintf('Loading add-ons:\n');
    addonsfolder = fullfile(pdir, 'add-ons');
    folderContents = dir(addonsfolder);
    for currFolder = reshape(folderContents([folderContents.isdir]), 1, [])
        if ~any(strcmp(currFolder.name, {'.' '..'}))
            fprintf('\t%s...', currFolder.name);
            addpath(genpath(fullfile(addonsfolder, currFolder.name)));
            try
                initfile = fullfile(addonsfolder, currFolder.name, 'init.m');
                run(initfile);
                clear(initfile);
            catch
                fprintf('no init.m file found');
            end
            fprintf('\n');
        end
    end
end

% Is octave?
if exist('OCTAVE_VERSION', 'builtin') ~= 0
    fprintf('Octave detected. Loading packages\n');
    pkg load statistics
end

fprintf('done\n')
end