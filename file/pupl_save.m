function pupl_save(data, varargin)

% Save eye data or event logs
%   Inputs
% path
% batch

global pupl_globals

if isempty(data)
    error('Data is empty, nothing to save')
end

if numel(varargin) == 1
    args = struct(...
        'path', varargin{1},...
        'batch', false);
else
    args = pupl_args2struct(varargin, {
        'path' [] % Either a string indicating the directory to save to or a cell array of these
        'batch' false % If true, all data is saved in the same directory
    });    
end

if isempty(args.path)
    def_filenames = strcat({data.name}, ['.' pupl_globals.ext]);
    if args.batch
        args.path = uigetdir(pwd, 'Select a folder to put all the data in');
        if isnumeric(args.path)
            return
        else
            args.path = fullfile(args.path, def_filenames);
        end
    else
        args.path = {};
        for dataidx = 1:numel(data)
            [f, p] = uiputfile(def_filenames{dataidx},...
                sprintf('Save %s', data.name));
            if isnumeric(f)
                return
            else
                args.path{end + 1} = fullfile(p, f);
            end
        end
    end
end

args.path = cellstr(args.path);

for dataidx = 1:numel(data)
    [p, f] = fileparts(args.path{dataidx});
    curr_path = fullfile(p, sprintf('%s.%s', f, pupl_globals.ext));
    fprintf('Saving %s...', curr_path);
    tmp = data(dataidx);
    save(curr_path, 'tmp', '-v6');
    fprintf('done\n');
end

end