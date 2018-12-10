function EYE = applyepochdescriptions(EYE, epochDescriptions)

% Adds 'epoch' field to EYE structs
%   Inputs
% EYE--struct array
% epochDescriptions--struct array
% rejection threshold--number from 0 to 1
%   Outputs
% EYE--struct array

for dataIdx = 1:numel(EYE)
    fprintf('Epoching %s...\n', EYE(dataIdx).name)
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
    fprintf('\t%d trials created\n', numel(EYE(dataIdx).epoch))
end

end