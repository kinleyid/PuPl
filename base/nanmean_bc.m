
function out = nanmean_bc(varargin)

% Old Matlab: mean(_, 'omitnan') doesn't exist
% New Matlab: nanmean() costs extra

try
    out = nanmean(varargin{:});
catch
    out = mean(varargin{:}, 'omitnan');
end

end
    