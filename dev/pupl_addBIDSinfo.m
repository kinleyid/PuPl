
function EYE = pupl_addBIDSinfo(EYE, varargin)

for dataidx = 1:numel(EYE)
    data = inputdlg({
        sprintf('%s\n\nSubject ID:', EYE(dataidx).name)
        'Session'},...
        
end

end
