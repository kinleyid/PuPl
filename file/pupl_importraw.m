
function out = pupl_importraw(loadfunc, varargin)

% Varargin{1}: true if loading from BIDS raw data
out = struct([]);

q = 'Load BIDS raw data?';
a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
switch a
    case 'Yes'
        rawdatapath = uigetdir(pwd, 'Select raw data folder');
        if isnumeric(rawdatapath)
            return
        end
        out = importBIDSraw(rawdatapath, loadfunc, '_eyetrack.', true);
    case 'No'
        [filenames, directory] = uigetfile('*.*',...
            'MultiSelect', 'on');
        if isnumeric(filenames)
            return
        end
        filenames = cellstr(filenames);
        fprintf('Importing raw data...\n')
        for dataidx = 1:numel(filenames)
            fprintf('\t%s...\n', filenames{dataidx});
            currsrc = fullfile(directory, filenames{dataidx});
            [~, n, x] = fileparts(currsrc);
            currdata.name = [n x];
            currdata = loadfunc(currsrc);
            currdata.src = currsrc;
            out = cat(2, out, currdata);
        end
        fprintf('Done\n');
    otherwise
        return
end

for dataidx = 1:numel(out)
    out(dataidx).getraw = str2func(sprintf('@()%s(''%s'')', func2str(loadfunc), out(dataidx).src));
    out(dataidx) = pupl_check(out(dataidx));
end

end