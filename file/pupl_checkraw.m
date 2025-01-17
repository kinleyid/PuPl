
function data = pupl_checkraw(data, varargin)

% Checks raw data to ensure compliance with pupl's expectations

args = pupl_args2struct(varargin, {
    'src' ''
    'type' 'eye'
});

if isfield(data, 'event')
    data.event = data.event(:)';
    for ii = 1:numel(data.event)
        if ~ischar(data.event(ii).name)
            data.event(ii).name = num2str(data.event(ii).name);
        end
    end
end

if isfield(data, 'pupil')
    ur = [];
    for f = {'pupil' 'gaze' 'times' 'srate'}
        ur.(f{:}) = data.(f{:});
    end
    % Check if the original data has separate left and right eye streams
    % for gaze coordinates--if not, assume both eyes are looking at the
    % same place
    for gaze_coord = {'x' 'y'}
        coord_data = getfield(ur, 'gaze', gaze_coord{:});
        if ~isstruct(coord_data)
            ur = setfield(ur, 'gaze', gaze_coord{:}, []);
            for side = {'left' 'right'}
                ur = setfield(ur, 'gaze', gaze_coord{:}, side{:}, coord_data);
            end
        end
    end
    data.ur = ur;
    % Assign unique ID's to events
    if isfield(data, 'event')
        if numel(data.event) > 0
            uniqid = num2cell(1:numel(data.event));
            [data.event.uniqid] = uniqid{:};
        end
    end

    % Check units
    def_pupil = {'size' 'unknown units' 'assumed absolute'};
    def_gaze = {'unknown units' 'unknown relative position'};
    if ~isfield(data, 'units')
        data.units = [];
    end
    if ~isfield(data.units, 'pupil')
        data.units.pupil = def_pupil;
    end
    if ~isfield(data.units, 'gaze')
        data.units.gaze = [];
    end
    for axis = {'x' 'y'}
        if ~isfield(data.units.gaze, axis{:})
            data.units.gaze.(axis{:}) = [axis def_gaze];
        end
    end
end

data.src = args.src;
[~, n] = fileparts(data.src);
data.name = n;
if strcmp(args.type, 'eye')

    % Handle monocular recordings

    sides = {'left' 'right'};
    fields = {
        {'ur' 'pupil'}
        {'ur' 'gaze' 'x'}
        {'ur' 'gaze' 'y'}
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
