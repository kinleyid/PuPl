function EYE = binepochs(EYE, varargin)

%  Inputs
% EYE--struct array
% binDescriptions--struct array with fields:
%   name: name of bin
%   epochs: cell array of names of epochs included in bin

p = inputParser;
addParameter(p, 'binDescriptions', []);
addParameter(p, 'overwrite', []);
parse(p, varargin{:});

callStr = sprintf('%s(', mfilename);

if isempty(p.Results.overwrite)
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
    overwrite = p.Results.overwrite;
end
callStr = sprintf('%s''overwrite'', %s, ', callStr, all2str(overwrite));

if overwrite
    [EYE.bin] = deal([]);
end

if isempty(p.Results.binDescriptions)
    binDescriptions = UI_getbindescriptions(EYE);
    if isempty(binDescriptions)
        return
    end
else
    binDescriptions = p.Results.binDescriptions;
end
callStr = sprintf('%s''binDescriptions'', %s', callStr, all2str(binDescriptions));

for dataIdx = 1:numel(EYE)
    EYE(dataIdx).history = [
        EYE(dataIdx).history
        callStr];
end

EYE = applybindescriptions(EYE, binDescriptions);

end