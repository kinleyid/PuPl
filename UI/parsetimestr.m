
function out = parsetimestr(timestr, srate, varargin)

%   Inputs
% timestr--something with ms, m, s, dp, or d
% srate--sample rate
% varargin--none or 'secs': output is in seconds
%           'samples' or 'smp': output is in samples (e.g. 1s at 60Hz gives 60)
%   Outputs
% outtime--time in seconds or samples

timestr = cellstr(timestr);
out = nan(1, numel(timestr));
for idx = 1:numel(timestr)

    cmd = lower(timestr{idx});
    cmd = strrep(cmd,' ','');

    for x = {'ms'}
        cmd = strsubconstval(cmd, x{:}, '(1/1000)');
    end
    for x = {'s'}
        cmd = strsubconstval(cmd, x{:}, '1');
    end
    for x = {'m'}
        cmd = strsubconstval(cmd, x{:}, '60');
    end
    for x = {'dp' 'd'}
        cmd = strsubconstval(cmd, x{:}, sprintf('(1/%f)', srate));
    end

    out(idx) = eval(cmd);
end

if nargin > 0
    if ismember(varargin{1}, {'samples' 'smp'})
        out = round(out * srate);
    end
end

end