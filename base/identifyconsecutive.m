function [idx, starts, ends] = identifyconsecutive(vec, n, func, varargin)

if numel(varargin) == 1
    t = varargin{1};
else
    t = 'most';
end

if numel(varargin) == 2
    v = varargin{1}; % Verbose
else
    v = false;
end

% Identify stretches of elements in vec that return true when
% func is applied to them
% t: 'least': at least n elements
% t: 'most': at most n elements

starts = [];
ends = [];
idx = false(size(vec));
i = 0;
flag = false;
nv = numel(vec);
while true
    i = i + 1;
    if i > nv
        break
    end
    if v
        fprintf('%6.2f%%', 100*i/nv);
    end
    if func(vec(i))
        starts(end + 1) = i;
        j = 0; % N. consecutive - 1
        while true
            j = j + 1;
            if i + j > nv
                switch t
                    case 'most'
                        if j <= n
                            idx(i:(i+j-1)) = true;
                            ends(end + 1) = i + j - 1;
                        else
                            starts(end) = []; % False start
                        end
                    case 'least'
                        if j >= n
                            idx(i:(i+j-1)) = true;
                            ends(end + 1) = i + j - 1;
                        else
                            starts(end) = []; % False start
                        end
                end
                flag = true;
                break
            end
            if v
                fprintf('%6.2f%%', 100*(i + j)/nv);
            end
            if ~func(vec(i + j))
                switch t
                    case 'most'
                        if j <= n
                            idx(i:(i+j-1)) = true;
                            ends(end + 1) = i + j - 1;
                        else
                            starts(end) = [];
                        end
                    case 'least'
                        if j >= n
                            idx(i:(i+j-1)) = true;
                            ends(end + 1) = i + j - 1;
                        else
                            starts(end) = [];
                        end
                end
                i = i + j;
                break
            end
        end
    end
    if flag
        break
    end
end

end