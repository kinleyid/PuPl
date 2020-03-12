function EYE = readeyelinkEDF_old(fullpath)

EYE = [];

% Signal codes:
START = 15;
MSG = 24;
nINPUT = 25;
xINPUT = 28;

fclose('all');
folder = fullfile('C:', 'Users', 'isaac', 'Projects', 'PuPl', 'data', 'eyelink');
file = 'cS1_b1';
fprintf('\n\nfile: %s\n\n', file);
fullpath = fullfile(folder, sprintf('%s.edf', file));

fid = fopen(fullpath, 'rb');
fseek(fid, 0, 'eof');
filesize = ftell(fid);
fseek(fid, 0, 'bof');

%% Read header
header = '';
stopsig = 'ENDP:';
b = repmat(' ', 1, numel(stopsig)); % Buffer
while ~strcmp(b, stopsig)
    c = fread(fid, 1, '*char'); % Current char
    b = [b(2:end) c];
    header(end + 1) = c;
end 
eoh = ftell(fid); % End of header
fseek(fid, 1, 'cof'); % I think this is usually a newline character and then 0

%% Read data
curr_lat = 1;
data = {};
data_times = {};
event_types = {};
event_lats = {}; % Event latencies
fprintf('%06.2f', 0);
while true
    % The first 2 bytes jointly determine what follows them
    ctrl1 = fread(fid, 1, 'uint8', 0, 'b');
    ctrl2 = fread(fid, 1, 'uint8', 0, 'b');
    fprintf('\b\b\b\b\b\b\b');
    fprintf('%06.2f%%', 100*ftell(fid)/filesize);
    switch ctrl1
        % The following 
        case MSG % Overrides ctrl2
            event_types{end + 1} = parse_msg(fid);
            event_lats{end + 1} = curr_lat;
        case {nINPUT xINPUT}
            parse_input(fid);
        otherwise
            switch ctrl2
                case 192
                    ctrl3 = fread(fid, 1, 'uint8', 0, 'b');
                    switch ctrl1
                        case 18 % True END?
                            n_skip = 5;
                            if skip_3
                                n_skip = n_skip - 3; % Inelegant but preserves the present code structure
                            end
                        case {66 130} % ENDish?
                            n_skip = 5;
                            if skip_3
                                n_skip = n_skip - 3; % Inelegant but preserves the present code structure
                            end
                        case {67 131} % SBLINK
                            n_skip = 5;
                        case {68 132} % EBLINK
                            n_skip = 10;
                        case {69 133} % SSACC
                            n_skip = 23;
                        case {70 134} % ESACC
                            n_skip = 52;
                        case {71 135} % SFIX
                            n_skip = 26;
                        case {72 136} % EFIX
                            n_skip = 71;
                        case {73 137} % microsaccade?
                            n_skip = 71; % Never, strictly speaking, got this to work
                        otherwise
                            x = 10;
                    end
                    if skip_3
                        n_skip = n_skip + 3;
                    end
                    fseek(fid, n_skip, 'cof');
                otherwise
                    switch ctrl1
                        case START
                            [LONG_SAMPLE, SHORT_SAMPLE, pre_skip, data_len, post_skip, srate, sfacvec, last_t, pupil_size, eyes, data_idx, skip_3] = parse_start(fid);
                            sp = 1000 / srate;
                            curr_scount = 0;
                            last_scount = 0;
                        case {SHORT_SAMPLE LONG_SAMPLE}
                            if ctrl1 == LONG_SAMPLE
                                t = fread(fid, 1, 'uint32', 0, 'b');
                                expected = srate*(t - last_t)/1000;
                                actual = (curr_scount - last_scount);
                                n_missing = expected - actual;
                                if n_missing ~= 0 
                                    x = 10;
                                    fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Missing %d\n', n_missing);
                                    % data(end-(actual-1):end) = []; % assume the whole block is a write-off
                                    % data = [data repmat(missing_data, 1, expected)];
                                end
                                last_t = t;
                                last_scount = curr_scount;
                            else
                                t = t + sp;
                                fseek(fid, 1, 'cof');
                            end
                            data_times{end + 1} = t;
                            fseek(fid, pre_skip, 'cof');
                            curr_scount = curr_scount + 1;
                            data{end + 1} = fread(fid, data_len, 'uint16', 0, 'b');
                            curr_lat = curr_lat + 1;
                            fseek(fid, post_skip, 'cof');
                        case 16
                            fseek(fid, 6, 'cof');
                        case 0
                            % End of file
                            break
                        otherwise
                            x = 10;
                    end
            end
    end
end
fclose(fid);

%% Process timestamps

EYE.srate = srate;
% Cut inter-trial gaps
t = [data_times{:}];
gaps = find(diff(t) > sp);
for gap_start = gaps
    next_t_x = t(gap_start) + sp; % Expected
    next_t_a = t(gap_start + 1); % Actual
    t(gap_start + 1:end) = t(gap_start + 1:end) - (next_t_x - next_t_a);
end

%% Get events

event_times = t([event_lats{:}]);

EYE.event = struct(...
    'type', event_types,...
    'time', num2cell(event_times),...
    'latency', event_lats,...
    'rt', repmat({NaN}, size(event_lats)));

%% Get data

switch eyes
    case 'L'
        neyes = 1;
        whicheye = 'left';
    case 'R'
        neyes = 1;
        whicheye = 'right';
    case 'LR'
        neyes = 2;
end

if neyes == 1
    fields = {
        {'urgaze' 'x' whicheye}
        {'urgaze' 'y' whicheye}
        {'urdiam' whicheye}
    };
else
    fields = {
        {'urgaze' 'x' 'left'}
        {'urgaze' 'y' 'left'}
        {'urpupil' 'left'}
        {'urgaze' 'x' 'right'}
        {'urgaze' 'y' 'right'}
        {'urpupil' 'right'}
    };
end
% Assign samples
data = [data{:}]';
data = data(:, data_idx);
for ii = 1:numel(fields)
    EYE = setfield(EYE, fields{ii}{:}, data(:, ii));
end

end

%% Utility functions

function bytes = read_bytes(fid, n, varargin)

if n > 0
    bytes = num2cell(fread(fid, n, 'uint8', varargin{:}));
    bytes = cellfun(@dec2bin, bytes, 'UniformOutput', false);
    bytes = cellfun(@(x) sprintf('%8s', x), bytes, 'UniformOutput', false);
    bytes = cellfun(@(x) regexprep(x, ' ', '0'), bytes, 'UniformOutput', false);
    bytes = sprintf('%s ', bytes{:});
    bytes(end) = [];
else
    bytes = '';
end

end

function [msg, timestamp] = parse_msg(fid)

% Assumes we're starting from right after the bit MSG byte
fseek(fid, 1, 'cof');
timestamp = fread(fid, 1, 'uint32', 0, 'b');
fseek(fid, 2, 'cof'); % Skip 2 more bytes
len = fread(fid, 1, 'uint8'); % Length of msg
msg = fread(fid, len, '*char')';
fseek(fid, 1, 'cof');

end

function [str_start, str_end] = find_str(fid, str)

% Find string str in file fid
buff = repmat(' ', 1, numel(str)); % Buffer

% Update buffer until it contains str:
while ~strcmp(buff, str)
    c = fread(fid, 1, '*char'); % Current char
    buff = [buff(2:end) c];
end

str_end = ftell(fid);
str_start = str_end - numel(str);

end

function [msg, t, msg_start] = find_msg(fid, msg)

msg_start = find_str(fid, msg) - 10;
fseek(fid, msg_start, 'bof'); % Go to the beginning of the 32-bit control sequence
ctrl = fread(fid, 1, 'uint8', 0, 'b'); % Ctrl seq
if ctrl == 24
    [msg, t] = parse_msg(fid);
else
    error('not a msg');
end

end

function n_bytes = find_bytes(fid, bytes)

n_bytes = 1;
while true
    curr_byte = fread(fid, 1, 'uint8', 0, 'b');
    if ismember(curr_byte, bytes)
        break
    else
        n_bytes = n_bytes + 1;
    end
end

end

function [long_sample, short_sample, pre_skip, data_len, post_skip, srate, sfacvec, t1, pupil_size, eyes, data_idx, skip_3] = parse_start(fid)

fseek(fid, 1, 'cof');

t1 = fread(fid, 1, 'uint32', 0, 'b'); % timestamp
fseek(fid, 1, 'cof');
srate = fread(fid, 1, 'uint16', 0, 'b');
fseek(fid, 4, 'cof');
sfac = fread(fid, 1, 'uint8', 0, 'b');
fseek(fid, 13, 'cof');
pupil_indic = read_bytes(fid, 1, 0, 'b');
switch pupil_indic
    case '00000001'
        pupil_size = 'area';
    case '10000000'
        pupil_size = 'diameter';
    otherwise
%        error('unrecognized pupil size indicator')
end
fseek(fid, 4, 'cof');
data_indic = read_bytes(fid, 1, 0, 'b') - '0'; % Indicates what data will be present, as well as what byte will precede samples
left_eye = data_indic(1);
right_eye = data_indic(2);
%{
is_pupil = logical(data_indic(4));
is_href = logical(data_indic(5));
%}
% We're assuming gaze x and y and pupil are present
long_sample = bin2dec(num2str(data_indic));
short_sample = long_sample - 32;

skip_indic = read_bytes(fid, 1, 0, 'b') - '0'; % Indicates how many bytes to skip before and after the data
pre_skip = 4 * sum(data_indic(4:5)) * (left_eye + right_eye);
post_skip = 17 * skip_indic(4) + sum(skip_indic(1:3) * 2); 
data_len = 3 * (left_eye + right_eye) + 2;

fseek(fid, 4, 'cof');
t1 = fread(fid, 1, 'uint32', 0, 'b'); % timestamp
fseek(fid, 1, 'cof');
srate = fread(fid, 1, 'uint16', 0, 'b'); 
fseek(fid, 2, 'cof');
fseek(fid, 1, 'cof');
eyes_indic = read_bytes(fid, 1, 0, 'b')' - '0';
eyes = 'LR';
eyes = eyes(logical(eyes_indic(1:2)));
switch eyes
    case {'L' 'R'}
        data_idx = [1 2 5];
        sfacvec = [1/sfac 1/sfac 1];
    case 'LR'
        data_idx = [1 2 7 3 4 8];
        sfacvec = [1/sfac 1/sfac 1 1/sfac 1/sfac 1];
    otherwise
        error('Unrecognized ocularity signifier')
end

if skip_indic(3)
    skip_3 = true;
else
    skip_3 = false;
end

input_indic = read_bytes(fid, 1, 0, 'b');
read_input = false;
switch input_indic
    case '01100000'
        read_input = true;
    case '01000000'
        read_input = false;
    otherwise
%        error('unrecognized input indicator')
end
fseek(fid, 2, 'cof');
sfac = fread(fid, 1, 'uint8', 0, 'b');
fseek(fid, 10, 'cof');
pupil_indic = read_bytes(fid, 1, 0, 'b');
switch pupil_indic
    case '00000001'
        pupil_size = 'area';
    case '10000000'
        pupil_size = 'diameter';
    otherwise
%        error('unrecognized pupil size indicator')
end
fseek(fid, 7, 'cof');
fseek(fid, 3, 'cof');
t1 = fread(fid, 1, 'uint32', 0, 'b'); % bytes 73-76, timestamp
fseek(fid, 4, 'cof'); % bytes 77-80, unknown
t1 = fread(fid, 1, 'uint32', 0, 'b'); % bytes 81-84, timestamp
while true
    indic = fread(fid, 1, 'uint8', 0, 'b'); % byte 85
    if indic == 0 % Read some more
        fseek(fid, 3, 'cof'); % unsure what this is 
        fread(fid, 1, 'uint32', 0, 'b'); % timestamp
    else
        break
    end
    % I have no idea if we would ever need to run through this while loop
    % again, but for now this code structure works with the 2 test cases
end
fseek(fid, 3, 'cof'); % Should be all zeros
% If there's no input, the first sample comes next

% If there was, there's more to read:
if read_input
    fseek(fid, 3, 'cof');
    input_time = fread(fid, 1, 'uint32', 0, 'b');
    fseek(fid, 2, 'cof'); % all zeros
    input_type = fread(fid, 1, 'uint8', 0, 'b');
    fseek(fid, 1, 'cof');
    % Now comes the first sample
end

end

function [input_type, timestamp] = parse_input(fid)

fseek(fid, 1, 'cof');
timestamp = fread(fid, 1, 'uint32', 0, 'b');
fseek(fid, 2, 'cof');
input_type = fread(fid, 1, 'uint8', 0, 'b');
fseek(fid, 1, 'cof');

end