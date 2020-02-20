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
pupl_globals.datavarname = 'eye_data'; % Name of the global data variable
pupl_globals.catdim = 2; % Will the global data variable be a row (2) or column (1) vector?
pupl_globals.ext = 'pupl'; % The extension to use for saving data files

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

fprintf('Done\n')
end