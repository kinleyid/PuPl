
function [data, isrej] = pupl_epoch_getdata(EYE, varargin)

% Get epoch data
%   Inputs
% EYE: struct array or single struct
% varargin{1}: index (numerical index of epochs), empty (all epochs), or string (epochs within a set)
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

for dataidx = 1:numel(EYE)
    if isempty(sel) % Return data from all epochs for the current recording
        idx = 1:numel(EYE(dataidx).epoch);
    elseif ischar(sel) % Return data from all epochs belonging to a set
        epochset = EYE(dataidx).epochset(strcmp({EYE(dataidx).epochset.name}, sel));
        idx = find(...
            regexpsel({EYE(dataidx).epoch.name}, epochset.description.members));
    else
        if islogical(sel)
            sel = find(sel);
        end
        idx = sel;
    end
    
    if isequal(data_fields, {'pupil' 'both'}) % Compute on the fly
        EYE(dataidx) = pupl_mergelr(EYE(dataidx));
    end
    all_data = getfield(EYE(dataidx), data_fields{:}); % All data from current recording
    
    curr_data = cell(1, nnz(idx)); % Epoch data from the current recording
    for ii = 1:numel(idx)
        curr_epoch = EYE(dataidx).epoch(idx(ii));
        curr_lims = curr_epoch.event.latency + ...
            parsetimestr(curr_epoch.lims, EYE(dataidx).srate, 'smp');
        curr_data{ii} = all_data(unfold(curr_lims));
        
        % Baseline correction
        if strcmp(data_fields{1}, 'pupil') && isfield(curr_epoch, 'baseline')
            baseline_data = all_data(curr_epoch.baseline.lims); % Already as latencies
            curr_data{ii} = curr_epoch.baseline.func(curr_data{ii}, baseline_data);
        end
    end
    
    data{dataidx} = curr_data;
    isrej{dataidx} = [EYE(dataidx).epoch(idx).reject];
    
end

data = [data{:}]';
isrej = [isrej{:}]';

end