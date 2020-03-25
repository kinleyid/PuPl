
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
    q = 'Cropping data will delete all epochs and epoch sets. Continue?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No')
        return
    end
end

args = parseargs(varargin{:});

if isempty(args.cfg)
    str = {'starting from' 'up until'};
    for i = 1:2
        curr_cfg = [];
        curr_cfg.event = pupl_event_UIget([EYE.event], sprintf('Retain data %s which event?', str{i}));
        if isempty(curr_cfg.event)
            return
        end
        curr_cfg.instance = inputdlg(sprintf('Retain data %s which instance of said event?\n\nE.g. 1, 2.\n\nTo start counting from the final instance, input a negative number (E.g. -1 would be the final instance, -2 would be the second-to-last instance, etc.).\n', str{i}));
        if isempty(curr_cfg.instance)
            return
        else
            curr_cfg.instance = str2double(curr_cfg.instance{:});
        end
        curr_cfg.lim = inputdlg(sprintf('Retain data %s what time relative to instance %d of said event?\n\nE.g. 1s, -200ms\n', str{i}, curr_cfg.instance));
        if isempty(curr_cfg.lim)
            return
        else
            curr_cfg.lim = curr_cfg.lim{:};
        end
        args.cfg = [args.cfg curr_cfg];
    end
end

outargs = args;
%{
for i = 1:2
    fprintf('Retaining data %s:\n', str{i});
    fprintf('\t%s relative to instance %d of "%s"\n', args.cfg(i).lim, args.cfg(i).instance, args.cfg(i).event)
end
%}
fprintf('All other data will be removed.\n');

end

function EYE = sub_crop(EYE, varargin)

args = parseargs(varargin{:});

bookend_event_times = [];
for i = 1:2
    event_matches = find(pupl_event_sel(EYE.event, args.cfg(i).event));
    if args.cfg(i).instance < 0
        inst = numel(event_matches) + args.cfg(i).instance + 1;
    else
        inst = args.cfg(i).instance;
    end
    event_idx = event_matches(inst);
    bookend_event_times(i) = EYE.event(event_idx).time;
end

% For current srate
lims = bookend_event_times + parsetimestr({args.cfg.lim}, EYE.srate);

% Remove events
event_times = [EYE.event.time];
event_rmidx = event_times <= lims(1) | event_times >= lims(2);
EYE.event(event_rmidx) = [];

% Remove data
data_times = EYE.times;
data_rmidx = data_times <= lims(1) | data_times >= lims(2);
for field1 = {'gaze' 'pupil' 'times' 'datalabel'}
    if isstruct(EYE.(field1{:}))
        for field2 = reshape(fieldnames(EYE.(field1{:})), 1, [])
            EYE.(field1{:}).(field2{:})(data_rmidx) = [];
        end
    else
        EYE.(field1{:})(data_rmidx) = [];
    end
end

% For ur srate
lims = bookend_event_times + parsetimestr({args.cfg.lim}, EYE.ur.srate);
% Remove ur data
ur_times = EYE.ur.times;
ur_rmidx = ur_times <= lims(1) | ur_times >= lims(2);
for field1 = {'gaze' 'pupil' 'times'}
    if isstruct(EYE.ur.(field1{:}))
        for field2 = reshape(fieldnames(EYE.ur.(field1{:})), 1, [])
            if isstruct(EYE.ur.(field1{:}).(field2{:}))
                for field3 = reshape(fieldnames(EYE.ur.(field1{:}).(field2{:})), 1, [])
                    EYE.ur.(field1{:}).(field2{:}).(field3{:})(ur_rmidx) = [];
                end
            else
                EYE.ur.(field1{:}).(field2{:})(ur_rmidx) = [];
            end
        end
    else
        EYE.ur.(field1{:})(ur_rmidx) = [];
    end
end

% Adjust recording length
prior_n = EYE.ndata;
EYE.ndata = numel(EYE.times);
n_removed = prior_n - EYE.ndata;
fprintf('%d datapoints (%f seconds) cropped\n', n_removed, n_removed / EYE.srate);

end
