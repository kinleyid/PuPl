
function eventlog2tsv(eventlog, fullpath)

bigcell = [...
    [
        'onset'
        reshape({eventlog.event.time}, [], 1)
    ] [
        'duration'
        repmat({'n/a'}, numel(eventlog.event), 1)
    ] [
        'trial_type'
        reshape({eventlog.event.type}, [], 1)
    ] [
        'response_time'
        reshape({eventlog.event.rt}, [], 1)
    ]
];

writecell2delim(fullpath, bigcell, '\t', eventlog.src);

end