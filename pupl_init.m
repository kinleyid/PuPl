
function pupl_init(varargin)
% Initializes PuPl
%
% Command line arguments:
%   noUI: don't initialize the user interface
%   noGlobals: don't initialize global variables
%   noAddOns: don't initialize toolboxes
%   noWeb: don't check the web for a new version
% Example:
%   >> pupl_init noui noaddons

currVersion = '1.2.3';
fprintf('PuPl, version %s\n', currVersion);

global pupl_globals
% Pupl's root file
pupl_globals.pupl_root = fileparts(mfilename('fullpath'));
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
    'txt', {{}},...
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

% Check for updates
if ~any(strcmpi(varargin, 'noweb'))
    fprintf('Checking web for new version...\n\t(use ''pupl init noweb'' to skip this)\n\t');
    try
        newestVersion = urlread('https://kinleyid.github.io/pupl/latest-version.txt');
        if ~strcmp(newestVersion, currVersion)
          fprintf('! A new version (%s) is out, download it from github.com/kinleyid/PuPl\n', newestVersion);
        else
          fprintf('You are using the latest version: %s\n', currVersion);
        end
    catch
        fprintf('Error\n');
    end
end

pdir = fileparts(which('pupl'));
addpath(pdir)

% Add built-in subdirectories
fprintf('Adding PuPl''s source code to ');
if pupl_globals.isoctave
    fprintf('Octave');
else
    fprintf('Matlab');
end
fprintf('''s path');
src_dirs = {'base' 'UI' 'file' 'edit' 'tools' 'prep' 'process' 'trials' 'plot' 'experiment'};
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
    evalin('base', sprintf('global %s', pupl_globals.datavarname));
    if ~isempty(evalin('base', pupl_globals.datavarname))
        while true
            switch input(sprintf('Overwrite global data variable "%s"? [y/n] ', pupl_globals.datavarname), 's')
                case 'y'
                    evalin('base', sprintf('%s = struct([]);', pupl_globals.datavarname));
                    break
                case 'n'
                    break
                otherwise
                    fprintf('Type "y" or "n"\n');
            end
        end
    else
        evalin('base', sprintf('%s = struct([]);', pupl_globals.datavarname));
    end
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
    addonfolders = dir(addonsfolder);
    for currFolder = reshape(addonfolders([addonfolders.isdir]), 1, [])
        if ~any(strcmp(currFolder.name, {'.' '..'}))
            fprintf('\t%s...', currFolder.name);
            addpath(genpath(fullfile(addonsfolder, currFolder.name)));
            initfolder = fullfile(addonsfolder, currFolder.name, 'init');
            if exist(initfolder, 'dir')
                initfile = fullfile(initfolder, 'init.m');
                if exist(initfile, 'file')
                    run(initfile)
                    rmpath(initfolder);
                else
                    fprintf('did not find expected file %s', initfile)
                end
            else
                fprintf('did not find expected folder %s', initfolder)
            end
            fprintf('\n')
        end
    end
end

fprintf('Done\n')

fprintf('\n\tSee the "Citations" tab for the papers PuPl is based on.\n\tPlease cite all the procedures you use to process your data.\n\tIf you encounter any difficulties using this software,\n\tplease contact Isaac Kinley (kinleyid@mcmaster.ca).\n\n');

end
