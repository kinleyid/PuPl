
function out = nanmedian_bc(varargin)

% Old Matlab: me(di)an(_, 'omitna') doesn't exist
% New Matlab: nanme(di)an() costs extra

persistent omitnan;

if ~isempty(omitnan)
    if omitnan
        out = median(varargin{:}, 'omitnan');
    else
        out = nanmedian(varargin{:});
    end
else
    try
        out = nanmedian(varargin{:});
        omitnan = false;
    catch
        out = median(varargin{:}, 'omitnan');
        omitnan = true;
    end

end

end
    