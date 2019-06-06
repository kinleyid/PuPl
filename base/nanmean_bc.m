
function out = nanmean_bc(varargin)

% Old Matlab: mean(_, 'omitnan') doesn't exist
% New Matlab: nanmean() costs extra

persistent omitnan;

if ~isempty(omitnan)
    if omitnan
        out = mean(varargin{:}, 'omitnan');
    else
        out = nanmean(varargin{:});
    end
else
    try
        out = nanmean(varargin{:});
        omitnan = false;
    catch
        out = mean(varargin{:}, 'omitnan');
        omitnan = true;
    end

end

end