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
    nConditions = str2double(inputdlg('How many conditions?'));
    if isempty(nConditions)
        EYE = [];
        return
    end
    conditions = UI_getnames(...
        arrayfun(@(x) sprintf('Name of condition %d', x), 1:nConditions, 'un', 0),...
        repmat({''}, nConditions, 1));
    if isempty(conditions)
        EYE = [];
        return
    end
else
    conditions = p.Results.conditions;
end

if isempty(p.Results.condIdx)
    for condIdx = 1:length(conditions)
        dataIdx = listdlg('PromptString', sprintf('Which datasets are in %s?', conditions{condIdx}),...
            'ListString', {EYE.name});
        for curridx = dataIdx
            if ~isfield(EYE(dataIdx), 'cond')
                EYE(dataIdx).cond = [];
            end
            EYE(curridx).cond = EYE(curridx).cond(:)';
            EYE(curridx).cond = [EYE(curridx).cond conditions(condIdx)];
        end
        fprintf('Condition %s includes:\n', conditions{condIdx})
        fprintf('\t%s\n', EYE(dataIdx).name)
    end
else
    [EYE.cond] = conditions(p.Results.condIdx);
end

EYE = pupl_merge(EYE);

end