function updateglobals(globalVarName, idx, func, outputidx)

% Updates global variables
%   Inputs
% globalVarName--string, ignored
% idx--logical or integer array or 'append'
% func--function handle
% outputidx--which serial output of func to use

global pupl_globals
pupl_globals.datavarname = pupl_globals.datavarname;

if isempty(pupl_globals.datavarname) ||...
        isempty(idx) ||...
        isempty(outputidx)
    % Function has no outputs
    feval(func)
else
    % Get the outputs
    outputs = cell(1, outputidx);
    [outputs{:}] = feval(func);
    
    % Subset the outputs
    outputs = outputs{outputidx};
    if isempty(outputs)
        return
    end
    
    % Get the global data variable
    tmp_datavar = evalin('base', pupl_globals.datavarname);
    
    % Make sure the new structs are consistent with the old ones
    [tmp_datavar, outputs] = fieldconsistency(tmp_datavar, outputs);
    
    % Are we subsetting or appending?
    if strcmpi(idx, 'append')
        % We are appending
        tmp_datavar = cat(pupl_globals.catdim, tmp_datavar, outputs);
    else
        % We are subsetting
        tmp_datavar(idx) = outputs;
    end
    
    % Update the global variable
    assignin('base', pupl_globals.datavarname, tmp_datavar);
end

% Update the user interface
update_UI

end