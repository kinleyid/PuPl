
function epochs = epoch_(EYE, timelocking, lims, other, span_name)

if isnumeric(timelocking)
    % Select by uniqid
    timelocking_idx = find(ismember([EYE.event.uniqid], timelocking));
else
    % Select by event filter
    timelocking_idx = find(pupl_event_sel(EYE.event, timelocking));
end
timelocking_times = [EYE.event(timelocking_idx).time];
% Candidate epoch ends
cand_other_idx = find(pupl_event_sel(EYE.event, other.event));
cand_other_times = [EYE.event(cand_other_idx).time];
other_idx = nan(size(timelocking_idx));
for t_idx = 1:numel(timelocking_times)
    curr_t_lat = timelocking_times(t_idx);
    switch other.when
        % Err on the size of making epochs as short as possible
        case 'before'
            o_idx = find(cand_other_times <= curr_t_lat, 1, 'last'); % Find latest start event
        case 'after'
            o_idx = find(cand_other_times >= curr_t_lat, 1); % Find earliest end event
    end
    if isempty(o_idx)
        switch other.when
            case 'before'
                doing = 'starting';
            case 'after'
                doing = 'ending';
        end
        curr_t = EYE.event(timelocking_idx(t_idx));
        error('No %s-%s event occurs %s timelocking event %s (at %f seconds)',...
            span_name,...
            doing,...
            other.when,...
            curr_t.name,...
            curr_t.time)
    else
        other_idx(t_idx) = cand_other_idx(o_idx);
    end
end

currlims = EYE.srate * parsetimestr(lims, EYE.srate);
timelocking_lats = pupl_event_getlat(EYE, timelocking_idx);
other_lats = pupl_event_getlat(EYE, other_idx);
switch other.when
    case 'before'
        abs_lims = [
            other_lats + currlims(1)
            timelocking_lats + currlims(2)
        ];
    case 'after'
        abs_lims = [
            timelocking_lats + currlims(1)
            other_lats + currlims(2)
        ];
end

is_out = [abs_lims(1, :) < 1; abs_lims(2, :) > EYE.ndata];
if any(is_out(:))
    bad_epoch_idx = find(sum(is_out, 1) > 0, 1);
    switch other.when
        case 'before'
            start_ev = EYE.event(other_idx(bad_epoch_idx));
            end_ev = EYE.event(timelocking_idx(bad_epoch_idx));
        case 'after'
            end_ev = EYE.event(other_idx(bad_epoch_idx));
            start_ev = EYE.event(timelocking_idx(bad_epoch_idx));
    end
    error_txt = {
        sprintf('%s%s %d would be defined from:', upper(span_name(1)), span_name(2:end),  bad_epoch_idx)
        sprintf('\t(%s): %fs + [%s]', start_ev.name, start_ev.time, lims{1})
        'to:'
        sprintf('\t(%s): %fs + [%s]', end_ev.name, end_ev.time, lims{2})
        'Which would reach outside the boundaries of the recording, which only lasts from:'
        sprintf('\t%fs', EYE.times(1))
        'to:'
        sprintf('\t%fs', EYE.times(end))
    };
    error('%s\n', error_txt{:});
end

epochs = struct(...
    'lims', {lims},...
    'event', {EYE.event(timelocking_idx).uniqid},...
    'other', num2cell(...
        struct(...
            'event', {EYE.event(other_idx).uniqid},...
            'when', other.when)));

end