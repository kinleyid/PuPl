function idx = identifyconsecutive(vec, n, func, varargin)

if numel(varargin) == 1
    t = varargin{1};
else
    t = 'most';
end

% Identify stretches of elements in vec that return true when
% func is applied to them
% t: 'least': at least n elements
% t: 'most': at most n elements

idx = false(size(vec));
i = 0;
flag = false;
while true
    i = i + 1;
    if i > numel(vec)
        break
    end
    if func(vec(i))
        j = 0; % N. consecutive - 1
        while true
            j = j + 1;
            if i + j > numel(vec)
                switch t
                    case 'most'
                        if j <= n
                            idx(i:(i+j-1)) = true;
                        end
                    case 'least'
                        if j >= n
                            idx(i:(i+j-1)) = true;
                        end
                end
                flag = true;
                break
            end
            if ~func(vec(i + j))
                switch t
                    case 'most'
                        if j <= n
                            idx(i:(i+j-1)) = true;
                        end
                    case 'least'
                        if j >= n
                            idx(i:(i+j-1)) = true;
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