function structArray = pupl_load(varargin)

% Load eye data or event logs
%   Inputs
% type--data type: see getextfromdatatype for more info
% filenames--cell array
% directory--char
%   Outputs
% structArray--struct array

p = inputParser;
addParameter(p, 'type', [])
addParameter(p, 'filenames', [])
addParameter(p, 'directory', [])
parse(p, varargin{:});

if isempty(p.Results.filenames) || isempty(p.Results.filenames)
    extFilter = ['*' getextfromdatatype(p.Results.type)];
    [filenames, directory] = uigetfile(extFilter,...
        'MultiSelect', 'on');
else
    filenames = p.Results.filenames;
    directory = p.Results.directory;
end

filenames = cellstr(filenames);

structArray = [];

for fileIdx = 1:numel(filenames)
    data = load([directory '\\' filenames{fileIdx}], '-mat');
    savedStructs = fieldnames(data);
    for sIdx = 1:numel(savedStructs)
        structArray = [structArray data.(savedStructs{sIdx})];
    end
end