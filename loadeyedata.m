function EYE = loadeyedata(varargin)

%   Inputs
% filenames
% directory
%   Outputs
% EYE--struct array

p = inputParser;
addParameter(p, 'filenames', [])
addParameter(p, 'directory', [])
parse(p, varargin{:});

if isempty(p.Results.filenames) || isempty(p.Results.filenames)
    [filenames, directory] = uigetfile('*.eyedata',...
        'MultiSelect', 'on');
else
    filenames = p.Results.filenames;
    directory = p.Results.directory;
end

filenames = cellstr(filenames);

EYE = [];

for fileIdx = 1:numel(filenames)
    data = load([directory '\\' filenames{fileIdx}], '-mat');
    EYE = [EYE data.currEYE];
end