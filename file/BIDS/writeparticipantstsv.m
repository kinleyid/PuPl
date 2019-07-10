
function writeparticipantstsv(EYE)

allpeople = unique(mergefields(EYE, 'BIDS', 'sub'));
allrows = [
    {'participant_id' 
    cell(numel(allpeople), 2);
];
for ii = 1:numel(allpeople)
    curr_group = inputdlg(sprintf('sub-%s\n\nGroup:', allpeople{ii}));
    if isempty(curr_group)
        return
    end
    allrows(ii, :) = [allpeople(ii) currgroup];
end

[f, d] = uiputfile('*.tsv', 'Write where?');

writecell(fullfile(d, f), allrows, '\t')

end