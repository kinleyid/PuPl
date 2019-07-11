function EYE = createtrialsets(EYE, varargin)

%  Inputs
% EYE--struct array
% binDescriptions--struct array with fields:
%   name: name of bin
%   epochs: cell array of names of epochs included in bin

p = inputParser;
addParameter(p, 'setdescriptions', []);
addParameter(p, 'overwrite', []);
parse(p, varargin{:});

if isempty(p.Results.overwrite)
    if any(arrayfun(@(x) ~isempty(x.trialset), EYE))
        q = 'Overwrite existing trial sets?';
        a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
        switch a
            case 'Yes'
                overwrite = true;
            case 'No'
                overwrite = false;
            otherwise
                return
        end
    end
else
    overwrite = p.Results.overwrite;
end

if isempty(p.Results.setdescriptions)
    setdescriptions = UI_getsets(unique(mergefields(EYE, 'epoch', 'name')), 'trial set');
    if isempty(setdescriptions)
        return
    end
else
    setdescriptions = p.Results.setdescriptions;
end

fprintf('Merging trials into sets...\n')
for dataidx = 1:numel(EYE)
    fprintf('\t%s...\n', EYE(dataidx).name);
    EYE(dataidx) = sub_createtrialsets(EYE(dataidx), setdescriptions, overwrite);
    for setidx = 1:numel(setdescriptions)
        fprintf('\t\tSet %s contains %d trials\n',...
            setdescriptions(setidx).name,...
            nnz(EYE(dataidx).trialset(strcmp({EYE(dataidx).trialset.name}, setdescriptions(setidx).name)).epochidx));
    end
    EYE(dataidx).history{end+1} = getcallstr(p);
end

fprintf('Done\n');

end