function idx = identifyconsecutive(vec, n, func)

% Identify stretches of at most n elements in vec that return true when
% func is applied to them

idx = false(size(vec));
i = 0;
flag = false;
while true
    i = i + 1;
    if i > numel(vec)
        break
    end
    if func(vec(i))
        j = 0;
        while true
            j = j + 1;
            if i + j > numel(vec)
                if j - 1 <= n
                    idx(i:(i+j-1)) = true;
                end
                flag = true;
                break
            end
            if ~func(vec(i + j))
                if j <= n
                    idx(i:(i+j-1)) = true;
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