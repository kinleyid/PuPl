
function save_asc(EYE, fullpath)

all_fields = fieldnames(EYE);

non_header_fields = {
    'ur'
    'pupil'
    'gaze'
    'times'
    'event'
    'datalabel'
    'interstices'
    'UI_n'
    'ppnmissing'
    'eventlog'
    'BIDS'
    'history'
};

header_fields = all_fields(~ismember(all_fields, non_header_fields));

header_lines = {};
for field = header_fields(:)'
    header_lines = [header_lines get_fields_recursive(EYE, field{:}, true)];
end

colnames = {};
for non_header_field = {'gaze' 'pupil' 'times' 'datalabel'} % Add interstices back
    colnames = [colnames get_fields_recursive(EYE, non_header_field{:}, false)];
end

all_data = [];
for col = colnames
    curr_fields = regexp(col{:}, '\.', 'split');
    curr_data = getfield(EYE, curr_fields{:});
    all_data = [all_data num2cell(curr_data(:))];
end

header = header_lines;
contents = [
    colnames
    all_data
];

writecell2delim(fullpath, contents, sprintf('\t'), header{:});

end

function header_lines = get_fields_recursive(s, fname, getdat)

header_lines = {};

f = s.(fname);
if isstruct(f) && numel(f) == 1
    sub_fnames = fieldnames(f);
    for sub_fname = sub_fnames(:)'
        new_lines = get_fields_recursive(f, sub_fname{:}, getdat);
        header_lines = [header_lines strcat(fname, '.', new_lines)];
    end
else
    curr_line = fname;
    if getdat
        curr_line = sprintf('%s: %s', curr_line, all2str(f));
    end
    header_lines{end + 1} = curr_line;
end

end