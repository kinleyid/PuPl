function latencies = spandesc2lats(EYE, spandesc)

%  Inputs
% EYE--SINGLE struct, not array
% spanDescription--SINGLE struct, not array

%  Outputs
% latencies--cell array of integer arrays

lims = EYE.srate * [
    parsetimestr(spandesc.bookends(1), EYE.srate)
    parsetimestr(spandesc.bookends(2), EYE.srate)
];

starts = find(ismember(spandesc.events{1}, {EYE.event.type}));
if spandesc.events{2} == 0
    ends = find(ismember(spandesc.events{1}, {EYE.event.type}));
else
    ends = find(ismember(spandesc.events{2}, {EYE.event.type}));
end

if spandesc.instanceidx ~= 0
    starts = starts(spandesc.instanceidx);
    ends = ends(spandesc.instanceidx);
end

if numel(starts) ~= numel(ends)
    warning('More epoch-starting events that epoch-ending events, trimming extras');
    ends = ends(1:numel(starts));
end

slims = EYE.event(starts).latency + lims(1);
elims = EYE.event(ends).latency + lims(2);
latencies = cell(numel(slims));
for i = 1:numel(slims)
    latencies{i} = slims(i):elims(i);
end

end
