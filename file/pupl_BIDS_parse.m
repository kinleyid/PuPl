
function parsed = pupl_BIDS_parse(in, varargin)

% out: struct array with the properties from each file
% in: either a sourcedata-like folder or the full path of a file

if numel(varargin) == 1
    fmt = varargin{1};
else
    fmt = '_eyetrack.';
end

if iscell(in)
    parsed = [];
    for idx = 1:numel(in)
        parsed = [parsed pupl_BIDS_parse(in{idx}, fmt)];
    end
else
    [filepath, name, ext] = fileparts(in);
    if isempty(ext)
        % We need to get the bottom of the file hierarchy
        parsed = [];
        contents = dir(in);
        contents = contents(~ismember({contents.name}, {'.' '..'}));
        subjects = contents([contents.isdir]);
        for subidx = 1:numel(subjects)
            currpath = fullfile(in, subjects(subidx).name);
            while true
                % Get to the bottom level
                contents = dir(currpath);
                contents = contents(~ismember({contents.name}, {'.' '..'}));
                if any([contents.isdir])
                    names = {contents.name};
                    idx = strcontains(names, 'eyetrack') | strcontains(names, 'ses');
                    currpath = fullfile(currpath, contents(idx).name);
                else
                    break
                end
            end
            contents = dir(currpath);
            iseyedata = ~cellfun(@isempty, regexp({contents.name}, [fmt '.*']));
            for dataidx = find(iseyedata)
                parsed = [parsed pupl_BIDS_parse(fullfile(contents(dataidx).folder, contents(dataidx).name))];
            end
        end
    else
        % Full path to file
        fields = regexp(name, '_', 'split');
        info = struct('type', fields{end});
        for field = fields(1:end-1)
            currfield = field{:};
            info.(currfield(1:find(currfield == '-', 1) - 1)) =...
                currfield(find(currfield == '-', 1) + 1:end);
        end
        parsed = struct(...
            'info', info,...
            'full', in,...
            'path', filepath,...
            'name', name);
    end
end

end