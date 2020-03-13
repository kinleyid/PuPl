
function data = pupl_checkraw(data, varargin)

% Checks raw data to ensure compliance with pupl's expectations

args = pupl_args2struct(varargin, {
    'src' ''
    'type' 'eye'
});

data.src = args.src;
[~, n] = fileparts(data.src);
data.name = n;
if strcmp(args.type, 'eye')
    
    % Handle monocular recordings
    
    sides = {'left' 'right'};
    fields = {
        {'urpupil'}
        {'urgaze' 'x'}
        {'urgaze' 'y'}
    };
    for ii1 = 1:numel(sides)
        otherside = sides{~strcmp(sides, sides{ii1})};
        for ii2 = 1:numel(fields)
            if ~isnonemptyfield(data, fields{ii2}{:}, sides{ii1})
                data = setfield(data, fields{ii2}{:}, sides{ii1}, getfield(data, fields{ii2}{:}, otherside));
            end
        end
    end
    
    % Reshape data fields to 1 x n
    
    for ii1 = 1:numel(sides)
        for ii2 = 1:numel(fields)
            data = setfield(data, fields{ii2}{:}, sides{ii1},...
                reshape(getfield(data, fields{ii2}{:}, sides{ii1}), 1, []));
        end
    end
    
    for field = {'gaze' 'pupil'}
        data.(field{:}) = getfromur(data, field{:});
    end
    data = pupl_check(data);
    
else
    data.event = data.event(:);
end

end