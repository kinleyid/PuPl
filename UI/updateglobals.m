function updateglobals(globalVarName, globalVarIndex, functionToCall, outputIndex)

% Updates global variables
% This is my least favourite part of this code
%   Inputs
% globalVarName--string
% globalVarIndex--logical or integer array or 'append'
% functionToCall--function handle
% outputIndex--which serial output of functionToCall to assign to

if isempty(globalVarName) ||...
        isempty(globalVarIndex) ||...
        isempty(outputIndex)
    % Function has no outputs
    feval(functionToCall)
else
    % Get the outputs
    codeSmell = cell(1, outputIndex);
    [codeSmell{:}] = feval(functionToCall);
    
    % Subset the outputs
    codeSmell = codeSmell{outputIndex};
    if isempty(codeSmell)
        return
    end
    % Make sure the new structs are consistent with the old ones
    eval(sprintf('global %s', globalVarName));
    eval(sprintf('[%s, codeSmell] = fieldconsistency(%s, codeSmell);', globalVarName, globalVarName));
    % Are we subsetting or appending?
    if strcmpi(globalVarIndex, 'append')
        % We are appending
        % eval(sprintf('[~, dim] = max(size(%s));', globalVarName));
        eval(sprintf('%s = cat(2, %s, codeSmell);', globalVarName, globalVarName));
    else
        % We are subsetting
        eval(sprintf('%s(globalVarIndex) = codeSmell;', globalVarName));
    end
end

% Update the user interface
update_UI

end