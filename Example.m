% clear,clc
%% �ɸ��Ĳ���
cfgFileName = 'Profile.cfg';
comportStandardNum = 3;%USB�˿ں�
comportEnhancedNum = 4;%USB�˿ں�
loadCfg = 1;%�ϵ����߸ı䲨�β������һ�βɼ�������Ϊ true

%%  ��ȡ�����ݴ洢��adcData��
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
    %% �����źŴ�������
    rx1 = reshape(adcData(1,:),numAdcSamples,[]);
    % rx2 = reshape(adcData(2,:),numAdcSamples,[]);
    % rx3 = reshape(adcData(3,:),numAdcSamples,[]);
    % rx4 = reshape(adcData(4,:),numAdcSamples,[]);

    % ���������ֻ����һ�����ߵĽ����ź�

    RD_plane = range_doppler_plane(rx1,numAdcSamples,sampleRate,freqSlopeConst,numChirps);
end
