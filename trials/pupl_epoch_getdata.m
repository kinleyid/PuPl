
function [data, isrej] = pupl_epoch_getdata(EYE, varargin)

% Get epoch data
%   Inputs
% EYE: struct array or single struct
% varargin{1}: index (numerical index of epochs), empty (all epochs), or string
% (epochs within a set)
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
            ismember({EYE(dataidx).epoch.name}, epochset.description.members));
    else
        if islogical(sel)
            sel = find(sel);
        end
        idx = sel;
    end
    
    vec = getfield(EYE(dataidx), data_fields{:}); % All data from current recording
    
    curr = cell(1, nnz(idx));
    for ii = 1:numel(idx)
        epoch = EYE(dataidx).epoch(idx(ii));
        rellims = EYE(dataidx).srate*[
            parsetimestr(epoch.lims{1}, EYE(dataidx).srate)...
            parsetimestr(epoch.lims{2}, EYE(dataidx).srate)
        ];
        abslims = (rellims(1):rellims(2)) + epoch.event.latency;
        curr{ii} = vec(abslims);
        % Baseline correction
        if strcmp(data_fields{1}, 'pupil')
            if isfield(epoch, 'baseline')
                curr{ii} = epoch.baseline.func(curr{ii}, vec(abslims));
            end
        end
    end
    
    data{dataidx} = curr;
    isrej{dataidx} = [EYE(dataidx).epoch(idx).reject];
    
end

data = [data{:}]';
isrej = [isrej{:}]';

end