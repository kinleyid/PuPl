
function pupl_history(varargin)

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
    fid = fopen(fullpath, 'wt');
else
    fid = 1;
end

global eyeData

fprintf(fid, '%% Command history:\n\n');

if numel(eyeData) > 1
    if ~isequal(eyeData.history)
        fprintf(fid, 'Not all datasets have the same processing history\n');
        for idx = 1:numel(eyeData)
            fprintf(fid, '\n\%\t%s:\n\n', eyeData(idx).name);
            cellfun(@(x) fprintf(fid, '%s;\n', x), eyeData(idx).history);
        end
    else
        cellfun(@(x) fprintf(fid, '%s\n', x), eyeData(1).history);
    end
else
    cellfun(@(x) fprintf(fid, '%s\n', x), eyeData.history);
end

if fid ~= 1
    fclose(fid);
end

end