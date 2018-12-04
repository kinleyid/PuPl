function plotrejection(f)

teditbox = findobj(f, 'Tag', 'threshold');
currThreshold = str2double(teditbox.String);

missingPpns = cell2mat(getmissingppns(f.UserData.data));

proportions = 0:0.01:1;   
ppnViolating = sum(bsxfun(@ge, missingPpns', proportions))/numel(missingPpns);
currPpnViolating = nnz(missingPpns >= currThreshold)/numel(missingPpns);
ax = findobj(f, 'Tag', 'axis');
axes(ax); cla; hold on
plot(proportions, ppnViolating, 'k');
plot(repmat(currThreshold, 1, 2), [0 1], '--k')
plot([0 1], repmat(currPpnViolating, 1, 2), '--k')
xlim([0 1]);
ylim([0 1]);
title('Poportion of trials rejected as a function of rejection threshold');
xlabel('Missing values threshold (proportion)');
ylabel('Proportion of trials violating threshold');

end