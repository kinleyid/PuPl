
function outStruct = pupl_loadEDF(varargin)

outStruct = struct([]);

if nargin ~= 1
    [filename, directory] = uigetfile('*.*',...
        'MultiSelect', 'off');
    if isnumeric(filename)
        return
    end
else
    [directory, name, ext] = fileparts(varargin{1});
    filename = sprintf('%s', name, ext);
end
filename = cellstr(filename);

fprintf('Importing EDF...\n');
for fileidx = 1:numel(filename)
    fprintf('\t%s: ', filename{fileidx});
    currsrc = sprintf('%s/%s', directory, filename{fileidx});
    currStruct = load_edf(currsrc);
    currStruct.src = currsrc;
    outStruct = cat(2, outStruct, currStruct);
end
fprintf('Done\n');
end