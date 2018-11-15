function EYE = binepochs(EYE, varargin)

%  Inputs
% EYE--struct array
% binDescriptions--struct array with fields:
%   name: name of bin
%   epochs: cell array of names of epochs included in bin

p = inputParser;
addParameter(p, 'binDescriptions', []);
addParameter(p, 'UI', []);
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

if isempty(p.Results.binDescriptions)
    binDescriptions = UI_getbindescriptions(EYE);
else
    binDescriptions = p.Results.binDescriptions;
end

EYE = applybindescriptions(EYE, binDescriptions);

if ~isempty(p.Results.UI)
    p.Results.UI.UserData.EYE = EYE;
    p.Results.UI.Visible = 'off';
    p.Results.UI.Visible = 'on';
    writetopanel(p.Results.UI,...
        'processinghistory',...
        'Organization of epochs into sets');
end

end