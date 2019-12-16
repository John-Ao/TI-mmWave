function DataStream()

    write_to_board=true; % set to true if it's the first time to run
    cfgFileName = 'Profile.cfg';
    comportUserNum = 3; % standard, for commands
    comportDataNum = 4; % enhanced, for data

    % open config file

    numChirps = 0;
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

    % Send Configuration Parameters to Board
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

    sampleRate = sampleRate*1000; % kbps->bps
    freqSlopeConst = freqSlopeConst*1e12; % MHz/us->Hz/s
    lightSpeed_meters_per_sec = 3e8;
    
    x_axis = ((((0:numAdcSamples-1)/numAdcSamples)*sampleRate)/...
        freqSlopeConst)*lightSpeed_meters_per_sec/2; % distance
    
    hanningWin = hanning(numAdcSamples); % numRangeBins = numAdcSamples
    % hanningWin = repmat(hanningWin,1,numChirps);

    figure;
    numChirps4=numChirps*4;
    disp('Init done!');

    %================================================
    %================================================


    numAdcSamples_t = power(2,ceil(log2(numAdcSamples)));
    numSamples_perRx_perChirp = numAdcSamples_t * 4; % uint8 x complex

    adcData = [];
    TIMEOUT=0.2;% set timeout for receiving uart reply

    bytevec = zeros(numAdcSamples,numChirps4);
    data_count=0;
    data_pos=1;
    readDataFlag = 0;


    % 释放串口
    port=instrfind('Type','serial');
    if ~isempty(port)
        fclose(port);
        delete(port);  % delete open serial ports.
    end

    % Configure data UART port
    sphandle = configureSport(comportDataNum);
    spCliHandle = configureCliPort(comportUserNum);

    warning off; % MATLAB: serial:fread:unsuccessfulRead

    readBufferTime = tic;

    fprintf(spCliHandle,'sensorStop');
    radarReply = fscanf(spCliHandle);
    if ~isempty(radarReply)&&any(radarReply(1:4)~='Done')
        disp(radarReply);
    end
    pause(.05);
    fprintf(spCliHandle,'sensorStart');
    fprintf('%s\n','sensorStart');
    readBufferTime = tic;
    radarReply = fscanf(spCliHandle);
    if any(radarReply(1:4)~='Done')
        disp(radarReply);
    end

    data_complete=false;

    while true
        t=toc(readBufferTime);
        % if data_count==numChirps4
        %     data_complete=true;
        %     break
        % end
        if t > TIMEOUT
            if readDataFlag == 0
                disp('发送的参数有问题，请重新配置参数并重启雷达！');
                break
            else
                disp('发生丢包！');
                disp(data_count)
                if data_count>numChirps4-4
                    for i=data_count+1:numChirps4
                        bytevec(:,i)=bytevec(:,data_count);
                    end
                    data_complete=true;
                end
                data_count=0;
                fprintf(spCliHandle,'sensorStop');
                pause(0.5);
                fprintf(spCliHandle,'sensorStart');
                fprintf('%s\n','sensorStart');
                radarReply = fscanf(spCliHandle);
                disp(radarReply);
                readBufferTime = tic;
            end
        end
    end

    fprintf(spCliHandle,'sensorStop');
    % 释放串口
    port=instrfind('Type','serial');
    if ~isempty(port)
        fclose(port);
        delete(port);  % delete open serial ports.
    end

    if ~data_complete
        return
    end

    % bytevec = reshape(bytevec,1,[]); % 1024x128 -> 1x131072
    % bytevec = uint8(bytevec);
    % tmp = double(typecast(bytevec,'int16')); % ->1x65536
    % tmp = tmp(1:2:end)+1i*tmp(2:2:end); % ->2x32768
    % tmp = reshape(tmp,numAdcSamples_t,[]); % ->256x128
    % rx1 = bytevec(:,1:4:end); % 256x32
    % rx2 = tmp(:,2:4:end);
    % rx3 = tmp(:,3:4:end);
    % rx4 = tmp(:,4:4:end);


    function range_doppler_plane()
        tmp = fftshift(abs(fft(bytevec(:,1:4:end).'))).';%对每一行进行fft
        % figure; 
        imagesc(1:numChirps,x_axis,tmp);
        xlabel('doppler'); ylabel('range'); title('2D FFT');
    end
    
    function [] = readData(obj,event) %#ok<*INUSD>
        data_count=data_count+1;
        tmp = fread(obj,numSamples_perRx_perChirp,'uint8');
        tmp = uint8(tmp);
        tmp = double(typecast(tmp,'int16'));
        tmp = tmp(1:2:end)+1i*tmp(2:2:end);
        bytevec = [bytevec(:,2:end),fft(tmp.*hanningWin)];

        if mod(data_count,4)==1
            tmp = fftshift(abs(fft(bytevec(:,1:4:end).').'),2);%对每一行进行fft
            % figure; 
            imagesc(1:numChirps,x_axis,tmp);
            pause(0.001);
            % xlabel('doppler'); ylabel('range'); title('2D FFT');
        end

        readBufferTime = tic;
        readDataFlag = 1;
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
        set(sphandle,'InputBufferSize',numSamples_perRx_perChirp);
        set(sphandle,'Timeout',10);
        set(sphandle,'ErrorFcn',@dispError);
        set(sphandle,'BytesAvailableFcnMode','byte');
        set(sphandle,'BytesAvailableFcnCount',numSamples_perRx_perChirp);
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