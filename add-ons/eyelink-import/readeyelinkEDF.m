function EYE = readeyelinkEDF(fullpath)

EYE = [];

% Signal codes:
START = 15;
MSG = 24;
nINPUT = 25;
xINPUT = 28;

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
sample_times = {};
event_types = {};
event_times = {}; % Event latencies
bindat = fread(fid, inf, '*uint8', 0, 'b'); % Binary data
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
        % The following 
        case MSG % Overrides ctrl2
            event_times{end + 1} = typecast(bindat(idx + 4:-1:idx + 1), 'uint32');
            len = double(bindat(idx+7));
            event_types{end + 1} = char(bindat(idx + 8:idx + 7 + len))';
            idx = idx + 9 + len;
        case {nINPUT xINPUT}
            idx = idx + 9;
        otherwise
            switch ctrl2
                case 192
                    idx = idx + 1;
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
                    idx = idx + n_skip;
                otherwise
                    switch ctrl1
                        case START
                            last_t = typecast(bindat(idx+4:-1:idx+1), 'uint32'); % t1 = fread(fid, 1, 'uint32', 0, 'b'); % timestamp
                            srate = uint32(typecast(bindat(idx+7:-1:idx+6), 'uint16'));
                            sfac = bindat(idx+12);
                            pupil_indic = bindat(idx+26);
                            switch pupil_indic
                                case 1
                                    pupil_size = 'area';
                                case 128
                                    pupil_size = 'diameter';
                                otherwise
                                    error('unrecognized pupil size indicator')
                            end
                            data_indic = regexprep(sprintf('%8s', dec2bin(bindat(idx + 31))), ' ', '0') - '0';
                            left_eye = data_indic(1);
                            right_eye = data_indic(2);
                            LONG_SAMPLE = bin2dec(num2str(data_indic));
                            SHORT_SAMPLE = LONG_SAMPLE - 32;

                            skip_indic = regexprep(sprintf('%8s', dec2bin(bindat(idx + 32))), ' ', '0') - '0';
                            pre_skip = 4 * sum(data_indic(4:5)) * (left_eye + right_eye);
                            post_skip = 17 * skip_indic(4) + sum(skip_indic(1:3) * 2); 
                            data_len = 3 * (left_eye + right_eye) + 2;

                            eyes_indic = regexprep(sprintf('%8s', dec2bin(bindat(idx + 47))), ' ', '0') - '0';
                            eyes = 'LR';
                            eyes = eyes(logical(eyes_indic(1:2)));
                            switch eyes
                                case {'L' 'R'}
                                    data_idx = [1 2 5];
                                case 'LR'
                                    data_idx = [1 2 7 3 4 8];
                                otherwise
                                    error('Unrecognized ocularity signifier')
                            end

                            if skip_indic(3)
                                skip_3 = true;
                            else
                                skip_3 = false;
                            end

                            input_indic = bindat(idx + 48);
                            switch input_indic
                                case 96
                                    read_input = true;
                                case 64
                                    read_input = false;
                                otherwise
                                    error('unrecognized input indicator')
                            end
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
                            
                            
                            
                            sp = 1000 / srate;
                            curr_scount = 0;
                            last_scount = 0;
                        case {SHORT_SAMPLE LONG_SAMPLE}
                            if ctrl1 == LONG_SAMPLE
                                t = typecast(bindat(idx+3:-1:idx), 'uint32');
                                idx = idx + 4;
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
                                idx = idx + 1;
                            end
                            sample_times{end + 1} = t;
                            idx = idx + pre_skip;
                            curr_scount = curr_scount + 1;
                            data{end + 1} = typecast(bindat(idx+data_len*2-1:-1:idx), 'uint16');
                            curr_lat = curr_lat + 1;
                            idx = idx + data_len*2 + post_skip;
                        case 16
                            idx = idx + 6;
                        case 0
                            % End of file
                            break
                        otherwise
                            x = 10;
                    end
            end
    end
end

%% Process timestamps

srate = double(srate);
EYE.srate = srate;
sample_times = double([sample_times{:}]);
EYE.t1 = sample_times(1);
event_times = double([event_times{:}]);
[~, event_times, event_lats] = processtimestamps(sample_times, event_times, srate);

%% Get events

EYE.event = struct(...
    'type', cellfun(@strtrim, event_types, 'UniformOutput', false),...
    'time', num2cell(event_times/1000),...
    'latency', num2cell(event_lats),...
    'rt', repmat({NaN}, size(event_times)));

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
        {'urgaze' 'x' whicheye}
        {'urgaze' 'y' whicheye}
        {'urpupil' whicheye}
    };
    f = [
        1/sfac
        1/sfac
        1
    ];
else
    fields = {
        {'urgaze' 'x' 'left'}
        {'urgaze' 'y' 'left'}
        {'urpupil' 'left'}
        {'urgaze' 'x' 'right'}
        {'urgaze' 'y' 'right'}
        {'urpupil' 'right'}
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

end
