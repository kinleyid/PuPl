
function processBIDSsourcedata

projectpath = uigetdir(pwd, 'Select top-level folder');
if projectpath == 0
    return
end

sourcedatapath = uigetdir(projectpath, 'Select sourcedata folder');
if isnumeric(sourcedatapath)
    return
end

[f, p] = uigetfile(sprintf('%s%s*.m', projectpath, filesep), 'Select pipeline script');
if f == 0
    return
else
    scriptpath  = sprintf('%s', p, f);
end

deriv = inputdlg('Name of derivative?');
if isempty(deriv)
    return
end

fprintf('\n\nLoading source data from %s\n\n', sourcedatapath);
sourcedata = loadBIDSsourcedata(sourcedatapath);
[~, n, x] = fileparts(scriptpath);
fprintf('\n\nRunning processing pipeline %s\n\n', [n x]);
processed = pupl_pipeline(sourcedata, 'scriptpath', scriptpath);
fprintf('\n\nSaving to %s\n\n', fullfile('derivatives', deriv{:}));
writeBIDS(processed, 'projectpath', projectpath, 'types', deriv);
fprintf('\n\nDone\n\n');

end