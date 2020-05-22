
function out = pupl_blink_id(EYE, varargin)
% Identify blinks according to one of a number of criteria
%
% Inputs:
%   method: string
%       specifies the method of blink identification
%   overwrite: boolean
%       specifies whether pre-existing blink labels should be overwritten
%   cfg: struct
%       configures the implementation of the method used
% Example:
%   pupl_blink_id(eye_data,...
%       'method', 'velocity',...
%       'overwrite', false,...
%       'cfg', struct(...
%           'onset_lim', -150,... 
%           'offset_lim', 150,...
%           'max_len', '400ms'))
if nargin == 0
    out = @getargs;
else
    out = sub_blink_id(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'method' []
    'overwrite' []
    'cfg' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.method)
    method_opts = {'Amount of consecutive missing data' 'Pupillometry noise' 'Dilation velocity threshold'};
    sel = listdlgregexp(...
        'PromptString', 'Identify blinks by which criterion?',...
        'ListString', method_opts,...
        'SelectionMode', 'single',...
        'regexp', false);
    if isempty(sel)
        return
    end
    switch sel
        case 1
            sel = 'missing';
        case 2
            sel = 'noise';
        case 3
            sel = 'velocity';
    end
    args.method = sel;
end

if isempty(args.overwrite)
    if any([EYE.datalabel] == 'b')
        a = questdlg('Overwrite previous blink labels?');
        switch a
            case 'Yes'
                args.overwrite = true;
            case 'No'
                args.overwrite = false;
            otherwise
                return
        end
    else
        args.overwrite = true;
    end
end

if isempty(args.cfg)
    switch args.method
        case 'missing'
            params = inputdlg({sprintf('Blink length\n\nMin') 'Max'}, '', 1, {'100ms' '400ms'});
            if isempty(params)
                return
            end
            args.cfg = struct(...
                'min', params{1},... 
                'max', params{2});
        case 'noise'
            % No configuration necessary
        case 'velocity'
            vel = cell(size(EYE));
            for dataidx = 1:numel(EYE)
                EYE(dataidx).pupil.both = mergelr(EYE(dataidx));
                vel{dataidx} = diff(EYE(dataidx).pupil.both);
            end
            onset_lim = UI_cdfgetrej(vel,...
                'dataname', 'dilation velocity samples',...
                'threshname', 'Blink onset threshold',...
                'names', {EYE.name},...
                'outcomename', 'marked as blink onsets',...
                'func', @le);
            if isempty(onset_lim)
                return
            end
            offset_lim = UI_cdfgetrej(vel,...
                'dataname', 'dilation velocity samples',...
                'threshname', 'Blink offset threshold',...
                'names', {EYE.name},...
                'outcomename', 'marked as blink offsets',...
                'func', @ge);
            if isempty(offset_lim)
                return
            end
            max_len = inputdlg('Max blink length', '', 1, {'400ms'});
            if isempty(max_len)
                return
            end
            args.cfg = struct(...
                'onset_lim', onset_lim,... 
                'offset_lim', offset_lim,...
                'max_len', max_len);
    end
end

switch args.method
    case 'missing'
        fprintf('Identifying blinks by consecutive missing data (method "missing")\nMin. blink length: %s\nMax. blink length: %s\n', args.cfg.min, args.cfg.max);
    case 'noise'
        fprintf('Identifying blinks by pupillometry noise (method "noise")\n');
    case 'velocity'
        fprintf('Identifying blinks by dilation velocity (method "velocity").\n');
        fprintf('Blinks begin when dilation velocity becomes less than or equal to %s\n', args.cfg.onset_lim);
        fprintf('Blinks end when dilation velocity becomes greater than or equal to %s\n', args.cfg.offset_lim);
        fprintf('Blinks are constrained to a max length of %s\n', args.cfg.max_len);
end

outargs = args;

end

function EYE = sub_blink_id(EYE, varargin)

args = parseargs(varargin{:});

pupil = mergelr(EYE);

switch args.method
    case 'missing'
        minblinklen = parsetimestr(args.cfg.min, EYE.srate, 'smp');
        maxblinklen = parsetimestr(args.cfg.max, EYE.srate, 'smp');
        blinkidx = ...
            ic_fft(isnan(pupil), minblinklen, 'least') &...
            ic_fft(isnan(pupil), maxblinklen, 'most');
    case 'noise'
        pupil(isnan(pupil)) = 0;
        blinkidx = based_noise_blinks_detection(pupil(:), EYE.srate);
        if mod(numel(blinkidx), 2) ~= 0
            blinkidx(end) = [];
        end
        if blinkidx(1) == 0
            blinkidx(1) = 1;
        end
        blinkidx = reshape(blinkidx, 2, [])';
        % Go from integer to logical index
        tmp = false(size(pupil));
        for ii = 1:size(blinkidx, 1)
            tmp(blinkidx(ii, 1):blinkidx(ii, 2)) = true;
        end
        blinkidx = tmp;
    case 'velocity'
        vel = diff(pupil);
        onset_lim = parsedatastr(args.cfg.onset_lim, vel);
        offset_lim = parsedatastr(args.cfg.offset_lim, vel);
        max_len = parsetimestr(args.cfg.max_len, EYE.srate, 'smp');
        blinkidx = false(size(pupil));
        isblink = false;
        si = 0; % Sample index
        while true
            if si == numel(vel)
                break
            else
                si = si + 1;
            end
            
            if vel(si) <= onset_lim
                if ~isblink
                    onsetidx = si + 1; % The point that was jumped to
                end
                isblink = true; % A new blink has begun
            elseif vel(si) >= offset_lim
                % Find latest offset sample
                while true
                    if si == numel(vel) || vel(si) < offset_lim
                        si = si - 1; % Go back to when the threshold was exceeded
                        break
                    else
                        si = si + 1;
                    end
                end
                if isblink % Onset already occured, therefore this is a reversal
                    offsetidx = si;
                    if offsetidx - onsetidx - 1 < max_len
                        blinkidx(onsetidx:offsetidx) = true;
                    end
                    isblink = false;
                end
            end
        end
end

if ~islogical(blinkidx)
    tmp = false(1, EYE.ndata);
    tmp(blinkidx) = true;
    blinkidx = tmp;
end

blinkstarts = find(diff(blinkidx) == 1);
blinkends = find(diff(blinkidx) == -1);
if any(blinkidx)
    if blinkstarts(1) > blinkends(1) % Recording starts with a blink
        blinkstarts = [1 blinkstarts];
    end
end
nblinks = numel(blinkstarts);
nmins = EYE.ndata / EYE.srate / 60;

fprintf('According to method "%s":\n', args.method);
fprintf('\t%f%% of data marked as blinks using this method\n', 100 * nnz(blinkidx) / EYE.ndata);
fprintf('\t%d blinks in %0.2f minutes of recording (%.2f blinks/min)\n', nblinks, nmins, nblinks/nmins)

if args.overwrite
    EYE.datalabel = repmat(' ', size(EYE.datalabel));
end
EYE.datalabel(blinkidx) = 'b';

blinkidx = EYE.datalabel == 'b'; % Print info about the data overall
blinkstarts = find(diff(blinkidx) == 1);
blinkends = find(diff(blinkidx) == -1);
if any(blinkidx)
    if blinkstarts(1) > blinkends(1) % Recording starts with a blink
        blinkstarts = [1 blinkstarts];
    end
end
nblinks = numel(blinkstarts);
fprintf('In total:\n');
fprintf('\t%f%% of data marked as blinks\n', 100 * nnz(blinkidx) / EYE.ndata);
fprintf('\t%d blinks in %0.2f minutes of recording (%.2f blinks/min)\n', nblinks, nmins, nblinks/nmins)

end

function blinks_data_positions = based_noise_blinks_detection(pupil_data, sampling_rate_in_hz) 
    
    % From Hershman, R., Henik, A., & Cohen, N. (2018). A novel blink detection method based on pupillometry noise. Behavior research methods, 50(1), 107-114.
    
    blinks_data_positions = [];
    sampling_interval     = round(1000/sampling_rate_in_hz); % compute the sampling time interval in milliseconds.
    gap_interval          = 100;                             % set the interval between two sets that appear consecutively for concatenation.
    
    %% Setting the blinks' candidates array
    % explanations for line 16:
    % pupil_data==0 returns a matrix of zeros and ones, where one means missing values for the pupil (missing values represented by zeros).
    % it looks like: 0000001111110000
    % diff(n) = pupil_data(n+1)-pupil_data(n)
    % find(diff(pupil_data==0)==1) returns the first sample before the missing values 
    % find(diff(pupil_data==0)==-1) returns the last missing values
    % it looks like: 00000100000-1000 
    % blink onset is represented by a negative value and blink offset is represented by a positive value
    blinks      = vertcat(-1.*find(diff(pupil_data==0)==1), find(diff(pupil_data==0)==-1)+1);    
    
    % Case 1: there are no blinks
    if(isempty(blinks))          
        return;
    end
    
    % Sort the blinks by absolute value. in this way we are getting an array of blinks when the offset appears after the onset 
    [~, idx] = sort(abs(blinks));
    blinks   = blinks(idx);

    %% Edge cases
    % Case 2: the data starts with a blink. In this case, blink onset will be defined as the first missing value.
    if(size(blinks, 1)>0 && blinks(1)>0) && pupil_data(1)==0 
        blinks = vertcat(0, blinks);
    end
    
    % Case 3: the data ends with a blink. In this case, blink offset will be defined as the last missing sample
    if(size(blinks, 1)>0 && blinks(end)<0) && pupil_data(end)==0 
        blinks = vertcat(blinks, size(pupil_data, 1));
    end

    %% Smoothing the data in order to increase the difference between the measurement noise and the eyelid signal.
    ms_4_smooting  = 10;                                    % using a gap of 10 ms for the smoothing
    samples2smooth = ceil(ms_4_smooting/sampling_interval); % amount of samples to smooth 
    if samples2smooth > 1
        smooth_data = fft_conv(pupil_data, ones(samples2smooth, 1));
    else
        smooth_data = pupil_data;
    end

    smooth_data(smooth_data==0) = nan;                      % replace zeros with NaN values
    diff_smooth_data            = diff(smooth_data);
    
    %% Finding the blinks' onset and offset
    blink                 = 1;                         % initialize blink index for iteration
    blinks_data_positions = zeros(size(blinks, 1), 1); % initialize the array of blinks
    prev_offset           = -1;                        % initialize the previous blink offset (in order to detect consecutive sets)    
    fprintf('%06.2f%%', 0);
    last_pct = 0;
    while blink < size(blinks, 1)
        pct = round(100 * blink / size(blinks, 1));
        if pct > last_pct
            last_pct = pct;
            fprintf(repmat('\b', 1, 7));
            fprintf('%06.2f%%', last_pct);
        end
        % set the onset candidate
        onset_candidate = blinks(blink);
        if(onset_candidate>0 && blinks(blink) == -blinks(blink+1)) % wrong sorting
            blinks(blink:blink+1) = -blinks(blink:blink+1);
            onset_candidate = blinks(blink);
        end
        blink = blink + 1;  % increase the value for the offset
        
        % set the offset candidate
        offset_candidate = blinks(blink);
        if(offset_candidate<0 && blinks(blink) == -blinks(blink+1)) % wrong sorting
            blinks(blink:blink+1) = -blinks(blink:blink+1);
            offset_candidate = blinks(blink);
        end

        blink = blink + 1;  % increase the value for the next blink
        
        % find blink onset
        data_before = diff_smooth_data(2:abs(onset_candidate)); % returns all the data before the candidate
        blink_onset = find(data_before>0, 1, 'last');           % returns the last 2 samples before the decline
        
        % Case 2 (the data starts with a blink. In this case, blink onset will be defined as the first missing value.)
        if isempty(blink_onset)
            if onset_candidate == blinks(1)
                blink_onset = 0;
            else
                blink_onset = -abs(onset_candidate);
            end
        end
        
        % correct the onset if we are not in case 2
        if onset_candidate>0 || pupil_data(blink_onset+2)>0
            blink_onset = blink_onset+2;
        end
        
        % find blink offset
        data_after   = diff_smooth_data(abs(offset_candidate):end); % returns all data after the candidate
        blink_offset = offset_candidate+find(data_after<0, 1);     % returns the last sample before the pupil increase

        % Case 3 (the data ends with a blink. In this case, blink offset will be defined as the last missing sample.)
        if isempty(blink_offset)
            blink_offset = size(pupil_data, 1)+1;
        end
        % Set the onset to be equal to the previous offset in case where several sets of missing values are presented consecutively
        if (sampling_interval*blink_onset > gap_interval && sampling_interval*blink_onset-sampling_interval*prev_offset<=gap_interval)
            blink_onset = prev_offset;
        end
        
        prev_offset = blink_offset-1;
        % insert the onset into the result array
        blinks_data_positions(blink-2) = -sampling_interval*blink_onset;
        % insert the offset into the result array
        blinks_data_positions(blink-1) = sampling_interval*(blink_offset-1);
    end
    fprintf(repmat('\b', 1, 7));
    fprintf('%06.2f%%\n', 100);
    
    %% Removing duplications (in case of consecutive sets): [a, b, b, c] => [a, c] (V3: better removing)
    id = 1;
    while (id<length(blinks_data_positions)-1)
        if(blinks_data_positions(id)>0 && blinks_data_positions(id)==-blinks_data_positions(id+1))
            blinks_data_positions(id:id+1) = [];
        else
            id = id+1;
        end
    end
    blinks_data_positions = abs(blinks_data_positions);
    blinks_data_positions = blinks_data_positions / sampling_interval;
end
