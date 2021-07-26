% Command history:

%% Preparing the data
% Removing the right eye
eye_data = pupl_feval(@pupl_rmeye, eye_data, 'which', 'right');
% Concatenating the recordings
eye_data = pupl_feval({@pupl_cat}, eye_data, 'sel', {{1 'b1'} {1 'b2'} {1 'b3'} {1 'b4'} {1 'b5'} {1 'b6'}}, 'ev_suffix', {'' '' '' '' '' ''}, 'rec_suffix', {'_b2_b3_b4_b5_b6'});

%% Processing the continuous data
% Identify blinks
eye_data = pupl_feval(@pupl_blink_id, eye_data, 'method', 'noise', 'overwrite', true, 'cfg', []);
% Trim blink samples and blink-adjacent samples
eye_data = pupl_feval(@pupl_blink_rm, eye_data, 'trim', {'50ms';'150ms'});
% Interpolate across resulting gaps
eye_data = pupl_feval(@pupl_interp, eye_data, 'data', 'pupil', 'interptype', 'linear', 'maxlen', '600ms', 'maxdist', '1`sd');
% Filter out high frequencies
eye_data = pupl_feval(@pupl_filt, eye_data, 'data', 'pupil', 'avfunc', 'mean', 'win', 'hann', 'width', '150ms', 'cfg', []);
% Downsample
eye_data = pupl_feval(@pupl_downsample, eye_data, 'fac', 50);

%% Processing the event data
% Read the number of false alarms
eye_data = pupl_feval(@pupl_evar_add, eye_data, 'method', 're', 'sel', {1 'Response'}, 'expr', 'FA=(\d+)', 'var', {'FA'}, 'type', {'numeric'});
% Read the number of hits and the max. hits
eye_data = pupl_feval(@pupl_evar_add, eye_data, 'method', 're', 'sel', {1 'Response'}, 'expr', 'Hit=(\d+)/(\d+)', 'var', {'n_hits' 'max_hits'}, 'type', {'numeric' 'numeric'});
% Compute the hit rate
eye_data = pupl_feval(@pupl_evar_add, eye_data, 'method', 'evar', 'sel', {1 'Response'}, 'expr', '#n_hits/#max_hits', 'var', {'HR'}, 'type', {'numeric'});
% Homogenizing event variables within trials
eye_data = pupl_feval(@pupl_evar_hg, eye_data, 'onsets', {1 'Scene'}, 'ends', {1 'Response'}, 'idx', true);

%% Defining epochs
% Initial epoch definition
eye_data = pupl_feval(@pupl_epoch, eye_data, 'len', 'fixed', 'timelocking', {1 'Scene'}, 'lims', {'0';'29'}, 'other', struct('when', {'after'}, 'event', {0}), 'overwrite', false, 'name', 'trial');
% Baseline correction
eye_data = pupl_feval(@pupl_baseline, eye_data, 'epoch', {0}, 'correction', 'subtract baseline mean', 'mapping', 'one:one', 'len', 'fixed', 'when', 0, 'timelocking', 0, 'lims', {'3.5s';'4s'}, 'other', struct('event', {0}, 'when', {'after'}));
% Epoch rejection
eye_data = pupl_feval(@pupl_epoch_reject, eye_data, 'method', 'event', 'cfg', struct('sel', {{2 '#HR < 1 | #FA >= 2'}}));
% Group epochs by condition
eye_data = pupl_feval(@pupl_epochset, eye_data, 'setdescriptions', struct('name', {'Easy' 'Medium' 'Hard'}, 'members', {{1 'Scene1'} {1 'Scene2'} {1 'Scene3'}}), 'overwrite', true, 'verbose', true);
