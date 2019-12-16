% clear,clc
%% 可更改参数
cfgFileName = 'Profile.cfg';
comportStandardNum = 3;%USB端口号
comportEnhancedNum = 4;%USB端口号
loadCfg = 1;%上电后或者改变波形参数后第一次采集数据置为 true

%%  获取的数据存储在adcData中
if loadCfg
    [numAdcSamples,sampleRate,freqSlopeConst,numChirps,cliCfg] = ...
        InitRadar(cfgFileName,comportStandardNum,comportEnhancedNum);
end
while true
    tic
    adcData = GetRawData(comportStandardNum,comportEnhancedNum,numChirps,numAdcSamples);
    toc
    if isempty(adcData)
        continue
    end
    %% 基本信号处理例程
    rx1 = reshape(adcData(1,:),numAdcSamples,[]);
    % rx2 = reshape(adcData(2,:),numAdcSamples,[]);
    % rx3 = reshape(adcData(3,:),numAdcSamples,[]);
    % rx4 = reshape(adcData(4,:),numAdcSamples,[]);

    % 下面的例子只处理一根天线的接收信号

    RD_plane = range_doppler_plane(rx1,numAdcSamples,sampleRate,freqSlopeConst,numChirps);
end
