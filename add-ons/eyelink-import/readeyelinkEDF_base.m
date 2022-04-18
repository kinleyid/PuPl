
function EYE = readeyelinkEDF_base(fullpath)

% Read eyelink EDF files into Octave

EYE = [];

% Signal codes:
START = 15;
MSG = 24;
nINPUT = 25; % button
xINPUT = 28; % exogenous input
LONG_SAMPLE = nan; % sample including timestamp
SHORT_SAMPLE = nan; % sample not including timestamp

fid = fopen(fullpath, 'rb');
%% Read header
header = '';
stopsig = 'ENDP:';
b = repmat(' ', 1, numel(stopsig)); % Buffer
while ~strcmp(b, stopsig)
    c = fread(fid, 1, '*char'); % Current char
    b = [b(2:end) c];
    header(end + 1) = c;
end 
fseek(fid, 1, 'cof'); % I think this is usually a newline character and then 0

% Check to see if the file is zipped--I don't know how to parse these
eol = find(header == sprintf('\n'), 1) - 1;
first_line = header(1:eol);
if ~isempty(regexp(first_line, 'ZIP'))
    fprintf('The first line of this file contains the word "ZIP".\n');
    fprintf('Currently, PuPl cannot read files like this natively.');
    fclose(fid);
    return
end

%% Read data
curr_lat = 1;
data = {};
sample_times = {};
event_types = {};
event_times = {}; % Event latencies
bindat = fread(fid, inf, '*uint8'); % Binary data
fclose(fid);
ndat = numel(bindat);
idx = 1;
last_pct_done = 0;
fprintf('Parsing binary...')
fprintf('%3d%%', 0);
while true
    % The first 2 bytes jointly determine what follows them
    ctrl1 = bindat(idx);
    ctrl2 = bindat(idx + 1);
    idx = idx + 2;
    curr_pct_done = round(100*idx/ndat);
    if curr_pct_done > last_pct_done
        last_pct_done = curr_pct_done;
        fprintf('\b\b\b\b');
        fprintf('%3d%%', curr_pct_done);
    end
    switch ctrl1
        case MSG % Overrides ctrl2
            event_times{end + 1} = typecast(bindat(idx + 4:-1:idx + 1), 'uint32');
            msg_len = double(bindat(idx+7));
            event_types{end + 1} = char(bindat(idx + 8:idx + 7 + msg_len))';
            idx = idx + 9 + msg_len;
        case {nINPUT xINPUT}
            % Some kind of input to the eyelink system
            idx = idx + 9;
        otherwise
            switch ctrl2
                case 192
                    idx = idx + 1;
                    switch ctrl1
                        case {18 66 130} % END?
                            % These signals seem to signal the end of the
                            % recording
                            n_skip = 5;
                            if skip_3
                                % 3 extra bytes will NOT be skipped. Thus
                                % we need to acocunt for them here
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
                        case {73 137} % Fixation update
                            n_skip = 71; % Never, strictly speaking, got this to work
                        otherwise
                            x = 10;
                    end
                    if skip_3
                        n_skip = n_skip + 3;
                    end
                    idx = idx + n_skip;
                otherwise
                    switch ctrl1
                        case START
                            % This sequence contains information about the
                            % recording settings
                            
                            % The first (i.e., most recent, i.e., last)
                            % timestamp:
                            last_t = typecast(bindat(idx+4:-1:idx+1), 'uint32'); % t1 = fread(fid, 1, 'uint32', 0, 'b'); % timestamp
                            % Sample rate:
                            srate = uint32(typecast(bindat(idx+7:-1:idx+6), 'uint16'));
                            % Scale factor (raw values are multiplied by
                            % this amount to match the output of edf2asc:
                            sfac = bindat(idx+12);
                            % Indicator of pupil size measurement
                            pupil_indic = bindat(idx+26);
                            switch pupil_indic
                                case 1
                                    pupil_size = 'area';
                                case 128
                                    pupil_size = 'diameter';
                                otherwise
                                    error('unrecognized pupil size indicator')
                            end
                            % Indicator of the type of data being recorded
                            data_indic = regexprep(sprintf('%8s', dec2bin(bindat(idx + 31))), ' ', '0') - '0';
                            % Ocularity is encoded in the first 2 bits
                            eyes_indic = data_indic(1:2);
                            % There are 2 sequences that indicate the next
                            % record is a sample:
                            LONG_SAMPLE = bin2dec(num2str(data_indic)); % If timestamp included
                            SHORT_SAMPLE = LONG_SAMPLE - 32; % If timestamp not included
                            % This next byte seems to indicate how much
                            % other (i.e., non-gaze, non-pupil) data is
                            % recorded. This code skips over it
                            skip_indic = regexprep(sprintf('%8s', dec2bin(bindat(idx + 32))), ' ', '0') - '0';
                            % How many bytes to skip before the data of
                            % interest in a sample
                            pre_skip = 4 * sum(data_indic(4:5)) * sum(eyes_indic);
                            % How many to skip after
                            % post_skip = 17 * skip_indic(4) + sum(skip_indic(1:3) * 2);
                            switch bindat(idx + 32)
                                case uint8(240)
                                    post_skip = 23;
                                case uint8(128)
                                    post_skip = 2;
                                case uint8(208)
                                    post_skip = 21;
                                case uint8(224)
                                    post_skip = 6;
                                case uint8(192)
                                    post_skip = 4;
                                case uint8(144)
                                    post_skip = 15;
                                otherwise
                                    error('unrecognized post_skip indicator')
                            end
                            % The length of the data of interest in a
                            % sample
                            data_len = 3 * sum(eyes_indic) + 2;
                            % The indices of the data of interest depend on
                            % the ocularity
                            eyes = 'LR';
                            eyes = eyes(logical(eyes_indic));
                            switch eyes
                                case {'L' 'R'}
                                    data_idx = [1 2 5];
                                case 'LR'
                                    data_idx = [1 2 7 3 4 8];
                                otherwise
                                    error('Unrecognized ocularity signifier')
                            end
                            % The next byte possibly contains information
                            % about which eye events (saccades, fixations)
                            % are recorded
                            eye_ev_indic = regexprep(sprintf('%8s', dec2bin(bindat(idx + 47))), ' ', '0') - '0';
                            % the 4th bit of byte 67 appears to tell us
                            % whether 3 more bits than the usual amount
                            % should be skipped after eye events
                            skip_3_indic = regexprep(sprintf('%8s', dec2bin(bindat(idx + 67))), ' ', '0') - '0';
                            skip_3 = logical(skip_3_indic(4));
                            % I think the next byte tells you whether the
                            % eyelink system starts recording in response
                            % to some kind of input? In practical terms it
                            % tells us whether the start sequence will be
                            % longer than expected
                            input_indic = bindat(idx + 48);
                            switch input_indic
                                case 96
                                    read_input = true;
                                case 64
                                    read_input = false;
                                otherwise
                                    error('unrecognized input indicator')
                            end
                            % The bytes between 49 and 84 clearly contain
                            % some kind of information, but none that I've
                            % found useful. Maybe serial number or
                            % something like that.
                            idx = idx + 85;
                            while true
                                indic = bindat(idx);
                                if indic == 0 % Read some more
                                    idx = idx + 8;
                                else
                                    idx = idx + 1;
                                    break
                                end
                                % I have no idea if we would ever need to run through this while loop
                                % again, but for now this code structure works with the 2 test cases
                            end
                            idx = idx + 3;
                            if read_input
                                idx = idx + 11;
                            end
                            sp = 1000 / srate; % sample period
                            curr_scount = 0; % current sample count
                            last_scount = 0; % most recent (i.e., last) sample count
                        case {SHORT_SAMPLE LONG_SAMPLE}
                            if ctrl1 == LONG_SAMPLE
                                t = typecast(bindat(idx+3:-1:idx), 'uint32');
                                idx = idx + 4;
                                expected = srate*(t - last_t)/1000;
                                actual = (curr_scount - last_scount);
                                n_missing = expected - actual;
                                if n_missing ~= 0 
                                    x = 10;
                                    fprintf('!Missing %d samples\n', n_missing);
                                    % data(end-(actual-1):end) = []; % assume the whole block is a write-off
                                    % data = [data repmat(missing_data, 1, expected)];
                                end
                                last_t = t;
                                last_scount = curr_scount;
                            else
                                t = t + sp;
                                idx = idx + 1;
                            end
                            sample_times{end + 1} = t;
                            % Skip to the data of interest
                            idx = idx + pre_skip;
                            % Read the data of interest
                            data{end + 1} = typecast(bindat(idx+data_len*2-1:-1:idx), 'uint16');
                            curr_scount = curr_scount + 1;
                            curr_lat = curr_lat + 1;
                            % Skip past the rest of the current record
                            idx = idx + data_len*2 + post_skip;
                        case 16
                            idx = idx + 6; % I suppose I never really figured out what this was...
                        case 0
                            % End of file
                            break
                        otherwise
                            x = 10;
                    end
            end
    end
end
fprintf(' ');
%% Process timestamps

srate = double(srate);
EYE.srate = srate;
sample_times = double([sample_times{:}]);
event_times = double([event_times{:}]);

[sample_times, event_times] = processtimestamps(sample_times, event_times, srate);
EYE.times = sample_times/1000;

%% Get events

event_types = cellfun(@(x) regexprep(x, sprintf('\n'), ' '), event_types, 'UniformOutput', false);
event_types = cellfun(@(x) regexprep(x, char(0), ''), event_types, 'UniformOutput', false);
EYE.event = struct(...
    'name', event_types,...
    'time', num2cell(event_times/1000));

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

sfac = double(sfac);
if neyes == 1
    fields = {
        {'gaze' 'x' whicheye}
        {'gaze' 'y' whicheye}
        {'pupil' whicheye}
    };
    f = [
        1/sfac
        1/sfac
        1
    ];
else
    fields = {
        {'gaze' 'x' 'left'}
        {'gaze' 'y' 'left'}
        {'pupil' 'left'}
        {'gaze' 'x' 'right'}
        {'gaze' 'y' 'right'}
        {'pupil' 'right'}
    };
    f = [
        1/sfac
        1/sfac
        1
        1/sfac
        1/sfac
        1
    ];
end
% Assign samples
data = double(fliplr([data{:}]'));
data = data(:, data_idx);
for ii = 1:numel(fields)
    EYE = setfield(EYE, fields{ii}{:}, data(:, ii) * f(ii));
end

EYE.units.pupil = {pupil_size 'arbitrary units' 'absolute'};
EYE.units.gaze = [];
EYE.units.gaze.x = {'x' 'px' 'from screen left'};
EYE.units.gaze.y = {'y' 'px' 'from screen top'};

end
