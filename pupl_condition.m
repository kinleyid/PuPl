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
addParameter(p, 'UI', []);
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
    remainingData = {EYE.name};
    for i = 1:length(conditions)
        currIdx = listdlg('PromptString', sprintf('Which datasets are in %s?', conditions{i}),...
            'ListString', remainingData);
        EYE(ismember(remainingData(currIdx), {EYE.name})).cond = conditions(i);
        remainingData(currIdx) = [];
    end
else
    [EYE.condition] = conditions(p.Results.condIdx);
end

if ~isempty(p.Results.UI)
    p.Results.UI.UserData.EYE = EYE;
    p.Results.UI.Visible = 'off';
    p.Results.UI.Visible = 'on';
    writetopanel(p.Results.UI,...
        'processinghistory',...
        'Assignment to condition');
end