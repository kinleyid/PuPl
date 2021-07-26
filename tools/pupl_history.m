
function pupl_history(varargin)

global pupl_globals
datavar = evalin('base', pupl_globals.datavarname);

if isempty(datavar)
    fprintf('Global data variable %s is empty, cannot read processing history\n', pupl_globals.datavarname);
    return
end

if numel(varargin) > 0 % Save to script file
    if strcmp(varargin{1}, 'wt') % Manually select 
        [f, p] = uiputfile('*.m', 'Save pipeline script');
        if f == 0
            return
        else
            fullpath = sprintf('%s', p, f);
        end
    else
        fullpath = [varargin{:}];
    end
    fprintf('Saving processing history to %s...', fullpath);
    fid = fopen(fullpath, 'w');
else
    fid = 1;
end

fprintf(fid, '%% Command history:\n\n');

if numel(datavar) > 1
    if ~isequal(datavar.history)
        fprintf(fid, 'Not all datasets have the same processing history\n');
        for idx = 1:numel(datavar)
            fprintf(fid, '\n\t%s:\n\n', datavar(idx).name);
            fprintf(fid, '%s\n', datavar(idx).history{:});
        end
    else
        fprintf(fid, '%s\n', datavar(1).history{:});
    end
else
    fprintf(fid, '%s\n', datavar.history{:});
end

if fid ~= 1
    fclose(fid);
    fprintf('done\n');
end

end