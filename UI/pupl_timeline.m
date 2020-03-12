
function varargout = pupl_timeline(direction, varargin)

global pupl_globals

any_printed = true;
switch direction
    case {'append' 'a'}
        curr_idx = find(strcmp(pupl_globals.timeline.data, 'curr')); % Where are we in the timeline?
        pupl_globals.timeline.data{curr_idx} = varargin{1}; % Replace 'curr' with the penultimate data
        pupl_globals.timeline.data{curr_idx + 1} = 'curr'; % Now we're one ahead of the penultimate data
        new_idx = strcmp(pupl_globals.timeline.data, 'curr'); % Now where are we in the timeline?
        n = nnz(~new_idx); % How long is the timeline?
        if n > pupl_globals.timeline.n
            % If we're over memory allocation, remove the oldest data in the timeline
            pupl_globals.timeline.data(1) = [];
        end
        if ~strcmp(pupl_globals.timeline.data{end}, 'curr')
            % If we've added new data to the middle of the timeline, erase
            % the tail--there's no branching structure here
            pupl_globals.timeline.data(find(new_idx)+1:end) = [];
        end
        d = 0;
        any_printed = false;
    case {'backward' 'b'}
        d = - 1;
        fprintf('Undoing...');
    case {'forward' 'f'}
        d = 1;
        fprintf('Redoing...');
    case {'flush'}
        a = questdlg('Are you sure you want to do this? You probably don''t. I don''t even know why I made it an option.');
        if ~strcmp(a, 'Yes')
            if nargout > 0
                varargout{1} = [];
            end
            return
        end
        pupl_globals.timeline.data = {'curr'};
        d = 0;
        fprintf('Erasing undo/redo timeline...');
end

old_idx = find(strcmp(pupl_globals.timeline.data, 'curr'));
new_idx = old_idx + d;

pupl_globals.timeline.data{old_idx} = evalin('base', pupl_globals.datavarname);
if nargout > 0
    varargout{1} = pupl_globals.timeline.data{new_idx};
    if isempty(varargout{1})
        varargout{1} = 'rm';
    end
end
pupl_globals.timeline.data{new_idx} = 'curr';

if any_printed
    fprintf('done\n')
end

end