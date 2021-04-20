function updateglobals(idx, func, outputidx, varargin)

% Updates global variables
%   Inputs
% idx--logical or integer array or 'append'/'a' or 'write'/'w'
% func--function handle or data
% outputidx--which serial output of func to use
% varargin
%   {1} update the undo/redo timeline? true by default
%   {2} text to add to the undo/redo timeline

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
    outputs = outputs{outputidx};
    if isnumeric(outputs)
        if outputs == 0
            return % Do nothing
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
        if numel(varargin) > 1
            timeline_txt = varargin{2};
        else
            timeline_txt = 'undefined operation';
        end
        pupl_timeline('a', old_data, timeline_txt);
    end
    
    % Make sure the new structs are consistent with the old ones
    if isstruct(outputs)
        [new_data, outputs] = fieldconsistency(new_data, outputs);
    end
    
    % Are we subsetting or appending?
    if ischar(idx)
        switch idx
            case {'append' 'a'} % append
                % Keep track of where the new data will be on the UI
                new_UI_n = num2cell(numel(new_data)+1:numel(new_data)+numel(outputs));
                [outputs.UI_n] = new_UI_n{:};
                new_data = cat(pupl_globals.catdim, new_data, outputs);
            case {'write' 'w'} % overwrite
                new_data = outputs;
        end
    else % Logical indexing
        if numel(outputs) < nnz(idx)
            % Less data came out than went in
            % Delete idx, append new data, then sort by UI_n
            new_data(idx) = [];
            new_data = cat(pupl_globals.catdim, new_data, outputs);
            [~, I] = sort([new_data.UI_n]);
            new_data = new_data(I);
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
fprintf('Rendering UI...')
update_UI
fprintf('done\n');

end