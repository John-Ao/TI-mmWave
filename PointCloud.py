from math import ceil, log2
from time import sleep
import numpy as np
import serial
import matplotlib.pyplot as plt
import cv2


write_to_board = True  # set to true if it's the first time to run
cfgFileName = 'profile01.cfg'
comportUser = 'COM3'  # standard, for commands
comportData = 'COM4'  # enhanced, for data


def b2n(arr, signed=False):
    x = 0
    for i in arr[::-1]:
        x = x*256+i
    if signed and arr[-1] > 127:
        x = x-256**len(arr)
    return x


class Buffer():
    def __init__(self, ser):
        self.ser = ser
        self.buffer = b''
        self.size = 0

    def read(self, n):
        if self.size == 0:
            return self.ser.read(n)
        elif n > self.size:
            buf = self.ser.read(n-self.size)
            self.size = 0
            return self.buffer+buf
        else:
            buf = self.buffer[:n]
            self.buffer = self.buffer[n:]
            self.size -= n
            return buf

    def push(self, buf):
        if self.size == 0:
            self.buffer = buf
            self.size = len(buf)
        else:
            self.buffer = buf+self.buffer
            self.size += len(buf)


# open config file

with open(cfgFileName, 'r') as cfgFile:
    cliCfg = []
    for cliCmd in cfgFile:
        if cliCmd[0] != '%':
            cliCfg.append(cliCmd)
            if cliCmd.startswith('frameCfg'):
                cliCmd_split = cliCmd.split(' ')
                numChirps = int(cliCmd_split[3])
            elif cliCmd.startswith('profileCfg'):
                cliCmd_split = cliCmd.split(' ')
                sampleRate = int(cliCmd_split[11])
                freqSlopeConst = int(cliCmd_split[8])
                numAdcSamples = int(cliCmd_split[10])
                if(numAdcSamples > 1024):
                    print('参数有问题，请降低距离分辨率或减小最大不模糊距离！')
                    exit()

numRangeBins = 2**ceil(log2(numAdcSamples))
rangeResolution = 3e8 * sampleRate * 1e3 / \
    (2 * freqSlopeConst * ((3.6*1e3*900) / (2**26)) * 1e12 * numRangeBins)
xyzOutputQFormat = ceil(log2(16 / rangeResolution))
ONE_QFORMAT = 2**xyzOutputQFormat*16

with serial.Serial(port=comportUser, baudrate=115200) as ser_cmd:
    ser_cmd.timeout = 0.01
    ser_cmd.write(b'sensorStop')
    while True:
        ser_cmd.write(b'')
        temp = ser_cmd.read(100)
        temp = temp.decode('ascii')
        temp = temp.replace('\10', '').replace('\13', '')  # ok<*CHARTEN>
        if len(temp) > 0:
            break
        sleep(0.1)
        print('waiting for reply... ')
    ser_cmd.timeout = 0.01
    if write_to_board:
        print('Sending configuration to board %s ...\n' % cfgFileName)
        for cliCmd in cliCfg[1:-1]:  # skip sensorstop and sensorstart
            ser_cmd.write(cliCmd.encode('ascii'))
            print('>%s\n' % cliCmd)
            radarReply = ser_cmd.read_until('\r').decode('ascii')
            if 'Done' not in radarReply:
                print(radarReply)
            sleep(0.05)

    buffer_size = 256
    data = []

    xmin = -0.9
    xmax = 0.9
    ymax = 0.9
    ymin = 0.1
    last_p = [0, 0]
    last_pp = [0, 0]
    momentum = 0.6
    thres = 0.4**2
    gap = 0
    gap_thres = 30
    pos_checked = False
    # plt.figure()
    # plt.show(block=False)
    plot_w, plot_h = 1024, 512
    plot = np.zeros((plot_h, plot_w, 3), np.uint8)

    print('Init done!')

    # ================================================
    # ================================================
    # Configure data UART port
    with serial.Serial(port=comportData, baudrate=921600, timeout=None) as ser_data:

        ser_cmd.write(b'sensorStart\n')
        print('%s\n' % 'sensorStart')
        print(ser_cmd.readline())

        magic_word = (2, 1, 4, 3, 6, 5, 8, 7)
        data_buf = Buffer(ser_data)
        checked = False
        try:
            while True:
                # find the magic word
                if ~checked:
                    mp = 0
                    while True:
                        tmp = data_buf.read(1)
                        if tmp[0] == magic_word[mp]:
                            mp += 1
                            if mp == 8:
                                break
                    checked = True
                length = b2n(data_buf.read(8)[-4:])
                # bytes after [length] plus next magic word
                data = data_buf.read(length-16+8)
                frame = b2n(data[4:8])
                if tuple(data[-8:]) != magic_word:
                    print('Corrupt frame: %d' % frame)
                    data_buf.push(data)
                    checked = False
                    continue
                points = b2n(data[12:16])
                data = data[36:-8]
                data = [b2n(i, signed=True) /
                        ONE_QFORMAT for i in zip(data[::2], data[1::2])]
                xs = data[3::6]
                ys = data[4::6]
                mdis = 1e8
                mp = []
                for x, y in zip(xs, ys):
                    if xmin < x < xmax and ymin < y < ymax:
                        p = [x, y]
                        dis = (x-last_p[0])**2+(y-last_p[1])**2
                        if dis < mdis:
                            mdis = dis
                            mp = p
                gap = gap+1
                if len(mp) > 0 and (mdis < thres or gap > gap_thres):
                    gap = 0
                    last_p = [-mp[0], mp[1]]  # flip over y axis
                # plot(xs,ys,'o')
                # plt.plot(last_p[0],last_p[1],'rx')
                # plt.xlim([-2,2])
                # plt.ylim([0,1.2])
                # plt.pause(0.01)
                last_pp = [last_pp[0]*momentum+last_p[0] *
                           (1-momentum), last_pp[1]*momentum+last_p[1]*(1-momentum)]
                plot[:] = 0
                # x, y = int((1-last_pp[1])*plot_h) - 1, \
                #        int((last_pp[0]+1)/2*plot_w) - 1
                x=int((np.clip(last_pp[0],-0.15,0.15)/0.15+1)/2*plot_w)
                y=int((1-np.clip(last_pp[1],0.3,0.6)/0.3)*plot_h)
                plot[y-3:y+3, x-3:x+3, :] = 255
                cv2.imshow('Figure', plot)
                cv2.waitKey(20)
                print(frame, last_p)
                # print([num2str(frame),':',num2str(points)])
                # sleep(0.01)
        except KeyboardInterrupt:
            ser_cmd.write(b'sensorStop\n')
            print('Sensor Stopped')
