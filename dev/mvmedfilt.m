function out = mvmedfilt(x, n, filtfunc)

xSize = size(x);
x = x(:); 
p = [nan(n, 1); x; nan(n, 1)]; % nan-padded
nd = numel(x); % n data
n2 = n*2; % n data times 2
w = [nan; p(1:n2)]; % current window
newval = nan;
oldval = nan;
replidx = repmat((1:2*n + 1)', ceil(nd/(2*n + 1)), 1); % index of replaced value
replidx = replidx(1:nd); 
nd100 = nd / 100;
prevmed = nan; % previous median
flag = true;
fprintf('%6.2f%%', 0);
for latidx = 1:nd
    fprintf('\b\b\b\b\b\b\b%6.2f%%', latidx / nd100);
    newval = p(latidx + n2);
    oldval = w(replidx(latidx));
    w(replidx(latidx)) = newval;
    if isnan(x(latidx))
        if ~flag
            flag = true;
        end
    else
        if flag ||...
                xor(isnan(oldval), isnan(newval)) ||...
                ((newval > prevmed) == (oldval <= prevmed)) ||...
                (oldval == prevmed)
            prevmed = filtfunc(w);
            x(latidx) = prevmed;
        end
        if flag
            flag = false;
        end
    end
end

out = reshape(x, xSize);

end