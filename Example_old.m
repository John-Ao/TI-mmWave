clear,clc
%% �ɸ��Ĳ���
cfgFileName = 'Profile.cfg';
comportStandardNum = 3;%USB�˿ں�
comportEnhancedNum = 4;%USB�˿ں�
loadCfg = 0;%�ϵ����߸ı䲨�β������һ�βɼ�������Ϊ1

%%  ��ȡ�����ݴ洢��adcData��
figure;
for t_1=1:100
[adcData,numAdcSamples,sampleRate,freqSlopeConst,numChirps] = ...
    GetRawData(cfgFileName,comportStandardNum,comportEnhancedNum,loadCfg);
% rx1~4 ��ʾ�ĸ��������ߵĽ����ź�
% rx1Ϊһ������ÿһ�б�ʾһ֡chirp�ز�����������֡��
rx1 = adcData(1,:);
rx2 = adcData(2,:);
rx3 = adcData(3,:);
rx4 = adcData(4,:);
disp('Finish!!!');

%% �����źŴ�������
rx1 = reshape(adcData(1,:),numAdcSamples,[]);
rx2 = reshape(adcData(2,:),numAdcSamples,[]);
rx3 = reshape(adcData(3,:),numAdcSamples,[]);
rx4 = reshape(adcData(4,:),numAdcSamples,[]);

% ���������ֻ����һ�����ߵĽ����ź�

% �Խ����ź�ֱ��fft���ɻ�ȡ��ֹĿ��ľ�����Ϣ
% fft�������������ʵ�ʾ���Ķ�Ӧ��ϵ��Ҫ����
rangeFFT1 = fft(rx1,numAdcSamples);% ��ÿһ�н���fft
% figure; 
% plot(abs(rangeFFT1));
% xlabel('FFT index')
% ylabel('Amplitude')

% �Խ��յ��ź����ݾ��󣬽���2άfft����ȡ����-�ٶ�ƽ��
% ��ֵ��Ӧ��Ŀ��ľ�����ٶ�
RD_plane = range_doppler_plane(rx1,numAdcSamples,sampleRate,freqSlopeConst,numChirps);
pause(0.1);
end
