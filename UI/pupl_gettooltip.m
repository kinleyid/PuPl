
function txt = pupl_gettooltip(elem)
% Get tool tip string

line_width = 50; % Characters
split_lines = true;
switch elem
    case 'regexp:edit'
        txt = sprintf('Enter a regular expression to select items from the list above. After writing a regular expression, press Enter to highlight the items that match it. You can learn about regular expressions by:\n1) going to PuPl''s Help menu\n2) typing "help regexp" into the Command Window');
    case 'regexp:button'
        txt = 'Click this button to select the items matched by the regular expression in the text box above. To see which items match the current regular expression, click the text box above and then press Enter.';
    case 'eventvar:edit'
        txt = 'Enter an event variable filter to select events from the list. For example, if you have computed reaction times, you can select events where the reaction time was less than 100ms using "#rt < 0.1"';
    case 'eventvar:button'
        txt = 'Click this button to select the items matched by the regular expression in the text box above. To see which items match the current regular expression, click the text box above and then press Enter.';
    case 'highlighted:button'
        txt = sprintf('Click this button to select the currently highlighted items. Note: this operation will be logged in the processing history such that, if you were to rerun the pipeline, only the particular highlighted values would be selected. This may make your processing pipeline less reusable.');
    case 'datastr'
        shorthands = {
            '`mu' 'mean'
            '`md' 'median'
            '`mn' 'min'
            '`mx' 'max'
            '`sd' 'standard deviation'
            '`vr' 'variance'
            '`iq' 'interquartile range'
            '`madv' 'median absolute deviation'
            'n%' 'nth percentile'
            'f($)' 'function f() applied to data'
        }';
        txt = [sprintf('You can use shorthands for statistical quantities here:\n\n') sprintf('%s: %s\n', shorthands{:})];
        split_lines = false;
end

if split_lines
    proc_txt = {};
    curr_n_chars = 0;
    last_space_idx = NaN;
    last_split_idx = 1;
    for char_idx = 1:numel(txt)
        curr_n_chars = curr_n_chars + 1;
        switch txt(char_idx)
            case sprintf('\n')
                curr_n_chars = 0;
            case ' '
                if curr_n_chars > line_width
                    if ~isnan(last_space_idx)
                        proc_txt{end + 1} = sprintf('%s\n', txt(last_split_idx:last_space_idx-1));
                        last_split_idx = last_space_idx + 1;
                        curr_n_chars = 0;
                    end
                end
                last_space_idx = char_idx;
        end
    end
    proc_txt{end + 1} = txt(last_split_idx:end);
    txt = [proc_txt{:}];
end

end