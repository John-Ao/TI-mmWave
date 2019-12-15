function [numAdcSamples,sampleRate,freqSlopeConst,numChirps,cliCfg] = ...
    InitRadar(cfgFileName)

    % param1: cfgFileName - Name of the configuration file

    numChirps = 0;
    cfgFileId = fopen(cfgFileName,'r');
    if cfgFileId == -1
        fprintf('File %s not found!\n',cfgFileName);
        return
    else
        fprintf('Opening configuration file %s ...\n',cfgFileName);
    end
    cliCfg = [];
    tline = fgetl(cfgFileId);
    k = 1;
    while ischar(tline)
        cliCfg{k} = tline;
        tline = fgetl(cfgFileId);
        k = k+1;
    end
    fclose(cfgFileId);

    % read numAdcSamples from 'profileCfg' 
    for k = 1:length(cliCfg)
        cliCmd = cliCfg{k};
        if(cliCmd(1)~='%')
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
                    numAdcSamples_t = power(2,ceil(log2(numAdcSamples)));
                    numSamples_perRx_perChirp = numAdcSamples_t * 2 * 2;
                end
            end
        end
    end

end