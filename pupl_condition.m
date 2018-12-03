function EYE = pupl_condition(EYE, varargin)

% Organize datasets into experimental conditions
%   Inputs
% EYE--struct array
% conditions--char cell array of condition names
% condIdx--numerical array of conditions.
%   E.g. if the first three datasets are part of condition 1 and the next 2
%   are part of condition 2, condIdx would be [1 1 1 2 2].

p = inputParser;
addParameter(p, 'conditions', []);
addParameter(p, 'condIdx', []);
parse(p, varargin{:});

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

if isempty(p.Results.conditions)
    conditions = [];
    nConditions = 1;
    while true
        currName = inputdlg(sprintf('Name of condition %d?', nConditions));
        if isempty(char(currName))
            break
        else
            nConditions = nConditions + 1;
            conditions = cat(1, conditions, currName);
        end
    end
    if isempty(conditions)
        return
    end
else
    conditions = p.Results.conditions;
end

if isempty(p.Results.condIdx)
    for condIdx = 1:length(conditions)
        dataIdx = listdlg('PromptString', sprintf('Which datasets are in %s?', conditions{condIdx}),...
            'ListString', {EYE.name});
        [EYE(dataIdx).cond] = deal(conditions{condIdx});
    end
else
    [EYE.cond] = conditions(p.Results.condIdx);
end

end