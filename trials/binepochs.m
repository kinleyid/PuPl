function EYE = binepochs(EYE, varargin)

%  Inputs
% EYE--struct array
% binDescriptions--struct array with fields:
%   name: name of bin
%   epochs: cell array of names of epochs included in bin

p = inputParser;
addParameter(p, 'binDescriptions', []);
parse(p, varargin{:});

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

try arrayfun(@(x) x.epoch, EYE, 'un', 0);
catch
    uiwait(msgbox('At least one dataset does not have trials'));
    return
end

if any(arrayfun(@(x) ~isempty(x.bin), EYE))
    q = 'Overwrite existing trial sets?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
    switch a
        case 'Yes'
            [EYE.bin] = deal([]);
        case 'No'
        otherwise
            return
    end
end

if isempty(p.Results.binDescriptions)
    binDescriptions = UI_getbindescriptions(EYE);
    if isempty(binDescriptions)
        return
    end
else
    binDescriptions = p.Results.binDescriptions;
end

EYE = applybindescriptions(EYE, binDescriptions);

end