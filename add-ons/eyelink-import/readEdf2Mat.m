
function EYE = readEdf2Mat(fullpath)

EYE = [];

% Convert the output of Edf2Mat to PuPl's structure format

st = load(fullpath);

% Find variable in .mat file that is the Edf2Mat structure
data_fns = {};
for fn = reshape(fieldnames(st), 1, [])
    if strcmp(class(st.(fn{:})), 'Edf2Mat')
        data_fns{end + 1} = fn{:};
    end
end

if isempty(data_fns)
    fprintf('No variable saved in %s was of class "Edf2Mat"\n', fullpath);
else
    data_fn = data_fns{1};
    if numel(data_fns) > 1
        fprintf('Multiple "Edf2Mat" variables found:\n');
        for dfn = data_fns
            fprintf(' - %s\n', dfn{:});
        end
        fprintf('Each Edf2Mat variable must be saved in a different .mat file\n');
        fprintf('Using %s\n', data_fn)
    end
    data = st.(data_fn);
    % Get times
    EYE.times = data.Samples.time/1000;
    % Get srate
    EYE.srate = data.RawEdf.RECORDINGS(1).sample_rate;
    % Get data
    fields = {
        {'gaze' 'x'} {'gx'}
        {'gaze' 'y'} {'gy'}
        {'pupil'} {'pa'}
    };
    sides = {'left' 'right'};
    for fi = 1:size(fields, 1)
        for si = 1:numel(sides)
            % Check if eye present
            if ~all(data.Samples.(fields{fi, 2}{:})(:, si) == data.MISSING_DATA_VALUE)
                EYE = setfield(EYE, fields{fi, 1}{:}, sides{si}, data.Samples.(fields{fi, 2}{:})(:, si));
            end
        end
    end
    % Units
    EYE.units.pupil = {data.Events.pupilInfo{1} 'arbitrary units' 'absolute'};
    EYE.units.gaze = [];
    EYE.units.gaze.x = {'x' 'px' 'from screen left'};
    EYE.units.gaze.y = {'y' 'px' 'from screen top'};
    % Get events
    msg = data.Events.Messages;
    EYE.event = struct(...
        'name', msg.info,...
        'time', num2cell(msg.time/1000));
end

end