function EYE = mergelr(EYE, varargin)

p = inputParser;
addParameter(p, 'UI', []);
parse(p, varargin{:});

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

if ~isempty(p.Results.UI)
    fprintf('Merging left and right streams...');
end

for dataIdx = 1:numel(EYE)
    fprintf('dataset %d...', dataIdx)
    EYE(dataIdx).data.both = mean([
        EYE(dataIdx).data.left
        EYE(dataIdx).data.right], 1);
end

if ~isempty(p.Results.UI)
    fprintf('done\n');
    p.Results.UI.UserData.EYE = EYE;
    figure(p.Results.UI);
    writetopanel(p.Results.UI,...
        'processinghistory',...
        sprintf('Merged left and right streams'));
    p.Results.UI.Visible = 'off';
    p.Results.UI.Visible = 'on';
end

end