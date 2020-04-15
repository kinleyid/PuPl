
function pupl_init(varargin)

%   Command line arguments
% 'noUI': don't initialize the user interface
% 'noGlobals': don't initialize global variables
% 'noAddOns': don't initialize toolboxes
%   Example
% >> pupl_init noui noaddons

global pupl_globals
if ~isfield(pupl_globals, 'UI')
    pupl_globals.UI = []; % The handle to the GUI is stored here
end
% Global settings
fprintf('Setting global configuration...\n')
pupl_globals.datavarname = 'eye_data'; % Name of the global data variable
pupl_globals.precision = 'single'; % Should data be stored in single or double precision?
pupl_globals.catdim = 2; % Will the global data variable be a row (2) or column (1) vector?
pupl_globals.ext = 'pupl'; % The extension to use for saving data files
n_save = inf; % How many steps to save for undo/redo operations?
pupl_globals.timeline = struct(...
    'n', n_save,...
    'data', {{'curr'}});

% Is octave?
if exist('OCTAVE_VERSION', 'builtin') ~= 0
    pupl_globals.isoctave = true;
    fprintf('Octave detected. Loading packages:\n');
    for package = {'statistics' 'data-smoothing'}
        fprintf('\t%s...\n', package{:})
        pkg('load', package{:})
    end
else
    pupl_globals.isoctave = false;
end

availableargs = {'noweb' 'noui' 'noglobals' 'noaddons'};
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
fprintf('PuPl, version %s\n', currVersion);
% Check for updates
if ~any(strcmpi(varargin, 'noweb'))
    fprintf('Checking web for new version...\n\t(use ''pupl init noweb'' to skip this)\n\t');
    try
        newestVersion = urlread('https://kinleyid.github.io/newest.txt');
        if ~strcmp(newestVersion, currVersion)
          fprintf('! A new version (%s) is out, download it from github.com/kinleyid/PuPl\n', newestVersion);
        else
          fprintf('You are using the latest version\n');
        end
    catch
        fprintf('Error\n');
    end
end

pdir = fileparts(which('pupl'));
addpath(pdir)

% Add built-in subdirectories
fprintf('Loading source');
src_dirs = {'base' 'UI' 'file' 'tools' 'process' 'trials' 'experiment' 'plot' 'edit'};
for src_idx = 1:numel(src_dirs)
    addpath(genpath(fullfile(pdir, src_dirs{src_idx}))) % Add folder and subfolders
    fprintf('.');
end
fprintf('\n');

if ~pupl_globals.isoctave
    % Octave's questdlg function works fine, but Matlab's returns the
    % default option when the user presses enter, regardless of which
    % option was actually highlighted when the user presses enter. I wrote
    % a quick function that behaves better:
    addpath(fullfile(pdir, 'overwrite', 'questdlg'));
end

if strcontains(varargin, 'dev')
    addpath(genpath(fullfile(pdir, 'dev')))
end

if ~any(strcmpi(varargin, 'noGlobals'))
    fprintf('Initializing global variables...\n');
    evalin('base',...
        sprintf('global %s; %s = struct([]);',...
            pupl_globals.datavarname, pupl_globals.datavarname));
end

if ~any(strcmpi(varargin, 'noUI'))
    if isgraphics(pupl_globals.UI)
        fprintf('Closing previous user interface (only one allowed at a time)...\n')
        delete(pupl_globals.UI)
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
            initfile = fullfile(addonsfolder, currFolder.name, 'init.m');
            if exist(initfile, 'file')
                run(initfile)
                clear('init')
            else
                fprintf('did not find expected file %s', initfile)
            end
            fprintf('\n')
        end
    end
end

fprintf('Done\n')

fprintf('\nSee the "Citations" tab for the papers PuPl is based on.\nPlease cite all the algorithms you use to process your data.\n');

end
