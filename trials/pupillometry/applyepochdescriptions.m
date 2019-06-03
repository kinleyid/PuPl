function EYE = applyepochdescriptions(EYE, epochDescriptions)

% Adds 'epoch' field to EYE structs
%   Inputs
% EYE--struct array
% epochDescriptions--struct array
%   Outputs
% EYE--struct array

fprintf('Epoching...\n')

for dataIdx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataIdx).name)
    if ~isfield(EYE(dataIdx), 'epoch')
        EYE(dataIdx).epoch = [];
    else
        EYE(dataIdx).epoch = reshape(EYE(dataIdx).epoch, 1, []);
    end
    for epochIdx = 1:numel(epochDescriptions)
        spans = getlatenciesfromspandescription(EYE(dataIdx),...
            epochDescriptions(epochIdx));
        for spanIdx = 1:numel(spans)
            currEpoch = struct(...
                'description', epochDescriptions(epochIdx),...
                'latencies', spans{spanIdx},...
                'name', epochDescriptions(epochIdx).name,...
                'reject', false);  
            for stream = reshape(fieldnames(EYE(dataIdx).diam), 1, [])
                currEpoch.diam.(stream{:}) = EYE(dataIdx).diam.(stream{:})(currEpoch.latencies);
            end
            EYE(dataIdx).epoch = [EYE(dataIdx).epoch currEpoch];
        end
    end
    fprintf('%d trials created\n', numel(EYE(dataIdx).epoch))
end

fprintf('Done\n')

end