
function EYE = readeyelinkEDF_mex(fullpath)

% Based on www.sr-support.com/attachment.php?aid=302

EYE = [];

edf = edfmex(fullpath);
fprintf('...');

% Get times
EYE.times = double(edf.FSAMPLE.time)/1000;
% Get srate
EYE.srate = double(edf.RECORDINGS(1).sample_rate);
% Get data
fields = {
    {'gaze' 'x'} {'gx'}
    {'gaze' 'y'} {'gy'}
    {'pupil'} {'pa'}
};
% Get ocularity
sides = {'left' 'right'};
side_indic = double(unique([edf.RECORDINGS.eye]));
if numel(side_indic) == 1
    if side_indic ~= 3
        sides = sides(side_indic); % 1 = left; 2 = right
    end
end
for fi = 1:size(fields, 1)
    for si = 1:numel(sides)
        % Check if eye present
        EYE = setfield(EYE, fields{fi, 1}{:}, sides{si},...
            edf.FSAMPLE.(fields{fi, 2}{:})(si, :));
    end
end
% Get sample rate
EYE.srate = double(edf.RECORDINGS(1).sample_rate);
% Get units
switch double(edf.RECORDINGS(1).pupil_type)
    case 0
        pupil_type = 'area';
    case 1
        pupil_type = 'diameter';
end
EYE.units.pupil = {pupil_type 'arbitrary units' 'absolute'};
EYE.units.gaze = [];
EYE.units.gaze.x = {'x' 'px' 'from screen left'};
EYE.units.gaze.y = {'y' 'px' 'from screen top'};

% Get events
msg_idx = arrayfun(@(s)~isempty(s.message), edf.FEVENT);
msg = edf.FEVENT(msg_idx);
EYE.event = struct(...
    'time', num2cell(double([msg.sttime])/1000),...
    'name', {msg.message}...
);