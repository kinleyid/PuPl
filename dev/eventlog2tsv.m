
function eventlog2tsv(eventLog, fullpath)

bigcell = [...
    [
        'onset'
        reshape({eventLog.time}, [], 1)
    ] [
        'duration'
        num2cell(zeros('n/a', numel(eventLog.event), 1))
    ] [
        'trial_type'
        reshape({eventLog.event.type}, [], 1)
    ] [
        'response_time'
        num2cell(repmat('n/a', numel(eventLog.event), 1)) % reshape({eventLog.event.rt}, [], 1)
    ]
];

writecell(fullpath, bigcell, '\t');

end