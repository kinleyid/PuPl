function structArray = pupl_load(varargin)

% Load eye data or event logs
%   Inputs
% type--data type: see getextfromdatatype for more info
% filenames--cell array
% directory--char
%   Outputs
% structArray--struct array

p = inputParser;
addParameter(p, 'filenames', [])
addParameter(p, 'directory', [])
parse(p, varargin{:});

structArray = struct([]);

extFilter = '*.eyedata';

if isempty(p.Results.filenames) || isempty(p.Results.filenames)
    [filenames, directory] = uigetfile(extFilter,...
        'MultiSelect', 'on');
    if isnumeric(filenames)
        return
    end
else
    filenames = p.Results.filenames;
    directory = p.Results.directory;
end

if isnumeric(filenames)
    return
else
    filenames = cellstr(filenames);
end

for fileIdx = 1:numel(filenames)
    fprintf('Loading %s\n', filenames{fileIdx});
    data = dataloader(@loadeyedata, fullfile(directory, filenames{fileIdx}));
    data = pupl_check(data);
    structArray = fieldconsistency(structArray, data);
    structArray = cat(2, structArray, data);
end

structArray = pupl_check(structArray);

fprintf('Done\n');

end