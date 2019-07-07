
function remapsourcedata

% Get project path
sourcedatapath = uigetdir;
if isnumeric(sourcedatapath)
    return
end
EYE = loadBIDSsourcedata(sourcedatapath);
for dataidx = 1:numel(EYE)
    k = strfind(EYE(dataidx).src, 'sourcedata');
    EYE(dataidx).src = fullfile(sourcedatapath, EYE(dataidx).src(k:end));
end
writeBIDS(EYE, 'types', 'sourcedata-current');

end