
function out = pupl_crop(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_crop(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'cfg', []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];

if isnonemptyfield(EYE, 'epoch')
    q = 'Cropping data will delete epochs and epoch sets. Continue?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No')
        return
    end
end

args = parseargs(varargin{:});

allevents = unique(mergefields(EYE, 'event', 'type'));

if isempty(args.cfg)
    str = {'starting from' 'up until'};
    for i = 1:2
        curr_cfg = [];
        [~, curr_cfg.event] = listdlgregexp(...
            'PromptString', sprintf('Retain data %s which event?', str{i}),...
            'ListString', allevents,...
            'SelectionMode', 'single');
        if isempty(curr_cfg.event)
            return
        else
            curr_cfg.event = curr_cfg.event{:};
        end
        curr_cfg.instance = inputdlg(sprintf('Retain data %s which instance of "%s"?\n\nE.g. 1, 2.\n\nTo start counting from the final instance, input a negative number (E.g. -1 would be the final instance, -2 would be the second-to-last instance, etc.).\n', str{i}, curr_cfg.event));
        if isempty(curr_cfg.instance)
            return
        else
            curr_cfg.instance = str2double(curr_cfg.instance{:});
        end
        curr_cfg.lim = inputdlg(sprintf('Retain data %s what time relative to instance %d of "%s"?\n\nE.g. 1s, -200ms\n', str{i}, curr_cfg.instance, curr_cfg.event));
        if isempty(curr_cfg.lim)
            return
        else
            curr_cfg.lim = curr_cfg.lim{:};
        end
        args.cfg = [args.cfg curr_cfg];
    end
end

outargs = args;

for i = 1:2
    fprintf('Retaining data %s:\n', str{i});
    fprintf('\t%s relative to instance %d of "%s"\n', args.cfg(i).lim, args.cfg(i).instance, args.cfg(i).event)
end
fprintf('All other data will be removed.\n');

end

function EYE = sub_crop(EYE, varargin)

args = parseargs(varargin{:});

lims = [nan nan];
for i = 1:2
    event_matches = find(strcmp(args.cfg(i).event, {EYE.event.type}));
    event_idx = event_matches(args.cfg(i).instance);
    lims(i) = EYE.event(event_idx).latency + parsetimestr(args.cfg(i).lim, EYE.srate, 'smp');
end

% Start by cropping data from the end

% Remove events
EYE.event([EYE.event.latency] > lims(2)) = [];
% Remove data
EYE = pupl_proc(EYE, @(x) rmdata(x, lims(2), @gt), 'all');

% Now crop from the beginning

% Remove events
EYE.event([EYE.event.latency] < lims(1)) = [];
% Remove data
EYE = pupl_proc(EYE, @(x) rmdata(x, lims(1), @lt), 'all');

% Adjust time measurements

time_change = (lims(1) - 1) / EYE.srate;

% Adjust t0
EYE.t1 = EYE.t1 + time_change;
% Adjust the latencies and times of each event
for idx = 1:numel(EYE.event)
    EYE.event(idx).latency = EYE.event(idx).latency - (lims(1) - 1);
    EYE.event(idx).time = EYE.event(idx).time - time_change;
end
% Adjust recording length
prior_n = EYE.ndata;
EYE.ndata = EYE.ndata - (lims(1) - 1) - (EYE.ndata - lims(2));
n_removed = prior_n - EYE.ndata;
fprintf('%d datapoints (%f seconds) cropped\n', n_removed, n_removed / EYE.srate);

end

function x = rmdata(x, idx, f)

badidx = f(1:numel(x), idx);
x(badidx) = [];

end