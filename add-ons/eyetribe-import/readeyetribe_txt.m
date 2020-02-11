function out = readeyetribe_txt(fullpath)

json = readdelim2cell(fullpath, 'extremely unlikely delimiter so I can import text as columns');

issample = ~cellfun(@isempty, regexp(json, '"category":"tracker"', 'once'));
samples = json(issample);
timestamps = regexp2num(regexp(samples, '"time":(\d+\.*\d*)', 'tokens'));
srate = estimatesrate(timestamps);
while srate == 0
    timestamps = timestamps / 1000;
    srate = estimatesrate(timestamps);
end
'(\d+-\d+-d+ \d+:\d+:\d+\.d+)';
t1 = regexp(samples(1), '"timestamp":"(\d+-\d+-\d+ \d+\:\d+\:\d+\.\d+)', 'tokens');
t1 = 86400 * datenum(t1{:}{:}{:}, 'yyyy-mm-dd HH:MM:SS.FFF');

urpupil = [];
urgaze = [];
for side = {'left' 'right'}
    diam_expr = [side{:} 'eye.*?"psize":(\d+\.*\d*)'];
    urpupil.(side{:}) = regexp2num(regexp(samples, diam_expr, 'tokens'));
    for ax = {'x' 'y'}
        gaze_expr = [side{:} 'eye.*?"raw":.*?"' ax{:} '":(\d+\.*\d*)'];
        urgaze.(ax{:}).(side{:}) = regexp2num(regexp(samples, gaze_expr, 'tokens'));
    end
end

out = struct(...
    'urpupil', urpupil,...
    'srate', srate,...
    'urgaze', urgaze,...
    't1', t1);

end

function out = regexp2num(in)

tmp = cell(size(in));
ie = cellfun(@isempty, in); 
tmp(~ie) = [in{:}];
tmp(ie) = {'nan'};
out = cellstr2num([tmp{:}]);

end