
function eventlog2tsv(eventLog, fullpath)

bigcell = [...
    [
        'onset'
        reshape({eventLog.event.time}, [], 1)
    ] [
        'duration'
        repmat({'n/a'}, numel(eventLog.event), 1)
    ] [
        'trial_type'
        reshape({eventLog.event.type}, [], 1)
    ] [
        'response_time'
        repmat({'n/a'}, numel(eventLog.event), 1) % reshape({eventLog.event.rt}, [], 1)
    ]
];

writecell(fullpath, bigcell, '\t');

end