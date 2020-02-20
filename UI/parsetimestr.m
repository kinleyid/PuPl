
function out = parsetimestr(timestr, srate, varargin)

%   Inputs
% timestr--something with ms, m, s, dp, or d
% srate--sample rate
% varargin{1}
%           none: output is in seconds
%           'samples' or 'smp': output is in samples
% varargin{2}
%           none: 1s at 60Hz gives 60, 0s give 0
%           'abs': 1s at 60Hz gives 61, 0s gives 1
%   Outputs
% outtime--time in seconds or samples

if isnumeric(timestr)
    timestr = num2cell(timestr);
elseif ischar(timestr)
    timestr = cellstr(timestr);
end

out = nan(1, numel(timestr));
for idx = 1:numel(timestr)
    if isnumeric(timestr{idx})
        out(idx) = timestr{idx};
    else
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
end

if numel(varargin) > 0
    if ismember(varargin{1}, {'samples' 'smp'})
        out = round(out * srate);
        if numel(varargin) > 1
            if strcmp(varargin{2}, 'abs')
                out = out + 1;
            end
        end
    end
end

end