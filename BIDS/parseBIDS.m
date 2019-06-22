
function parsed = parseBIDS(datafolder, varargin)

if numel(varargin) == 1
    fmt = varargin{1};
else
    fmt = '_eyetrack.';
end

parsed = struct([]);

contents = dir(datafolder);
contents(1:2) = [];
subjects = contents([contents.isdir]);
for subidx = 1:numel(subjects)
    currpath = fullfile(datafolder, subjects(subidx).name);
    while true
        % Get to the bottom level
        contents = dir(currpath);
        contents(1:2) = [];
        if any([contents.isdir])
            currpath = fullfile(currpath, contents([contents.isdir]).name);
        else
            break
        end
    end
    contents = dir(currpath);
    iseyedata = ~cellfun(@isempty, regexp({contents.name}, [fmt '.*']));
    for dataidx = find(iseyedata)
        % Get file head
        filehead = contents(dataidx).name(1:regexp(contents(dataidx).name, [fmt '.*']) - 1);
        % Get BIDS info
        currbidsinfo = [];
        fields = strsplit(filehead, '_');
        for field = fields
            currfield = field{:};
            currbidsinfo.(currfield(1:find(currfield == '-', 1) - 1)) =...
                currfield(find(currfield == '-', 1) + 1:end);
        end
        parsed = [parsed
            struct(...
                'info', currbidsinfo,...
                'full', fullfile(currpath, contents(dataidx).name),...
                'path', currpath,...
                'head', filehead);
        ];
    end
end

end