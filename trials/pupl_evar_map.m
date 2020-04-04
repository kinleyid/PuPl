
function out = pupl_evar_map(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_evar_map(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'old' []
    'map' []
    'new' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.old)
    all_evars = pupl_evar_getnames([EYE.event]);
    sel = listdlg(...
        'PromptString', 'Map which event variables to numbers?',...
        'ListString', all_evars,...
        'SelectionMode', 'single');
    if isempty(sel)
        return
    else
        args.old = all_evars{sel};
    end
end

if isempty(args.map)
    all_levels = mergefields(EYE, 'event', args.old);
    unique_levels = unique(all_levels(~cellfun(@isempty, all_levels)));
    str_unique = sprintf('%s; ', unique_levels{:});
    str_unique(end-1:end) = [];
    cfg = inputdlg({
        sprintf('Levels of string variable (separated by commas or semicolons)\n\nleave empty to use all levels, sorted alphabetically:\n%s', str_unique)
        sprintf('Corresponding numeric replacements (e.g. [1 3 2] or 1:10)\n\nleave empty to use\n%s', num2str(1:numel(unique_levels)))});
    if isempty(cfg)
        return
    else
        str = cfg{1};
        if isempty(str)
            str = unique_levels;
        else
            str = regexprep(str, ' ', '');
            str = regexp(str, '[;,]', 'split');
        end
        num = str2num(cfg{2});
        if isempty(num)
            num = 1:numel(unique_levels);
        end
        args.map.str = str;
        args.map.num = num;
    end
end

if isempty(args.new)
    new = inputdlg('Name of resulting numeric event variable');
    if isempty(new)
        return
    else
        new = new{:};
        new = regexprep(new, ' ', '');
        new = regexprep(new, '#', '');
        args.new = new;
    end
end

fprintf('Mapping the string variable #%s to the numeric variable #%s as follows:\n', args.old, args.new);
for i = 1:numel(args.map.str)
    fprintf('\t%s -> %d\n', args.map.str{i}, args.map.num(i));
end

outargs = args;

end

function EYE = sub_evar_map(EYE, varargin)

args = parseargs(varargin{:});

n_val = 0;
for eventidx = 1:numel(EYE.event)
    curr_str = EYE.event(eventidx).(args.old);
    if ~isempty(curr_str)
        n_val = n_val + 1;
        replace_idx = strcmp(curr_str, args.map.str);
        curr_num = args.map.num(replace_idx);
        EYE.event(eventidx).(args.new) = curr_num;
    end
    % By default, if the old variable was empty, the new variable will also
    % be empty
end

fprintf('%d non-empty strings mapped to numbers\n', n_val);

end