
function pupl_history(varargin)

global eyeData

if isempty(eyeData)
    fprintf('Global eyeData struct is empty, cannot read processing history\n');
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
    fid = fopen(fullpath, 'wt');
else
    fid = 1;
end

fprintf(fid, '%% Command history:\n\n');

if numel(eyeData) > 1
    if ~isequal(eyeData.history)
        fprintf(fid, 'Not all datasets have the same processing history\n');
        for idx = 1:numel(eyeData)
            fprintf(fid, '\n\%\t%s:\n\n', eyeData(idx).name);
            fprintf(fid, '%s;\n', eyeData(idx).history{:});
        end
    else
        fprintf(fid, '%s;\n', eyeData(1).history{:});
    end
else
    fprintf(fid, '%s;\n', eyeData.history{:});
end

if fid ~= 1
    fclose(fid);
    fprintf('done\n');
end

end