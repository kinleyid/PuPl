
function varargout = pupl_txt(full_path, file_ctrl, type_ctrl, varargin)

% file_ctrl: 'w' or 'r'
% type_ctrl: 'c' (continuous data) or 'e' (events) or 'ce' (both)

header_fields = {
    'srate'
    'units'
};

switch file_ctrl
    case {'w' 'write'}
        EYE = varargin{1};
        %% Write timeseries data?
        if any(type_ctrl == 'c')
            header_lines = {};
            for field = header_fields(:)'
                header_lines = [header_lines get_fields_recursive(EYE, field{:}, true)];
            end

            col_names = {};
            for non_header_field = {'gaze' 'pupil' 'times' 'datalabel'} % Add interstices back
                col_names = [col_names get_fields_recursive(EYE, non_header_field{:}, false)];
            end

            all_data = [];
            for col = col_names
                curr_fields = regexp(col{:}, '\.', 'split');
                curr_data = getfield(EYE, curr_fields{:});
                all_data = [all_data num2cell(curr_data(:))];
            end

            header = header_lines;
            contents = [
                col_names
                all_data
            ];

            writecell2delim(full_path, contents, sprintf('\t'), header{:});
        end
        %% Write events?
        if any(type_ctrl == 'e')
            col_names = fieldnames(EYE.event);
            col_names = col_names(~strcmp(col_names, 'uniqid'));
            col_names = col_names(:)';
            contents = [];
            for col_name = col_names
                curr_col = {EYE.event.(col_name{:})};
                contents = [contents curr_col(:)];
            end
            event_table = [
                col_names
                contents
            ];
            [p, f] = fileparts(full_path);
            events_path = fullfile(p, sprintf('%s.csv', f));
            writecell2delim(events_path, event_table, ',');
        end
    case {'r' 'read'}
        EYE = [];
        %% Read timeseries data?
        if any(type_ctrl == 'c')
            [raw, h] = readdelim2cell(full_path, '\t');
            for hline = h(:)'
                field_val = regexp(hline{:}, ':', 'split');
                fields = regexprep(field_val{1}, ' ', '');
                fields = regexp(fields, '\.', 'split');
                EYE = setfield(EYE, fields{:}, eval(field_val{2}));
            end
            col_names = raw(1, :);
            for colidx = 1:numel(col_names)
                curr_dat = raw(2:end, colidx);
                if isnan(str2double(curr_dat{1}))
                    curr_dat = [curr_dat{:}];
                else
                    curr_dat = cellstr2num(curr_dat);
                end
                curr_dat = curr_dat(:)';
                curr_fields = col_names{colidx};
                curr_fields = regexp(curr_fields, '\.', 'split');
                EYE = setfield(EYE, curr_fields{:}, curr_dat);
            end
        end
        %% Read event data?
        if any(ctrl == 'e')
            EYE.event = [];
            [p, f] = fileparts(full_path);
            events_path = fullfile(p, sprintf('%s.csv', f));
            if exist(events_path, 'file')
                raw = readdelim2cell(events_path, ',');
                col_names = raw(1, :);
                for colidx = 1:numel(col_names)
                    curr_dat = raw(2:end, colidx);
                    if isnan(str2double(curr_dat{1}))
                        curr_dat = [curr_dat{:}];
                    else
                        curr_dat = cellstr2num(curr_dat);
                    end
                    curr_dat = num2cell(curr_dat(:)');
                    curr_field = col_names{colidx};
                    [EYE.event.(curr_field)] = curr_dat{:};
                end
            end
        end
        varargout{1} = EYE;
end

end

function fields = get_fields_recursive(s, fname, getbottom)

fields = {};

f = s.(fname);
if isstruct(f) && numel(f) == 1
    sub_fnames = fieldnames(f);
    for sub_fname = sub_fnames(:)'
        new_lines = get_fields_recursive(f, sub_fname{:}, getbottom);
        fields = [fields strcat(fname, '.', new_lines)];
    end
else
    curr_line = fname;
    if getbottom
        curr_line = sprintf('%s: %s', curr_line, all2str(f));
    end
    fields{end + 1} = curr_line;
end

end