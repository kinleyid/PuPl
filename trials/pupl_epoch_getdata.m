
function [data, isrej, lims, bef_aft, rel_lats] = pupl_epoch_getdata(EYE, varargin)
% Get epoch data
%
% Inputs:
%   varargin{1}: struct
%       see pupl_epoch_selector
%   varargin(2:end): strings
%       data fields to get data from
% Outputs:
%   out: cell array of 1 x n numeric vectors
% Example:
%   pupl_epoch_getdata_new(eye_data,...
%       'filt', {2 '#rt < 0.2'},... <- get epochs where the reaction time is less than 200 ms
%       'pupil', 'left') % Get left pupil size

if numel(varargin) > 0
    epoch_selector = varargin{1};
else
    epoch_selector = [];
end

if numel(varargin) > 1
    data_fields = varargin(2:end);
else
    data_fields = {'pupil' 'both'};
end

if ismember('ur', data_fields)
    maybe_ur = {'ur'};
else
    maybe_ur = {};
end

data = cell(1, numel(EYE));
isrej = cell(1, numel(EYE));
lims = cell(1, numel(EYE));
bef_aft = cell(1, numel(EYE));
rel_lats = cell(1, numel(EYE));

for dataidx = 1:numel(EYE)
    
    epochs = pupl_epoch_get(EYE(dataidx), epoch_selector);
    
    abslats = pupl_epoch_get(EYE(dataidx), epoch_selector, '_abslats', maybe_ur{:});
    rellats = pupl_epoch_get(EYE(dataidx), epoch_selector, '_rellats', maybe_ur{:});
    
    if isequal(data_fields, {'pupil' 'both'}) % Compute on the fly
        EYE(dataidx) = pupl_mergelr(EYE(dataidx));
    end
    all_data = getfield(EYE(dataidx), data_fields{:}); % Continuous data from current recording
    
    curr_data = cell(1, numel(epochs)); % Container for epoch data from the current recording
    curr_bef_aft = cell(1, numel(epochs));
    curr_rel_lats = cell(1, numel(epochs));
    for epochidx = 1:numel(epochs)
        % Get data
        curr_epoch = epochs(epochidx);
        curr_lims = abslats(epochidx, :);
        curr_data{epochidx} = all_data(curr_lims(1):curr_lims(2));
        curr_bef_aft{epochidx} = curr_epoch.other.when;
        curr_rel_lats{epochidx} = rellats(epochidx, :);
        % Baseline correction
        if ismember({'pupil'}, data_fields) && isfield(curr_epoch, 'baseline')
            for b_idx = 1:numel(curr_epoch.baseline)
                baseline = curr_epoch.baseline(b_idx);
                corr_func = baseline.func;
                corr_func = str2func(func2str(corr_func));  % Avoids "undefined function handle" error in r2015
                baseline_data = pupl_epoch_getdata(EYE(dataidx), baseline, data_fields{:});
                curr_data{epochidx} = corr_func(curr_data{epochidx}, baseline_data{:});
            end
        end
    end
    
    data{dataidx} = curr_data;
    lims{dataidx} = {epochs.lims};
    if isfield(epochs, 'reject')
        isrej{dataidx} = [epochs.reject];
    else
        isrej{dataidx} = false(size(epochs));
    end
    bef_aft{dataidx} = curr_bef_aft;
    rel_lats{dataidx} = curr_rel_lats;
end

data = [data{:}]';
isrej = [isrej{:}]';
lims = [lims{:}]';
bef_aft = [bef_aft{:}];
rel_lats = [rel_lats{:}];

% Fill in the missing data
lens = cellfun(@numel, data);
max_len = max(lens);
too_short = find(lens(:)' < max_len);
for dataidx = too_short
    n_missing = max_len - lens(dataidx);
    new_nans = nan(1, n_missing);
    switch bef_aft{dataidx}
        case 'before'
            data{dataidx} = [new_nans data{dataidx}];
            rel_lats{dataidx}(1) = rel_lats{dataidx}(1) - n_missing;
        case 'after'
            data{dataidx} = [data{dataidx} new_nans];
            rel_lats{dataidx}(2) = rel_lats{dataidx}(2) + n_missing;
    end
end

end
