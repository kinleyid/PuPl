function out = pupl_mergelr(EYE)

if nargin == 0
    out = @()[];
else
    EYE.pupil.both = mergelr(EYE);
    out = EYE;
end

end