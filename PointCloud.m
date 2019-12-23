function PointCloud()

    write_to_board=true; % set to true if it's the first time to run
    cfgFileName = 'profile01.cfg';
    comportUserNum = 3; % standard, for commands
    comportDataNum = 4; % enhanced, for data

    % open config file

    cfgFileId = fopen(cfgFileName,'r');
    if cfgFileId == -1
        fprintf('File %s not found!\n',cfgFileName);
        return
    else
        fprintf('Opening configuration file %s ...\n',cfgFileName);
    end
    cliCfg = [];
    k = 1;
    while true
        cliCmd = fgetl(cfgFileId);
        if ~ischar(cliCmd)
            break
        end
        if cliCmd(1)~='%'
            cliCfg{k} = cliCmd;
            k = k+1;

            if(length(cliCmd)>=10)
                if(all(cliCmd(1:8)=='frameCfg'))
                    cliCmd_split = strsplit(cliCmd,' ');
                    numChirps = str2double(cliCmd_split{1,4});
                elseif(all(cliCmd(1:10)=='profileCfg'))
                    cliCmd_split = strsplit(cliCmd,' ');
                    sampleRate = str2double(cliCmd_split{1,12});
                    freqSlopeConst = str2double(cliCmd_split{1,9});
                    numAdcSamples = str2double(cliCmd_split{1,11});
                    if(numAdcSamples>1024)
                        disp('参数有问题，请降低距离分辨率或减小最大不模糊距离！');
                        return
                    end
                end
            end
        end
    end
    fclose(cfgFileId);

    numRangeBins=2^ceil(log2(numAdcSamples));
    rangeResolution = 3e8 * sampleRate * 1e3 / (2 * freqSlopeConst * ((3.6*1e3*900) / (2^26)) * 1e12 * numRangeBins);
    xyzOutputQFormat = ceil(log2(16 / rangeResolution));
    ONE_QFORMAT=2^xyzOutputQFormat*16;

    % Send Configuration Parameters to Board
    % 释放串口
    port=instrfind('Type','serial');
    if ~isempty(port)
        fclose(port);
        delete(port);  % delete open serial ports.
    end
    % Open CLI port
    spCliHandle = configureCliPort(comportUserNum);

    warning off; % MATLAB: serial:fread:unsuccessfulRead
    timeOut = get(spCliHandle,'Timeout');
    set(spCliHandle,'Timeout',1);

    tStart = tic;
    fprintf(spCliHandle,'sensorStop');
    while true
        fprintf(spCliHandle, ''); 
        temp=fread(spCliHandle,100);
        temp = strrep(strrep(temp,char(10),''),char(13),''); %#ok<*CHARTEN>
        if ~isempty(temp)
            break;
        end
        pause(0.1);
        disp(['waiting for reply... ',num2str(toc(tStart))]);
    end
    set(spCliHandle,'Timeout', timeOut);
    warning on;

    % Send CLI configuration to board
    if write_to_board
        fprintf('Sending configuration to board %s ...\n',cfgFileName);
        for k=2:length(cliCfg)-1 % skip sensorstop and sensorstart
            cliCmd = cliCfg{k};
            fprintf(spCliHandle,cliCmd);
            fprintf('>%s\n',cliCmd);
            radarReply = fscanf(spCliHandle);
            if any(radarReply(1:4)~='Done')
                disp(radarReply);
            end
            pause(0.05);
        end
    end
    figure;
    buffer_size=256;
    data=[];

    xmin=-0.9;
    xmax=0.9;
    ymax=0.9;
    ymin=0.1;
    last_p=[0;0];
    thres=0.2;
    gap=0;
    gap_thres=30;

    disp('Init done!');

    %================================================
    %================================================
    
    % s_idle=0;
    % s_header=1;
    % s_data=2;
    % p_header=0;
    % p_data=0;

    % state=s_idle;
    
    % 释放串口
    port=instrfind('Type','serial');
    if ~isempty(port)
        fclose(port);
        delete(port);  % delete open serial ports.
    end

    % Configure data UART port
    configureSport(comportDataNum);
    spCliHandle = configureCliPort(comportUserNum);

    warning off; % MATLAB: serial:fread:unsuccessfulRead

    fprintf(spCliHandle,'sensorStop');
    radarReply = fscanf(spCliHandle);
    if ~isempty(radarReply)&&any(radarReply(1:4)~='Done')
        disp(radarReply);
    end
    pause(.05);
    fprintf(spCliHandle,'sensorStart');
    fprintf('%s\n','sensorStart');
    radarReply = fscanf(spCliHandle);
    if any(radarReply(1:4)~='Done')
        disp(radarReply);
    end

    while true
        if input('')==1
            break;
        end
    end

    fprintf(spCliHandle,'sensorStop');
    % 释放串口
    port=instrfind('Type','serial');
    if ~isempty(port)
        fclose(port);
        delete(port);  % delete open serial ports.
    end

    function [] = readData(obj,event) %#ok<*INUSD>
        tmp=uint8([data;fread(obj,buffer_size,'uint8')]);
        bsize=numel(tmp);
        data=[];
        pos=1;
        while true
            % find the magic word
            while true
                while tmp(pos)~=0x02
                    pos=pos+1;
                    if pos+7>bsize
                        return;
                    end
                end
                if tmp(pos+1)==0x01&&tmp(pos+2)==0x04&&tmp(pos+3)==0x03&& ...
                    tmp(pos+4)==0x06&&tmp(pos+5)==0x05&&tmp(pos+6)==0x08&&tmp(pos+7)==0x07
                    break;
                end
            end
            len=double(typecast(tmp(pos+(12:15)),'int32'));
            if pos+len+7>bsize % if the data left is not enough, wait for the next time
                data=tmp(pos:end);
                return;
            end
            frame=double(typecast(tmp(pos+(20:23)),'uint32'));
            if typecast(tmp(pos+len+(0:7)),'uint64')~=0x708050603040102
                disp(['Corrupt frame: ',num2str(frame)])
                data=tmp(pos+8:end);
                return;
            end
            points=double(typecast(tmp(pos+(28:29)),'uint16'));
            pos=pos+52;
            ps=double(typecast(tmp(pos+(0:points*12-1)),'int16'));
            xs=ps(4:6:end)./ONE_QFORMAT;
            ys=ps(5:6:end)./ONE_QFORMAT;
            mdis=inf;
            mp=[];
            for l=1:points
                if xs(l)<xmax&&xs(l)>xmin&&ys(l)<ymax&&ys(l)>ymin
                    p=[xs(l);ys(l)];
                    dis=norm(p-last_p);
                    if dis<mdis
                        mdis=dis;
                        mp=p;
                    end
                end
            end
            gap=gap+1;
            if ~isempty(mp)&&(mdis<thres||gap>gap_thres)
                gap=0;
                last_p=mp;
            end                        
            % plot(xs,ys,'o');
            plot(last_p(1),last_p(2),'rx');
            xlim([-2,2]);
            ylim([0,1.2]);
            % disp([num2str(frame),':',num2str(points)]);
            % pause(0.01);
            pos=pos+12*points;
        end
    end


    %================================================
    %================================================



    function [sphandle] = configureSport(comportSnum)
        % global numSamples_perRx_perChirp;
        % 释放被占用的串口
        if ~isempty(instrfind('Type','serial'))
            disp('Serial port(s) already open. Re-initializing...');
            fclose(instrfind('Type','serial'));
            delete(instrfind('Type','serial'));  % delete open serial ports.
        end
        comportnum_str=['COM' num2str(comportSnum)];
        sphandle = serial(comportnum_str,'BaudRate',921600);
        set(sphandle,'InputBufferSize',buffer_size);
        set(sphandle,'Timeout',10);
        set(sphandle,'ErrorFcn',@dispError);
        set(sphandle,'BytesAvailableFcnMode','byte');
        set(sphandle,'BytesAvailableFcnCount',buffer_size);
        set(sphandle,'BytesAvailableFcn',@readData);
        fopen(sphandle);
    end

    function [sphandle] = configureCliPort(comportPnum)
    %     if ~isempty(instrfind('Type','serial'))
    %         disp('Serial port(s) already open. Re-initializing...');
    %         delete(instrfind('Type','serial'));  % delete open serial ports.
    %     end
        comportnum_str=['COM' num2str(comportPnum)];
        sphandle = serial(comportnum_str,'BaudRate',115200);
        set(sphandle,'ErrorFcn',@dispError);
        set(sphandle,'Parity','none');    
        set(sphandle,'Terminator','CR/LF');
        fopen(sphandle);
    end

    function [] = dispError()
        disp('Serial port error!');
    end
end