function EYE = pupl_condition(EYE, varargin)

% Organize datasets into experimental conditions
%   Inputs
% EYE--struct array
% conditions--char cell array of condition names
% condIdx--numerical array of conditions.
%   E.g. if the first three datasets are part of condition 1 and the next 2
%   are part of condition 2, condIdx would be [1 1 1 2 2].

p = inputParser;
addParameter(p, 'condstruct', []);
addParameter(p, 'overwrite', []);
parse(p, varargin{:});

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

if isempty(p.Results.condstruct)
    condstruct = UI_getsets({EYE.name}, 'Condition');
    if isempty(condstruct)
        return
    end
else
    condstruct = p.Results.condstruct;
end

if isempty(p.Results.overwrite)
    if isnonemptyfield(EYE, 'cond')
        q = 'Overwrite existing condition assignments?';
        a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
        switch a
            case 'Yes'
                overwrite = true;
            case 'No'
                overwrite = false;
            otherwise
                return
        end
    else
        overwrite = false;
    end
else
    overwrite = p.Results.overwrite;
end

callstr = getcallstr(p);

if overwrite
    [EYE.cond] = deal('');
end

for condidx = 1:numel(condstruct)
    membersidx = ismember({EYE.name}, condstruct(condidx).members);
    for dataidx = find(membersidx)
        EYE(dataidx).cond = [EYE(dataidx).cond {condstruct(condidx).name}];
    end
    fprintf('Condition ''%s'' contains:\n', condstruct(condidx).name);
    fprintf('\t%s\n', condstruct(condidx).members{:});
end

for dataidx = 1:numel(EYE)
    EYE(dataidx).history{end + 1} = callstr;
end

end