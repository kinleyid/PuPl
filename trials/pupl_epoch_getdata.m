
function [data, isrej, lims] = pupl_epoch_getdata(EYE, varargin)

% Get epoch data
%   Inputs
% EYE: struct array or single struct
% varargin{1}: struct array (epochs), index (numerical index of epochs), empty (all epochs), or string (epochs within a set)
% varargin{2:end}: strings to specify which data to access
%   Outputs
% out: cell array of 1 x n numeric vectors

if isempty(varargin)
    sel = [];
else
    sel = varargin{1};
end
data_fields = varargin(2:end);
if isempty(data_fields)
    data_fields = {'pupil' 'both'};
end

data = cell(1, numel(EYE));
isrej = cell(1, numel(EYE));
lims = cell(1, numel(EYE));

for dataidx = 1:numel(EYE)
    if isstruct(sel)
        epochs = sel;
    else
        if isempty(sel) % Return data from all epochs for the current recording
            selidx = 1:numel(EYE(dataidx).epoch);
        elseif ischar(sel) % Return data from all epochs belonging to a set
            epochset = EYE(dataidx).epochset(strcmp({EYE(dataidx).epochset.name}, sel));
            selidx = find(pupl_epoch_sel(EYE(dataidx), EYE(dataidx).epoch, epochset.members));
        else
            if islogical(sel)
                sel = find(sel);
            end
            selidx = sel;
        end
        epochs = EYE(dataidx).epoch(selidx);
    end
    
    if isequal(data_fields, {'pupil' 'both'}) % Compute on the fly
        EYE(dataidx) = pupl_mergelr(EYE(dataidx));
    end
    all_data = getfield(EYE(dataidx), data_fields{:}); % All data from current recording
    
    curr_data = cell(1, numel(epochs)); % Epoch data from the current recording
    for epochidx = 1:numel(epochs)
        curr_epoch = epochs(epochidx);
        curr_lims = ...
            pupl_epoch_get(EYE(dataidx), curr_epoch, '_lat') + ...
            parsetimestr(curr_epoch.lims, EYE(dataidx).srate, 'smp');
        curr_data{epochidx} = all_data(unfold(curr_lims));
        
        % Baseline correction
        if ismember({'pupil'}, data_fields) && isfield(curr_epoch, 'baseline')
            baseline_data = pupl_epoch_getdata(EYE(dataidx), curr_epoch.baseline, data_fields{:});
            curr_data{epochidx} = curr_epoch.baseline.func(curr_data{epochidx}, baseline_data{:});
        end
    end
    
    data{dataidx} = curr_data;
    lims{dataidx} = {epochs.lims};
    if isfield(epochs, 'reject')
        isrej{dataidx} = [epochs.reject];
    else
        isrej{dataidx} = false(size(epochs));
    end
    
end

data = [data{:}]';
isrej = [isrej{:}]';
lims = [lims{:}]';

end