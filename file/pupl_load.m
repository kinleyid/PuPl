function out = pupl_load(varargin)

% Load eye data or event logs
%   Inputs
% path--string or cell array of strings
%   Outputs
% out--struct array containing data

global pupl_globals

out = struct([]);

args = pupl_args2struct(varargin, {
    'path' []
});

if isempty(args.path)
    [f, p] = uigetfile(sprintf('*%s', pupl_globals.ext),...
        'MultiSelect', 'on');
    if isnumeric(f)
        return
    else
        args.path = fullfile(p, f);
    end
end

args.path = cellstr(args.path);

for dataidx = 1:numel(args.path)
    fprintf('Loading %s...', args.path{dataidx});
    curr = load(args.path{dataidx}, '-mat');
    % curr should be a structure with 1 field
    fn = fieldnames(curr);
    curr = curr.(fn{:});
    out = fieldconsistency(out, curr);
    out = cat(pupl_globals.catdim, out, curr);
    fprintf('done\n');
end

out = pupl_check(out);

end