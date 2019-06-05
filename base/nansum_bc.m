
function out = nansum_bc(varargin)

% Old Matlab: sum(_, 'omitnan') doesn't exist
% New Matlab: nansum() costs extra

try
    out = nansum(varargin{:});
catch
    out = sum(varargin{:}, 'omitnan');
end

end
    