function updateglobals(idx, func, outputidx, varargin)

% Updates global variables
%   Inputs
% idx--logical or integer array or 'append'/'a' or 'write'/'w'
% func--function handle or data
% outputidx--which serial output of func to use
% varargin--update the timeline? true by default

global pupl_globals

if isempty(idx) ||...
        isempty(outputidx)
    % Function has no outputs
    feval(func)
else
    old_data = evalin('base', pupl_globals.datavarname); % Keep a copy for undo/redo timeline
    
    % Get the outputs
    outputs = cell(1, outputidx);
    [outputs{:}] = feval(func);
    
    % Subset the outputs
    rm = false;
    outputs = outputs{outputidx};
    if isempty(outputs)
        return
    elseif ischar(outputs)
        if ismember(outputs, {'rm' 'del'})
            rm = true;
        else
            outputs = eval(outputs);
        end
    end
    
    % Get the global data variable
    new_data = evalin('base', pupl_globals.datavarname);
    
    % Update undo/redo timeline
    if numel(varargin) > 0
        update_timeline = varargin{1};
    else
        update_timeline = true;
    end
    if update_timeline
        pupl_timeline('a', old_data);
    end
    
    % Make sure the new structs are consistent with the old ones
    if isstruct(outputs)
        [new_data, outputs] = fieldconsistency(new_data, outputs);
    end
    
    % Are we subsetting or appending?
    if ischar(idx)
        switch idx
            case {'append' 'a'}
                new_data = cat(pupl_globals.catdim, new_data, outputs);
            case {'write' 'w'}
                if rm
                    new_data = struct([]);
                else
                    new_data = outputs;
                end
        end
    else
        if rm
            new_data(idx) = [];
        else
            new_data(idx) = outputs;
        end
    end
    
    if isempty(new_data)
        new_data = struct([]); % So that it's 0x0
    end
    
    % Update the global variable
    assignin('base', pupl_globals.datavarname, new_data);
end

% Update the user interface
update_UI

end