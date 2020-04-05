% Command history:

%% Preparing the data
% Removing the right eye
eye_data = pupl_feval(@pupl_rmeye, eye_data, 'which', 'right');
% Concatenating the recordings
eye_data = pupl_feval({@pupl_cat}, eye_data, 'sel', {{1 'b1'} {1 'b2'} {1 'b3'} {1 'b4'} {1 'b5'} {1 'b6'}}, 'ev_suffix', {'' '' '' '' '' ''}, 'rec_suffix', {'_b2_b3_b4_b5_b6'});

%% Processing the continuous data
% Trimming pupil size 0 samples
eye_data = pupl_feval(@pupl_trim_pupil, eye_data, 'lims', {'200' 'inf'});
% Idenntifying blinks
eye_data = pupl_feval(@pupl_blink_id, eye_data, 'method', 'missing', 'overwrite', true, 'cfg', struct('min', {'50ms'}, 'max', {'1s'}));
% Trimming blink samples
eye_data = pupl_feval(@pupl_blink_rm, eye_data, 'trim', '200ms');
% Interpolating missing data
eye_data = pupl_feval(@pupl_interp, eye_data, 'data', 'pupil', 'interptype', 'linear', 'maxlen', '1.2s', 'maxdist', '3`sd');
% Filtering the data
eye_data = pupl_feval(@pupl_filt, eye_data, 'data', 'pupil', 'win', 'hann', 'avfunc', 'mean', 'width', '150ms', 'cfg', []);
% Downsample
eye_data = pupl_feval(@pupl_downsample, eye_data, 'fac', 50);

%% Working with trials
% Reading the number of false alarms
eye_data = pupl_feval(@pupl_evar_read, eye_data, 'method', 're', 'sel', {1 'Response'}, 'expr', 'FA=(\d+)', 'var', {'FA'}, 'type', {'Numeric'});
% Reading the number of hits
eye_data = pupl_feval(@pupl_evar_read, eye_data, 'method', 're', 'sel', {1 'Response'}, 'expr', 'Hit=(\d)/(\d)', 'var', {'n_hits' 'max_hits'}, 'type', {'Numeric' 'Numeric'});
% Computing the hit rate
eye_data = pupl_feval(@pupl_evar_read, eye_data, 'method', 'evar', 'sel', {1 'Response'}, 'expr', '#n_hits / #max_hits', 'var', {'HR'}, 'type', {'Numeric'});
% Homogenizing event variables within trials
eye_data = pupl_feval(@pupl_evar_hg, eye_data, 'onsets', {1 'Scene'}, 'ends', {1 'Response'});
% Epoching
eye_data = pupl_feval(@pupl_epoch, eye_data, 'timelocking', {1 'Scene'}, 'lims', {'0s';'29.5s'}, 'overwrite', []);
% Baseline correction
eye_data = pupl_feval(@pupl_baseline, eye_data, 'correction', 'subtract baseline mean', 'event', 0, 'lims', {'4s';'4.5s'}, 'mapping', 'one:one');
% Epoch rejection
eye_data = pupl_feval(@pupl_epoch_reject, eye_data, 'method', 'event', 'cfg', struct('sel', {{2 '#HR < 1 | #FA > 1'}}));
% Defining epoch sets
eye_data = pupl_feval(@pupl_epochset, eye_data, 'setdescriptions', struct('name', {'Easy' 'Medium' 'Hard'}, 'members', {{1 'Scene1'} {1 'Scene2'} {1 'Scene3'}}), 'overwrite', true, 'verbose', true);
