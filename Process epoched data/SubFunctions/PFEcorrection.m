
% see:  Hayes & Petrov. (2016). Behaviour Research Methods, 48, 510-517.
% --> describes this correction method, etc.
% --> pupil off-axis error = sqrt( cos( camera-eye-target angle) )
% --> calculate this, and then correct raw pupil diameter data for it
%
% Set these variables for the experiment tracker setup - measure them!...
% RELATIVE TO PUPIL (0,0,0) x y z coordinates...
% ALL VALUES are in millimeters (mm)...

disp('Correct data for pupil-camera angle error (PFE)...');

%screen top left pixel from eyes. - NEED TO MEASURE AND SET THESE!!!
Sx = -169; % -160;  % make half of screen width (everything centered
Sy = 0; % 100; % eyes close to top of screen
Sz = 600; % 450;

%camera x y z location, relative to pupil/eye - MEASURE AND SET THESE!!!
Cx = 0;
Cy = -270; %-250;
Cz = 510; %400;

% eye to target distance - assume this is same as screen distance
Tz = Sz;  

% screen is 1024 x 768; need to convert to mm sizes - MEASURE!
% approximate for right now:
%-->  approx 13.33 x 10 inches
%--> approx 338 x 254 mm

screen_width_mm = 338;  % MEASURE AND SET THESE!!!
screen_height_mm = 270;  %254;

x_pix_to_mm = screen_width_mm / 1024;
y_pix_to_mm = screen_height_mm / 768;

% set max limit for angle correction...
% 45deg camera-eye-target = 0.84 error; 50deg = 0.80; more is too weird?
% PFEerror = sqrt( cos(camera-eye-target angle) ) 
PFE_limit = 0.8;  % set pupil data to NAN if less, below...


% Tx and Ty we calculate per sample from raw pupil data
% Tx = Sx + gazeX in mm
% Ty = Sy - gazeY in mm

% calculate gaze x y in pupil(0,0) coordinates, in millimetres...
gaze_data_X_raw = gaze_data_X_v1(1:end);
gaze_data_Y_raw = gaze_data_Y_v1(1:end);
gaze_data_Tx = gaze_data_X_raw;  % we will overwrite these in a sec...
gaze_data_Ty = gaze_data_Y_raw;

for i = 1:length(gaze_data_X_v1)
    if gaze_data_X_raw(1,i) == 0 || gaze_data_Y_raw(1,i) == 0
        gaze_data_Tx(1,i) = NaN;
        gaze_data_Ty(1,i) = NaN;
    else
        gaze_data_Tx(1,i) = Sx + (gaze_data_X_raw(1,i) * x_pix_to_mm);
        gaze_data_Ty(1,i) = Sy - (gaze_data_Y_raw(1,i) * y_pix_to_mm);
    end;
end;

% calculate pupil foreshortening measurement error due to gaze position...
PFE_error = zeros(1,length(gaze_data_X_v1));

for i = 1:length(gaze_data_X_v1)
    numer1 = (Cx * gaze_data_Tx(1,i)) + (Cy * gaze_data_Ty(1,i)) + (Cz * Tz);
    denom1 = sqrt( (Cx * Cx) + (Cy * Cy) + (Cz * Cz) ) * sqrt( (gaze_data_Tx(1,i) * gaze_data_Tx(1,i)) + (gaze_data_Ty(1,i) * gaze_data_Ty(1,i)) + (Tz * Tz) );
    PFE_error(1,i) = sqrt( (numer1 / denom1) );
end;

% correct LEFT pupil diameter values based on calculated PFE for each sample...
for i = 1:length(pupil_data_Left_v1)
    if isnan(pupil_data_Left_v1(1,i)) || isnan(gaze_data_Tx(1,i)) || isnan(gaze_data_Ty(1,i))
        % don't do anything if NaN        
    elseif PFE_error(1,i) < PFE_limit
        pupil_data_Left_v1(1,i) = NaN;  % exclude too high correction trials
    else
        pupil_data_Left_v1(1,i) = pupil_data_Left_v1(1,i) / PFE_error(1,i);
    end;
end;

% correct RIGHT pupil diameter values based on calculated PFE for each sample...
for i = 1:length(pupil_data_Right_v1)
    if isnan(pupil_data_Right_v1(1,i)) || isnan(gaze_data_Tx(1,i)) || isnan(gaze_data_Ty(1,i))
        % don't do anything if NaN
    elseif PFE_error(1,i) < PFE_limit
        pupil_data_Right_v1(1,i) = NaN; % exclude too high correction trials
    else
        pupil_data_Right_v1(1,i) = pupil_data_Right_v1(1,i) / PFE_error(1,i);
    end;
end;