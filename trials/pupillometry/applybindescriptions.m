function EYE = applybindescriptions(EYE, binDescriptions)

%  Inputs
% EYE--struct array
% binDescriptions--struct array
%  Outputs
% EYE--struct array
%  Description
% Adds a field to EYE called bin, which is a struct array. The data in each
% element of EYE.bin is a numerical array of dimension (n. trials x trial
% length)--I.e., each row 

for dataidx = 1:numel(EYE)
    fprintf('Merging trials from %s...\n', EYE(dataidx).name);
    if ~isfield(EYE(dataidx), 'bin')
        EYE(dataidx).bin = [];
    else
        if ~isempty(EYE(dataidx).bin)
            EYE(dataidx).bin = EYE(dataidx).bin(:)';
        end
    end
    for binIdx = 1:numel(binDescriptions)
        binMembers = find(ismember({EYE(dataidx).epoch.name},...
            binDescriptions(binIdx).epochs));
        currBin = struct('name', binDescriptions(binIdx).name,...
            'data', [],...
            'relLatencies', EYE(dataidx).epoch(binMembers(1)).relLatencies);
        dataStreams = fieldnames(EYE(dataidx).epoch(1).diam);
        for stream = dataStreams(:)'
            currBin.data.(stream{:}) = [];
            for binMemberIdx = binMembers
                % Same relative location of defining event?
                if ~all(currBin.relLatencies == EYE(dataidx).epoch(binMemberIdx).relLatencies)
                    warning('You are combining epochs into a bin that do not all begin and end at the same time relative to their events');
                    currBin.relLatencies = [];
                end
                if ~EYE(dataidx).epoch(binMemberIdx).reject
                    currData = [EYE(dataidx).epoch(binMemberIdx).diam.(stream{:})];
                    currBin.data.(stream{:}) = cat(1, currBin.data.(stream{:}), currData(:)');
                end
            end
        end
        fprintf('\tTrial set ''%s'' contains data from %d trials\n', binDescriptions(binIdx).name, nnz(~[EYE(dataidx).epoch(binMembers).reject]))
        EYE(dataidx).bin = [EYE(dataidx).bin currBin];
    end
end

fprintf('Done\n');

end