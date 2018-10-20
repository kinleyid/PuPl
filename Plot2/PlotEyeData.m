function PlotEyeData

uiwait(msgbox('Select eye data with bin info to plot from'));
figure; hold on
BinIdx = [];
LegendEntries = {};
PlotNames = {};
while true
    if exist('Path','var')
        [Filename,Path] = uigetfile([Path '\*.mat'],...
            'Select the eye data to plot');
    else
        [Filename,Path] = uigetfile('..\..\..\*.mat',...
            'Select the eye data to plot');
    end
    MatData = load([Path '\' Filename]);
    EYE = MatData.EYE;
    if ~isfield(EYE,'bins')
        Question = 'No bins found; will abort';
        uiwait(msgbox(Question));
        error('No bins found')
    end
    if ~isfield(EYE.bins(1).data,'both')
        Question = 'No merged left and right streams found; will abort';
        uiwait(msgbox(Question));
        exit
    end
    BinDescriptions = [EYE.bins.description];
    BinNames = {BinDescriptions.name};
    BigIdx = listdlg('ListString',BinNames,...
                'PromptString','Plot from which bin?');
    for i = 1:length(BigIdx)
        Idx = BigIdx(i);
        RGB = inputdlg({'Red saturation (0 to 1)' 'Green saturation (0 to 1)' 'Blue saturation (0 to 1)'},...
                       sprintf('Colours for bin %s',BinNames{Idx}),1,...
                       cellstr(num2str(rand(3,1)))');
        Colour = [str2double(RGB{1}) str2double(RGB{2}) str2double(RGB{3})];
        BinIdx = [BinIdx Idx];
        Average = mean(EYE.bins(Idx).data.both,'omitnan');
        PWSEM = std(EYE.bins(Idx).data.both,[],1,'omitnan')/sqrt(size(EYE.bins(Idx).data.both,1));
        t = (1:size(EYE.bins(Idx).data.both,2))/EYE.srate;
        % Plot but don't register to determine plot limits
        plot(t,Average,'Color',Colour,'HandleVisibility','Off')
        plot(t,Average+PWSEM,':','Color',Colour,'HandleVisibility','Off')
        plot(t,Average-PWSEM,':','Color',Colour,'HandleVisibility','Off')
        xlabel('Time (s)');
        ylimits = ylim;
        % plot([0 0],ylim,'k','HandleVisibility','Off');
        ylim(ylimits)
        xlimits = xlim;
        plot(xlimits,[0 0],'k','HandleVisibility','Off');
        xlim(xlimits);
        % Plot with proper plot limits
        plot(t,Average,'Color',Colour)
        plot(t,Average+PWSEM,':','Color',Colour,'HandleVisibility','Off')
        plot(t,Average-PWSEM,':','Color',Colour,'HandleVisibility','Off')
        xlim(xlimits);
        ylim(ylimits);
        Answer = inputdlg('Name in legend:');
        PlotNames = [PlotNames Answer{:}];
        for j = 1:length(PlotNames)
            LegendEntries(j) = {[PlotNames{j} ' \pm pointwise SEM']};
        end
        legend(LegendEntries);
    end
    AnotherOne = questdlg('Another plot?',...
        'Another plot?',...
        'Yes','No','Yes');
    if strcmp(AnotherOne,'No')
        %{
        BinDescriptions = [EYE.bins(BinIdx).description];
        LegendEntries = {BinDescriptions.name};
        for j = 1:length(LegendEntries)
            LegendEntries(j) = {[LegendEntries{j} ' \pm pointwise SEM']};
        end
        legend(LegendEntries);
        %}
        break
    end
end