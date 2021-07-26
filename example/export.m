
% Get path to example folder
global pupl_globals
eg_path = fullfile(pupl_globals.pupl_root, 'example');

% Export basic stats
pupl_export(eye_data, 'which', 'stats', 'cfg', struct('name', {'trial'}, 'win', {{'4s';'29s'}}, 'stats', {{'Mean'}}, 'statsnames', {{'mean'}}), 'trialwise', 'Analyze epoch set averages', 'path', fullfile(eg_path, 'stats-basic.csv'), 'lw', []);

% Export for mixed effects analysis
pupl_export(eye_data, 'which', 'stats', 'cfg', struct('name', {'trial'}, 'win', {{'4s';'29s'}}, 'stats', {{'Mean'}}, 'statsnames', {{'mean'}}), 'trialwise', 'Analyze individual epochs (e.g. for mixed effects models)', 'path', fullfile(eg_path, 'stats-long.csv'), 'lw', []);

% Export long-format downsampled data
pupl_export(eye_data, 'which', 'downsampled', 'cfg', struct('start', {''}, 'width', {'500ms'}, 'step', {''}, 'end', {''}), 'trialwise', 'Analyze epoch set averages', 'path', fullfile(eg_path, 'ds-long.csv'), 'lw', 'long');
