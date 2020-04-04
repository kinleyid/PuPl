
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
        reshape({eventlog.event.name}, [], 1)
    ]
];

if isfield(eventlog.event, 'rt')
    bigcell = [bigcell [
            'response_time'
            reshape({eventlog.event.rt}, [], 1)
        ]
    ];
end

for evar = pupl_evar_getnames(eventlog.event)
    bigcell = [bigcell [
            evar
            reshape({eventlog.event.(evar{:})}, [], 1);
        ]
    ];
end

fprintf('Saving %s...', fullpath);
writecell2delim(fullpath, bigcell, '\t', eventlog.src);
fprintf('done\n');

end