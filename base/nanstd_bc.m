
function out = nanstd_bc(varargin)

% Old Matlab: std(_, 'omitna') doesn't exist
% New Matlab: nanstd() costs extra

try
    out = nanstd(varargin{:});
catch
    out = std(varargin{:}, 'omitnan');
end

end
    