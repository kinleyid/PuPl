function EYE = binepochs(EYE, varargin)

%  Inputs
% EYE--struct array
% binDescriptions--struct array with fields:
%   name: name of bin
%   epochs: cell array of names of epochs included in bin

p = inputParser;
addParameter(p, 'binDescriptions', []);
parse(p, varargin{:});

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);

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

if isempty(p.Results.binDescriptions)
    binDescriptions = UI_getsets(unique({EYE.event.type}), 'trial set');
    if isempty(binDescriptions)
        return
    else
        % A little code duct tape
        binDescriptions.epochs = binDescriptions.members;
        rmfield(binDescriptions, 'members');
    end
else
    binDescriptions = p.Results.binDescriptions;
end
callStr = sprintf('%s''binDescriptions'', %s)', callStr, all2str(binDescriptions));

for dataIdx = 1:numel(EYE)
    EYE(dataIdx).history = [
        EYE(dataIdx).history
        callStr];
end

EYE = applybindescriptions(EYE, binDescriptions);

end