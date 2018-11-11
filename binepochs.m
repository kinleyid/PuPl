function EYE = binepochs(EYE, varargin)

%  Inputs
% EYE--struct array
% binDescriptions--struct array with fields:
%   name: name of bin
%   epochs: cell array of names of epochs included in bin

p = inputParser;
addParameter(p, 'binDescriptions', []);
addParameter(p, 'saveTo', []);
parse(p, varargin{:});

if isempty(p.Results.binDescriptions)
    binDescriptions = UI_getbindescriptions(EYE);
else
    binDescriptions = p.Results.binDescriptions;
end

EYE = applybindescriptions(EYE, binDescriptions);

saveeyedata(EYE, p.Results.saveTo, 'binful');

end