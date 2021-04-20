
function out = pupl_cat(EYE, varargin)
% Concatenate recordings
%
% Inputs:
%   sel: cell array
%       each element selects a block of recordings
%   ev_suffix: cellstr
%       each element is a suffix for a the events in a different block
%   rec_suffiv: cellstr
%       the suffix to append to the recording name
% Example:
%   pupl_cat(eye_data,...
%       'sel', {{1 'b1'} {1 'b2'} {1 'b3'} {1 'b4'} {1 'b5'} {1 'b6'}},...
%       'ev_suffix', {'' '' '' '' '' ''},...
%       'rec_suffix', {''});
if nargin == 0
    out = @getargs;
else
    out = sub_cat(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'sel' []
    'ev_suffix' []
    'rec_suffix' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.sel)
    str2 = 'Concatenate which recordings?';
    str = {
        'Concatenate to the ends of which recordings?'
        str2
    };
    for i = 1:2
        [~, sel] = listdlgregexp(...
            'PromptString', str{i},...
            'ListString', {EYE.name},...
            'AllowRegexp', true);
        if isempty(sel)
            return
        else
            args.sel{i} = sel;
        end
    end
    while true
        a = questdlg('Concatenate more recordings?');
        switch a
            case 'No'
                break
            case 'Yes'
                [~, sel] = listdlgregexp(...
                    'PromptString', str2,...
                    'ListString', {EYE.name},...
                    'AllowRegexp', true);
                if isempty(sel)
                    return
                else
                    args.sel{end + 1} = sel;
                end
            otherwise
                return
        end
    end
end

if isempty(args.rec_suffix)
    rec_suffix = inputdlg('Suffix to add to the names of the first block of recordings?');
    if isempty(rec_suffix)
        return
    else
        args.rec_suffix = rec_suffix;
    end
end

if isempty(args.ev_suffix)
    for i = 1:numel(args.sel)
        ev_suffix = inputdlg(sprintf('Suffix to add to the events from block %d of the recordings?', i));
        if isempty(ev_suffix)
            return
        else
            args.ev_suffix{i} = ev_suffix{:};
        end
    end
end

allnames = {EYE.name};
allrecs = [];
for selidx = 1:numel(args.sel)
    sel = args.sel(selidx);
    idx = regexpsel(allnames, sel{:});
    currnames = allnames(idx);
    if ~isempty(allrecs) && numel(currnames) ~= size(allrecs, 2)
        error('There are %d recordings in block %d but %d in the prior block(s)', numel(currnames), selidx, size(allrecs, 2));
    end
    allrecs = [
        allrecs
        currnames
    ];
end

fprintf('Concatenating as follows:\n');
for idx = 1:size(allrecs, 2)
    fprintf('\t%s = ', strcat(allrecs{1, idx}, args.rec_suffix{:}))
    str = sprintf('%s + ', allrecs{:, idx});
    str(end-2:end) = [];
    fprintf('%s\n', str);
end

outargs = args;

end

function EYE = sub_cat(EYE, varargin)

args = parseargs(varargin{:});

allnames = {EYE.name};
allrecs = [];
args.sel = args.sel(:)';
idx = regexpsel(allnames, args.sel{1});
allrecs = [
    allrecs
    EYE(idx)
];
keep_idx = find(idx);
rm_idx = [];
for sel = args.sel(2:end)
    idx = regexpsel(allnames, sel{:});
    allrecs = [
        allrecs
        EYE(idx)
    ];
    rm_idx = [rm_idx find(idx)];
end

nsets = size(allrecs, 2);
nper = size(allrecs, 1);
sets = mat2cell(allrecs, nper, ones(1, nsets));

fprintf('Concatenating...\n');
for setidx = 1:nsets
    for i = 1:numel(args.ev_suffix)
        newnames = strcat({sets{setidx}(i).event.name}, args.ev_suffix{i});
        [sets{setidx}(i).event.name] = newnames{:};
    end
    
    % Fix timestamps and uniqids
    last = sets{setidx}(1);
    for dataidx = 2:nper
        % Reset timestamps for events and samples
        last_t = last.ur.times(end);
        sp = 1/last.ur.srate;
        first_t = sets{setidx}(dataidx).ur.times(1);
        time_diff = first_t - (last_t + sp);
        event_times = [sets{setidx}(dataidx).event.time];
        event_times = num2cell(event_times - time_diff);
        [sets{setidx}(dataidx).event.time] = event_times{:};
        sets{setidx}(dataidx).times = sets{setidx}(dataidx).times - time_diff;
        sets{setidx}(dataidx).ur.times = sets{setidx}(dataidx).ur.times - time_diff;
        % Reset uniqids for events, epochs, and baselines
        % Events:
        last_uniqid = max([last.event.uniqid]);
        curr_uniqid = [sets{setidx}(dataidx).event.uniqid];
        first_uniqid = min(curr_uniqid);
        uniqid_diff = first_uniqid - (last_uniqid + 1);
        new_uniqid = num2cell(curr_uniqid - uniqid_diff);
        [sets{setidx}(dataidx).event.uniqid] = new_uniqid{:};
        if isnonemptyfield(sets{setidx}(dataidx), 'epoch')
            curr_uniqid = [sets{setidx}(dataidx).epoch.event];
            new_uniqid = num2cell(curr_uniqid - uniqid_diff);
            [sets{setidx}(dataidx).epoch.event] = new_uniqid{:};
            if isfield(sets{setidx}(dataidx).epoch, 'baseline')
                curr_uniqid = mergefields(sets{setidx}(dataidx), 'epoch', 'baseline', 'event');
                new_uniqid = curr_uniqid - uniqid_diff;
                % Wish there was a more elegant way to do this
                for epochidx = 1:numel(sets{setidx}(dataidx).epoch)
                    sets{setidx}(dataidx).epoch(epochidx).baseline.event = new_uniqid(epochidx);
                end
            end
        end
        % Do it all again
        last = sets{setidx}(dataidx);
    end
    
    % Append data fields
    fields = {
        'datalabel'
        'interstices'
        'times'
        {'ur' 'times'}
        {'pupil' 'left'}
        {'pupil' 'right'}
        {'pupil' 'both'}
        {'gaze' 'x'}
        {'gaze' 'y'}
        'event'
        'epoch'
        {'ur' 'gaze' 'x' 'left'}
        {'ur' 'gaze' 'x' 'right'}
        {'ur' 'gaze' 'y' 'left'}
        {'ur' 'gaze' 'y' 'right'}
        {'ur' 'pupil' 'left'}
        {'ur' 'pupil' 'right'}
    };
    curr = sets{setidx}(1);
    fprintf('\t%s', curr.name);
    for dataidx = 2:nper
        for fieldidx = 1:numel(fields)
            currfields = fields{fieldidx};
            if ~iscell(currfields)
                currfields = {currfields};
            end
            % Append
            if isnonemptyfield(curr, currfields{:}) && isnonemptyfield(sets{setidx}(dataidx), currfields{:})
                curr = setfield(curr, currfields{:}, cat(2,...
                    getfield(curr, currfields{:}),...
                    getfield(sets{setidx}(dataidx), currfields{:})));
            end
        end
        fprintf(' + %s', sets{setidx}(dataidx).name);
    end
    fprintf('\n');
    curr.name = strcat(curr.name, args.rec_suffix{:});
    curr.ndata = numel(curr.pupil.left);
    EYE(keep_idx(setidx)) = curr;
end

EYE(rm_idx) = [];

end