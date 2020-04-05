
% Change this variable based on where you unzipped the Git repo
proj_path = fullfile('C:', 'Users', 'isaac', 'Projects', 'pupl-worked-example');

exp_path = fullfile(proj_path, 'export');

% Export for standard analysis
pupl_export_new(eye_data, 'which', 'stats', 'cfg', struct('name', {'trial'}, 'win', {{'4.5s';'29.5s'}}, 'stats', {{'Mean'}}, 'statsnames', {{'mean'}}), 'trialwise', 'Analyze epoch set averages', 'path', fullfile(exp_path, 'stats-basic.csv'), 'lw', [])

% Export for mixed effects analysis
pupl_export_new(eye_data, 'which', 'stats', 'cfg', struct('name', {'trial'}, 'win', {{'4.5s';'29.5s'}}, 'stats', {{'Mean'}}, 'statsnames', {{'mean'}}), 'trialwise', 'Analyze individual epochs (e.g. for mixed effects models)', 'path', fullfile(exp_path, 'stats-long.csv'), 'lw', [])

% Export long-format downsampled data
pupl_export_new(eye_data, 'which', 'downsampled', 'cfg', struct('start', {'0s'}, 'width', {'500ms'}, 'step', {''}, 'end', {'29.5s'}), 'trialwise', 'Analyze epoch set averages', 'path', fullfile(exp_path, 'ds-long.csv'), 'lw', 'long')
