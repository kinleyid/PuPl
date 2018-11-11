function EYE = getfakeeyedata

events = struct('type','Event', 'time', 1000);
events(2) = struct('type', 'Event', 'time', 2000);
events(3) = struct('type', 'Event', 'time', 3000);
events(4) = struct('type', 'Event', 'time', 4000);

% Fake data
gt = 10*rand(1,10000);
EYE = struct('name', 'Fake eye data',...
    'srate', 100,...
    'data', struct(...
        'left', gt + rand(size(gt)),...
        'right', gt + rand(size(gt))),...
    'event', events);
EYE.urData = EYE.data;

end