function correctionFactor = PFEcostheta(c, Tx, Ty)

Tx = Tx - c.Tx0;
Ty = Ty - c.Ty0;

correctionFactor = (c.Cx*Tx + c.Cy*Ty + c.Cz*c.Tz)...
            / sqrt(c.Cx^2 + c.Cy^2 + c.Cz^2)...
            ./ sqrt(Tx.^2 + Ty.^2 + c.Tz^2);

end