function Description = DescribeEpoch(Epoch)

if strcmp(Epoch.EpochType,'Length of time relative to events')
    Description = sprintf('From %.3f seconds before instance %d of %s to %.3f seconds after',Epoch.Lims(1),Epoch.InstanceN,Epoch.EventType{:},Epoch.Lims(2));
elseif strcmp(Epoch.EpochType,'Between events')
    Description = sprintf('From %.3f seconds before instance %d of %s to %.3f seconds after instance %d of %s',Epoch.Lims(1),Epoch.InstanceN(1),Epoch.EventType{1},Epoch.Lims(2),Epoch.InstanceN(2),Epoch.EventType{2});
else
    Description = 'Someone needs to complete the function DescribeEpoch';
end