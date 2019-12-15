clear,clc
%% 可更改参数
cfgFileName = 'Profile.cfg';
comportStandardNum = 3;%USB端口号
comportEnhancedNum = 4;%USB端口号
loadCfg = 0;%上电后或者改变波形参数后第一次采集数据置为1

%%  获取的数据存储在adcData中
figure;
for t_1=1:100
[adcData,numAdcSamples,sampleRate,freqSlopeConst,numChirps] = ...
    GetRawData(cfgFileName,comportStandardNum,comportEnhancedNum,loadCfg);
% rx1~4 表示四根接收天线的接收信号
% rx1为一个矩阵，每一列表示一帧chirp回波，列数代表帧数
rx1 = adcData(1,:);
rx2 = adcData(2,:);
rx3 = adcData(3,:);
rx4 = adcData(4,:);
disp('Finish!!!');

%% 基本信号处理例程
rx1 = reshape(adcData(1,:),numAdcSamples,[]);
rx2 = reshape(adcData(2,:),numAdcSamples,[]);
rx3 = reshape(adcData(3,:),numAdcSamples,[]);
rx4 = reshape(adcData(4,:),numAdcSamples,[]);

% 下面的例子只处理一根天线的接收信号

% 对接收信号直接fft，可获取静止目标的距离信息
% fft后的序列索引与实际距离的对应关系需要换算
rangeFFT1 = fft(rx1,numAdcSamples);% 对每一列进行fft
% figure; 
% plot(abs(rangeFFT1));
% xlabel('FFT index')
% ylabel('Amplitude')

% 对接收的信号数据矩阵，进行2维fft，获取距离-速度平面
% 峰值对应了目标的距离和速度
RD_plane = range_doppler_plane(rx1,numAdcSamples,sampleRate,freqSlopeConst,numChirps);
pause(0.1);
end
