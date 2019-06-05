
function out = nanmedian_bc(varargin)

% Old Matlab: me(di)an(_, 'omitna') doesn't exist
% New Matlab: nanme(di)an() costs extra

try
    out = nanmedian(varargin{:});
catch
    out = median(varargin{:}, 'omitnan');
end

end
    