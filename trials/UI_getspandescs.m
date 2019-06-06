function spandescs = UI_getspandescs(EYE, varargin)

%   Inputs
% EYE: struct array
% basic: 'off' (default) or 'on'
% spanName: 'span' (default) | string to refer to spans (e.g. 'trial'--don't pluralize or capitalize)
% n: 'single' (default) or 'multi' or whatever else you want
%   Outputs
% spandescs: struct array with fields:
%   name: char array
%   events: 1 x 2 cell array
%   bookends: 1 x 2 cell array
%   instanceidx: integer array

p = inputParser;
addParameter(p, 'basic', 'on');
addParameter(p, 'spanName', 'span');
addParameter(p, 'n', 'single');
parse(p, varargin{:});

% Options for defining spans
%   Basic: all spans are of the same length and defined according to single
%   events
%   Advanced: all options are available

allEventTypes = unique(mergefields(EYE, 'event', 'type'));

spandescs = struct([]);

while true
    if strcmp(p.Results.basic, 'on')
        events = allEventTypes(listdlgregexp('PromptString', sprintf('Define %s relative to which events?', p.Results.spanName),...
            'ListString', allEventTypes));
        if isempty(events)
            return
        end
        bookends = (inputdlg({
            sprintf('%ss start at this time relative to events:', [upper(p.Results.spanName(1)) p.Results.spanName(2:end)])
            sprintf('%ss end at this time relative to events:', [upper(p.Results.spanName(1)) p.Results.spanName(2:end)])
        }));
        if isempty(bookends)
            return
        end
        for eventidx = 1:numel(events)
            spandescs = cat(2, spandescs, struct(...
                'name', events{eventidx},...
                'events', {events{eventidx} 0},...
                'bookends', bookends,...
                'instanceidx', 0));
        end
    else
        name = (inputdlg({
            sprintf('Name of %s?', p.Results.spanName)
        }));
        if isempty(name)
            return
        end
        events1 = allEventTypes(listdlgregexp('PromptString', sprintf('%ss start relative to which events?', [upper(p.Results.spanName(1)) p.Results.spanName(2:end)]),...
            'ListString', allEventTypes));
        if isempty(events1)
            return
        end
        events2 = allEventTypes(listdlgregexp('PromptString', sprintf('%ss end relative to which events?', [upper(p.Results.spanName(1)) p.Results.spanName(2:end)]),...
            'ListString', allEventTypes));
        if isempty(events2)
            return
        end
        bookends = (inputdlg({
            sprintf('%ss start at this time relative to first events:', [upper(p.Results.spanName(1)) p.Results.spanName(2:end)])
            sprintf('%ss end at this time relative to final events:', [upper(p.Results.spanName(1)) p.Results.spanName(2:end)])
        }));
        if isempty(bookends)
            return
        end
        instanceidx = (inputdlg({
            'Which instances? (e.g. 1:3, 1 3 4--0 for any)'
        }));
        if isempty(instanceidx)
            return
        else
            instanceidx = str2num(instanceidx{:});
        end
        spandescs = cat(2, spandescs, struct(...
            'name', name,...
            'events', {{events1{:} events2{:}}},...
            'bookends', {bookends{:}},...
            'instanceidx', instanceidx));
    end
    if strcmp(p.Results.n, 'single')
        return
    else
        q = sprintf('Define more %ss?', p.Results.spanName);
        a = questdlg(q, q, 'Yes', 'No', 'Cancel');
        switch a
            case 'Yes'
                continue
            case 'No'
                break
            otherwise
                spandescs = [];
                return
        end
    end
end

end