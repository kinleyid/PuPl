
function out = pupl_epoch(EYE, varargin)
% Pupulates the eye_data.epoch field
%
% Inputs:
%   len: string ('fixed' or 'variable')
%       specifies whether epochs are fixed-length or variable-length
%   timelocking: cell array (see pupl-event_sel)
%       specifies the timelocking events
%   other: cell array
%       specifies the non-timelocking event and whether it comes before or
%       after the timelocking event (if epochs are variable-length)
%   lims: cell array of strings
%       specifies when epochs should be defined, relative to the events
%       that mark their onsets and ends
%   overwrite: boolean
%       specifies whether existing epochs should be overwritten
%   names: string or 0
%       specifies the names for epochs
% Example:
%   
if nargin == 0
    out = @getargs;
else
    out = sub_epoch(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin{:}, {
    'len' []
    'timelocking' []
    'lims' []
    'other' []
    'overwrite' []
    'name', []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin);

if any(arrayfun(@(x) ~isempty(x.epoch), EYE)) && isempty(args.overwrite)
    q = 'Overwrite existing epochs?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
    switch a
        case 'Yes'
            args.overwrite = true;
        case 'No'
            args.overwrite = false;
        otherwise
            return
    end
end

if isempty(args.timelocking)
    args.timelocking = pupl_event_selUI(EYE, 'Which are the timelocking events?');
    if isempty(args.timelocking)
        return
    end
end

if isempty(args.len)
    q = sprintf('Fixed or variable length epochs?');
    a = lower(questdlg(q, q, 'Fixed', 'Variable', 'Cancel', 'Fixed'));
    switch a
        case {'fixed' 'variable'}
            args.len = a;
        otherwise
            return
    end
end

if isempty(args.other)
    switch args.len
        case 'fixed'
            args.other = struct(...
                'when', 'after',...
                'event', 0);
        case 'variable'
            rel2 = 'Do epochs end after timelocking events or begin before timelocking events?';
            a = questdlg(rel2, rel2, 'End after', 'Begin before', 'Cancel', 'End after');
            switch a
                case 'End after'
                    args.other.when = 'after';
                    pick_next = 'ends';
                case 'Begin before'
                    args.other.when = 'before';
                    pick_next = 'beginnings';
                otherwise
                    return
            end
            args.other.event = pupl_event_selUI(...
                EYE,...
                sprintf('Epoch %s are defined relative to which events?', pick_next));
            if isempty(args.other.event)
                return
            end
        otherwise
            return
    end
end

if isempty(args.lims)
    rel2 = cell(1, 2);
    rel2(1:2) = {'timelocking events'};
    if strcmp(args.len, 'variable')
        switch args.other.when
            case 'before'
                rel2{1} = 'the events that signal their beginnings';
            case 'after'
                rel2{2} = 'the events that signal their ends';
        end
    end
    args.lims = inputdlg({
        sprintf('Epochs start at this time relative to %s:', rel2{1})
        sprintf('Epochs end at this time relative to %s:', rel2{2})
    });
    if isempty(args.lims)
        return
    end
end

if isempty(args.name)
    q = 'How should epochs be named?';
    a = questdlg(q, q, 'Use timelocking event names', 'Use a custom name', 'Cancel', 'Use timelocking event names');
    switch a
        case 'Use timelocking event names'
            args.name = 0;
        case 'Use a custom name'
            args.name = inputdlg('Custom name for these epochs:');
            if isempty(args.name)
                return
            else
                args.name = args.name{:};
            end
        otherwise
            return
    end
end
if ~isnumeric(args.name)
    fprintf('Defining epochs called "%s"\n', args.name);
else
    fprintf('Defining epochs\n');
end
switch args.other.when
    case 'before'
        if isnumeric(args.other.event)
            fprintf('Epochs begin at %s relative to the timelocking events:\n', args.lims{1});
        else
            fprintf('Epochs begin at %s relative to the following events:\n', args.lims{1});
            txt = pupl_event_selprint(args.other.event);
            fprintf('\t%s\n', txt{:});
        end
        fprintf('Epochs end at %s relative to the timelocking events:\n', args.lims{2});
        txt = pupl_event_selprint(args.timelocking);
        fprintf('\t%s\n', txt{:});
    case 'after'
        fprintf('Epochs begin at %s relative to the timelocking events:\n', args.lims{1});
        txt = pupl_event_selprint(args.timelocking);
        fprintf('\t%s\n', txt{:});
        if isnumeric(args.other.event)
            fprintf('Epochs begin at %s relative to the timelocking events:\n', args.lims{1});
        else
            fprintf('Epochs end at %s relative to the following events:\n', args.lims{2});
            txt = pupl_event_selprint(args.other.event);
            fprintf('\t%s\n', txt{:});
        end
end

outargs = args;

end

function EYE = sub_epoch(EYE, varargin)

args = parseargs(varargin);

if args.overwrite
    EYE.epoch = [];
end

fprintf('Defining epochs...');
epochs = epoch_(EYE, args.timelocking, args.lims, args.other, 'epoch');
fprintf('%d epochs defined\n', numel(epochs));
[epochs.name] = deal(args.name);
[epochs.reject] = deal(false);
[epochs.units] = deal(EYE.units.pupil);

[EYE.epoch, epochs] = fieldconsistency(EYE.epoch, epochs);
EYE.epoch = [EYE.epoch epochs];
% Sort epochs by onset latency
fprintf('Sorting epochs by onset time...');
L = pupl_epoch_get(EYE, [], '_abs');
[~, I] = sort(L(:, 1));
EYE.epoch = EYE.epoch(I);
fprintf('done\n');

end
