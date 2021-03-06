
function [best_params, lowest_err] = findoffset(sync1, sync2, varargin)

% Params is a 2-element function such that
% sync1 ~ sync2*params(1) + params(2)

if numel(varargin) < 1
    tolerance = 0.05; % 50 ms
else
    tolerance = varargin{1};
end

if numel(varargin) < 2
    ppn = 0.80; % There must be an alignment between at least 80% of the events
else
    ppn = varargin{2};
end

sync1 = sync1(:);
sync2 = sync2(:);

all_poss_offsets = bsxfun(@minus, sync1, sync2');
msize = size(all_poss_offsets);
smaller_n = min(msize);
all_poss_offsets = all_poss_offsets(:)';

best_params = [];
lowest_err = inf;

for cand_offset = all_poss_offsets
    is_match = abs(bsxfun(@minus, sync1, sync2') - cand_offset) < tolerance;
    % is_match is an n x m logical matrix where n is the number of elements
    % in sync1 and m is the number of elements in sync2. is_match(i, j)
    % indicates whether sync1(i) and sync2(j) correspond to one another
    % according to the current candidate clock offset
    if nnz(is_match) < ppn * smaller_n
        % We require that some minimum proportion of events from the
        % smaller set of events have correspondences according to the
        % current candidate clock offset
        continue
    else
        % Get the times of the sync events that correspond to each other
        matches = find(is_match);
        s1_matches = nan(numel(matches), 1);
        s2_matches = nan(numel(matches), 1);
        for match_idx = 1:numel(matches)
            [s1_idx, s2_idx] = ind2sub(msize, matches(match_idx));
            s1_matches(match_idx) = sync1(s1_idx);
            s2_matches(match_idx) = sync2(s2_idx);
        end
        
        % Align the two sets of timestamps by linear regression
        s2_mat = [s2_matches ones(size(s2_matches))];
        cand_params = s2_mat \ s1_matches;
        
        % Check if the MSE is lower than the best candidate offset
        curr_err = mean((s1_matches - s2_mat * cand_params).^2);
        if curr_err < lowest_err
            lowest_err = curr_err;
            best_params = cand_params;
        end
    end
end

end