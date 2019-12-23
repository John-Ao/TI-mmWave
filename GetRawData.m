function adcData = GetRawData(comportUserNum,comportDataNum,numChirps,numAdcSamples)

    % param2: comportUserNum - COM Number of User UART

    % param3: comportDataNum - COM Number of Data Port

    % param4: loadCfg - Enabled flag of sending configuration parameters
    %         1 - enabled;  0 - disabled

    % out1:   raw ADC data, [numRx,numAdcSamples*numChirps]

    % numChirps,numAdcSamples
    numAdcSamples_t = power(2,ceil(log2(numAdcSamples)));
    numSamples_perRx_perChirp = numAdcSamples_t * 2 * 2;

    adcData = [];
    TIMEOUT=0.2;% set timeout for receiving uart reply

    bytevec = zeros(numAdcSamples,numChirps*4);
    data_count=0;
    readDataFlag = 0;

    % Configure data UART port
    configureSport(comportDataNum);

    % Send Configuration Parameters to Board
    % Open CLI port
    spCliHandle = configureCliPort(comportUserNum);

    warning off; % MATLAB: serial:fread:unsuccessfulRead
%     timeOut = get(spCliHandle,'Timeout');
    set(spCliHandle,'Timeout',1);

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
        % if size(bytevec,2) == numChirps*4
        % if data_count==numChirps*4
        %     data_complete=true;
        %     break
        % end
        if t > TIMEOUT
            if readDataFlag == 0
                disp('发送的参数有问题，请重新配置参数并重启雷达！');
            else
                disp('发生丢包！');
                disp(data_count)
                if data_count>numChirps*4-4
                    for i=data_count+1:numChirps*4
                        bytevec(:,i)=bytevec(:,data_count);
                    end
                    data_complete=true;
                end
                fprintf(spCliHandle,'sensorStop');
            end
            break
        end
    end

    fprintf(spCliHandle,'sensorStop');
    bytevec(:,data_count-1)=bytevec(:,data_count);
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
    tmp=bytevec;
    rx1 = tmp(:,1:4:end); % 256x32
    rx2 = tmp(:,2:4:end);
    rx3 = tmp(:,3:4:end);
    rx4 = tmp(:,4:4:end);
    % rx1 = rx1(1:numAdcSamples,:);
    % rx2 = rx2(1:numAdcSamples,:);
    % rx3 = rx3(1:numAdcSamples,:);
    % rx4 = rx4(1:numAdcSamples,:);
    rx1 = reshape(rx1,1,[]); % 1x8192
    rx2 = reshape(rx2,1,[]);
    rx3 = reshape(rx3,1,[]);
    rx4 = reshape(rx4,1,[]);
    adcData = [rx1;rx2;rx3;rx4];

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

    function [] = readData(obj,event) %#ok<*INUSD>
        data_count=data_count+1;
        tmp = fread(obj,numSamples_perRx_perChirp,'uint8');
        tmp = uint8(tmp);
        tmp = double(typecast(tmp,'int16'));
        tmp = tmp(1:2:end)+1i*tmp(2:2:end);
        bytevec(:,data_count) = tmp;
        % bytevec(:,data_count) = fread(obj,numSamples_perRx_perChirp,'uint8');
        % [tempvec,~] = fread(obj,numSamples_perRx_perChirp,'uint8');
        % bytevec = [bytevec,tempvec];
        readBufferTime = tic;
        readDataFlag = 1;
    end
end