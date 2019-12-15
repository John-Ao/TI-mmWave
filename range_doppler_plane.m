function RD_plane = range_doppler_plane(rxData,numAdcSamples,...
    sampleRate,freqSlopeConst,numChirps)

% input1: rxData - [numAdcSamples,numChirps]

sampleRate = sampleRate*1000; % kbps->bps
freqSlopeConst = freqSlopeConst*1e12; % MHz/us->Hz/s
lightSpeed_meters_per_sec = 3e8;

x_axis = ((((0:numAdcSamples-1)/numAdcSamples)*sampleRate)/...
    freqSlopeConst)*lightSpeed_meters_per_sec/2; % distance

% Range FFT (1D-FFT)
% rangeFFT = fft(rxData,numAdcSamples);
hanningWin = hanning(numAdcSamples); % numRangeBins = numAdcSamples
hanningWin = repmat(hanningWin,1,numChirps);
rangeFFT = fft(rxData.*hanningWin,numAdcSamples);%对每一列进行fft（加了窗）

% Doppler FFT (2D-FFT)
RD_plane = fft(rangeFFT,numChirps,2);%对每一行进行fft

% plot
tmp = fftshift(abs(RD_plane),2);
% figure; 
imagesc(1:numChirps,x_axis,tmp);
xlabel('doppler'); ylabel('range'); title('2D FFT');
end