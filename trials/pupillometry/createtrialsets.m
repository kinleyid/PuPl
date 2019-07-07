function EYE = createtrialsets(EYE, varargin)

%  Inputs
% EYE--struct array
% binDescriptions--struct array with fields:
%   name: name of bin
%   epochs: cell array of names of epochs included in bin

p = inputParser;
addParameter(p, 'setDescriptions', []);
parse(p, varargin{:});

callstr = sprintf('eyeData = %s(eyeData, ', mfilename);

if any(arrayfun(@(x) ~isempty(x.bin), EYE))
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
else
    overwrite = false;
end

if overwrite
    [EYE.bin] = deal([]);
end

if isempty(p.Results.setDescriptions)
    setDescriptions = UI_getsets(unique(mergefields(EYE, 'epoch', 'name')), 'trial set');
    if isempty(setDescriptions)
        return
    end
else
    setDescriptions = p.Results.setDescriptions;
end
callstr = sprintf('%s''setDescriptions'', %s)', callstr, all2str(setDescriptions));

fprintf('Merging trials into sets...\n')
for dataidx = 1:numel(EYE)
    fprintf('\t%s...\n', EYE(dataidx).name);
    EYE(dataidx).trialset = struct([]);
    for setidx = 1:numel(setDescriptions)
        epochidx = find(ismember({EYE(dataidx).epoch.name}, setDescriptions(setidx).members));
        relLatencies = {EYE(dataidx).epoch(epochidx).relLatencies};
        if numel(unique(cellfun(@num2str, relLatencies, 'UniformOutput', 0))) > 1
            warning('You are combining epochs into a bin that do not all begin and end at the same time relative to their events');
            relLatencies = [];
        else
            relLatencies = EYE(dataidx).epoch(1).relLatencies;
        end
        EYE(dataidx).trialset = [
            EYE(dataidx).trialset...
            struct(...
                'name', setDescriptions(setidx).name,...
                'members', {setDescriptions(setidx).members},...
                'relLatencies', relLatencies,...
                'epochidx', epochidx)
        ];
        fprintf('\t\tSet %s contains %d trials\n', setDescriptions(setidx).name, nnz(epochidx));
    end
    EYE(dataidx).history{end+1} = callstr;
end

fprintf('Done\n');

end