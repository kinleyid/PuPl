
function out = loader(rawindicator, type, loadfunc, fullpath, varargin)

% This deals with low-level structural stuff all in one place

out = loadfunc(fullpath, varargin{:});
[~, n] = fileparts(fullpath);
out.name = n;
if strcmp(rawindicator, 'raw')
    out.src = fullpath;
    if strcmp(type, 'eye')
        % Fix monocular recordings
        sides = {'left' 'right'};
        fields = {
            {'urdiam'}
            {'urgaze' 'x'}
            {'urgaze' 'y'}
        };
        for ii1 = 1:numel(sides)
            otherside = sides{~strcmp(sides, sides{ii1})};
            for ii2 = 1:numel(fields)
                if ~isnonemptyfield(out, fields{ii2}{:}, sides{ii1})
                    out = setfield(out, fields{ii2}{:}, sides{ii1}, getfield(out, fields{ii2}{:}, otherside));
                end
            end
        end
        % Reshape data fields to 1 x n
        for ii1 = 1:numel(sides)
            for ii2 = 1:numel(fields)
                out = setfield(out, fields{ii2}{:}, sides{ii1},...
                    reshape(getfield(out, fields{ii2}{:}, sides{ii1}), 1, []));
            end
        end
        out = pupl_check(out);
        for field = {'gaze' 'diam'}
            out.(field{:}) = getfromur(out, field{:});
        end
    else
        out.event = out.event(:);
    end
end

end