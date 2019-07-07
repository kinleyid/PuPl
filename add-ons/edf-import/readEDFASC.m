function result=readEDFASC(fname, readPos, automatic)
% result=readEDFASC(fname, readPos, automatic)
% Read an EDF file or an ASC file.
% 1) If filename ends with '.edf' (case sensitive), run edf2asc - this needs to
%    be on the path!
% 2) Open resulting '.asc' file (or the specified '.asc' file) and read the
%    data. If readPos is 1, then store all the eye location points in an
%    array called 'pos'.
% 3) Saccade events translated into [startTime endTime duration startX startY endX
%    endY ? ?]
% 4) Fixation events translated into [startTime endTime duration avX avY ?]
% 5) MSG events recorded: first word (message name) becomes a fieldname in the
%    structure, appended with _m (a string containing the message) or _t
%    (the time of the message).
if exist('automatic')~=1, automatic=0;end;
if fname(end-3)=='.'
    fstem=fname(1:end-4);
else
    fstem=fname;
end;

rehash path % why
if exist([fstem '.asc'])
    fname=[fstem '.asc'];
    fprintf('using existing asc file %s\n',fname);
elseif exist([fstem '.edf'])
    fname=[fstem '.edf'];
end

if(fname(end-3:end)=='.edf')
    fprintf('running edf2asc on %s...', fname);
    fname2=[fname(1:end-4) '.asc'];
    
    [err,tmp]=dos(['edf2asc ' fname], '-echo');
    if err==1
      [status result]=system([getExperimentBase() '/Eyelink/edf2asc ' fname '&'])
    end
    rehash path
    if ~exist(fname2)  % error reading file
      fprintf(tmp); fprintf('\n error reading edf\n'); 
      result=struct();return;
    end;
    disp(tmp);
else fname2=fname;
end

[fid mess]=fopen(fname2, 'r');
if(fid==-1) error(mess);end;
line=0; trial=1; trialstart=0;
nancount=0; maxnans=3000; %max 3 seconds blink recorded.
if ~exist('readPos') readPos=1;end;
try
    skipToNextLineStartingWith(fid, 'START'); token='START'; % Run tape til next instance of "START"
    while ~feof(fid)
        if strcmp(token,'MSG') % If a message:
            t = fscanf(fid, '%d',1);
            msg = fscanf(fid, '%s',1);
            val = fgets(fid); %remainder of line
            if(msg=='B')
                tmp=find(val==':');
                if ~isempty(tmp) 
                    [msg,tmp2,tmp2,tmp2]=sscanf(val(tmp+1:end),'%s',1);
                    val=val((tmp+tmp2):end);
                else
                    [result(trial).B tmp tmp tmp]= sscanf(val,'%d',1);
                    [result(trial).T tmp tmp tmp]= sscanf(val((tmp+2):end),'%d',1);
                    msg='BT';
                end
            end;
            fn = removeNonalphanumericChars(msg);
            val(uint8(val)<31)=[]; % remove control characters from message
            try
                result(trial).([fn '_m']) = val;
                result(trial).([fn '_t']) = t-trialstart;
            end
        elseif strcmp(token,'START')
            trial=trial+1;
            result(trial).pos=[]; result(trial).fixation=[]; result(trial).saccade=[];
            result(trial).blink=[];
            trialstart=fscanf(fid,'%d',1);
            fprintf('\rTrial %d   ',trial);
        elseif readPos & any(token(1)=='0123456789') % If token contains a number,
            t=fscanf(fid,'%g',3)'; time=str2num(token)-trialstart ;
            if length(t)==3 % How could it not be?
                result(trial).pos = [result(trial).pos; time, t ] ;
                nancount=0;
            else
                if(nancount<maxnans)
                    result(trial).pos = [result(trial).pos; time NaN NaN NaN];
                elseif nancount==maxnans
                    fprintf('?blink?');
                end;
                nancount=nancount+1;
            end;
            fgets(fid); %gobble rest of line
        elseif strcmp(token,'EFIX')
            tmp=fscanf(fid,'%s',1); t=fscanf(fid,'%g',6)';
            result(trial).fixation=[result(trial).fixation; t - [trialstart trialstart 0 0 0 0]];
            fprintf('f');
        elseif strcmp(token,'ESACC')
            tmp=fscanf(fid,'%s',1); t=fscanf(fid,'%g',9)';
            if length(t)==9
                result(trial).saccade=[result(trial).saccade; t - [trialstart trialstart 0 0 0 0 0 0 0]];
            else
                fprintf(['?']); disp(t);
            end;
            fprintf('s');
        elseif strcmp(token, 'EBLINK')
            tmp=fscanf(fid,'%s',1); t=fscanf(fid,'%g',3)';
            result(trial).blink  =[result(trial).blink; t - [trialstart trialstart 0]];
            fprintf('B');
        else
            fgets(fid); %gobble
        end
        %[z z kcode]=KbCheck;
        %if kcode(27) break;end;
        token=fscanf(fid, '%s',1); % Get next token
    end
    if~(prod(size(result(1).pos)))result(1)=[]; end;%remove single initial blank trial
    if isfield(result(1), 'VOID_TRIAL_t')
        n=sum([result.VOID_TRIAL_t]>0);
        if ~automatic
            if(input(['Delete ' num2str(n) ' void trials? (1/0)'])) 
                result([result.VOID_TRIAL_t]>0)=[];
            end;
        end;
    end;

catch
    e=lasterror;
    fprintf('%s\nin %s\nline %d\n',e.message, e.stack(1).file, e.stack(1).line);
end
fclose(fid);
if(~automatic)
    if input(['Delete ' fname2 '? (1/0)']) delete(fname2);end;
end;

end

function skipToNextLineStartingWith(fid, str)
    token = ''; pass=1;
    while ~feof(fid) & pass
        token=fscanf(fid, '%s',1);
        if strcmp(token,str) pass=0; break;
        else fgets(fid);  %gobble
        end;
    end;
end

function str=removeNonalphanumericChars(str)
% Remove all characters that are not alphanumeric, . or _,  and remove 
% any initial digits.
% useful for making field names or variable names.
    i=1;
    while i<=length(str)
        if any(str(i)=='_.') i=i+1;continue; end;
        if str(i)<65 | (str(i)>90 & str(i)<97) | str(i)>122 ...
                | (i==1 & str(i)>47 & str(i)<58)
            str=[ str(1:i-1)  str(i+1:end) ];
        else i=i+1;
        end
    end;
end