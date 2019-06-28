
function readparticipantstsv(EYE)

[f, d] = uigetfile('*.tsv', 'Select participants.tsv');
raw = readcell(fullfile(d, f));
raw(1, :)

end