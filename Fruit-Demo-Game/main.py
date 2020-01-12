#Importing all the modules
try:
    import time, random, sys, os, math, threading
    from math import ceil, log2
    from time import sleep
    import numpy as np
    import serial
except ImportError:
    print("Make sure to have the time module")
    sys.exit()
try:
    import pygame
except ImportError:
    print("Make sure you have python 3 and pygame.")
    sys.exit()
try:
    import MainMenu
except ImportError:
    print("Make sure you have all the extra files")
from pygame import freetype


#game_font = pygame.freetype.Font("Font.ttf", 75)
#text_surface, rect = game_font.render(("Programmer: 8BitToaster"), (0, 0, 0))
#gameDisplay.blit(text_surface, (150, 300))

# Initialize the game engine
pygame.init()


DisplayWidth,DisplayHeight = 1000, 800
clock = pygame.time.Clock()

gameDisplay = pygame.display.set_mode((DisplayWidth,DisplayHeight))
pygame.display.set_caption("Fruit Demo Game - Ao")
font_100 = pygame.freetype.Font("Font.ttf", 100)
font_50 = pygame.freetype.Font("Font.ttf", 50)
font_75 = pygame.freetype.Font("Font.ttf", 75) 
font_35 = pygame.freetype.Font("Font.ttf", 35)

radar_pos=(-1,-1)
game_run=True
last_radar_pos=radar_pos
def get_radar():
    global radar_pos
    return radar_pos

def get_radar_rel():
    global radar_pos,last_radar_pos
    rel=(radar_pos[0]-last_radar_pos[0],radar_pos[1]-last_radar_pos[1])
    last_radar_pos=radar_pos
    return rel

pygame.mouse.get_pos=get_radar
pygame.mouse.get_rel=get_radar_rel

#Loading the images
def load_images(path_to_directory):
    images = {}
    for dirpath, dirnames, filenames in os.walk(path_to_directory):
        for name in filenames:
            if name.endswith('.png'):
                key = name[:-4]
                if key != "Bg":
                    img = pygame.image.load(os.path.join(dirpath, name)).convert_alpha()
                else:
                    img = pygame.image.load(os.path.join(dirpath, name)).convert()
                images[key] = img
    return images


#Calculates and draws everything for the fruits
class Fruit():
    def __init__(self, Image, x=None, y=None, Vx=None, gravity=None, width=200,height=200):
        """Declares all the starting Variables."""
        self.Image = Image
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.Vx = Vx
        self.gravity = gravity
        if x == None:
            self.x = 500
        if y == None:
            self.y = 800
        if Vx == None:
            self.Vx = random.randint(-20,20)
        if gravity == None:
            self.gravity = random.randint(-22,-20)
        self.image = pygame.Surface([self.width,self.height])
        self.rect = self.image.get_rect()
        self.rect.top = self.y
        self.rect.bottom = self.y + self.height
        self.rect.left = self.x
        self.rect.right = self.x + self.width
        self.angle = random.randint(0,355)
        self.split = False
 

    def draw(self):
        """Draws the Fruit."""
        gameDisplay.blit(pygame.transform.rotate(pygame.transform.scale(self.Image,(self.width,self.height)),self.angle).convert_alpha(),(self.x,self.y))

    def Physics(self):
        """Calculates the physics and angles of each fruit."""
        self.x += self.Vx
        self.y += self.gravity
        self.gravity += 0.35
        if self.Vx > 0:
            self.Vx -= 0.25
        if self.Vx < 0:
            self.Vx += 0.25
        if self.x + self.width >= 1000 or self.x <= 0:
            self.Vx *= -1

        #Updating the angles
        self.angle += 1
        self.angle %= 360

    def update(self):
        """Calls every function to update each fruit."""
        self.draw()
        self.Physics()
        #Updating the hitbox
        self.rect.top = self.y
        self.rect.bottom = self.y + self.height
        self.rect.left = self.x
        self.rect.right = self.x + self.width

class Player():
    def __init__(self):
        """Declaring a bunch of variables"""
        pos = pygame.mouse.get_pos()
        self.x = pos[0]
        self.y = pos[1]
        self.width = 5
        self.height = 5
        self.image = pygame.Surface([self.width,self.height])
        self.rect = self.image.get_rect()
        self.rect.top = self.y
        self.rect.bottom = self.y + self.height
        self.rect.left = self.x
        self.rect.right = self.x + self.width
        self.drag = True # False
        self.Past = []

    def draw(self, Colors):
        """Draws your slashy line"""
        pygame.draw.rect(gameDisplay,(0,255,0),(self.x,self.y,self.width,self.height),0)
        #New Version
        for i in range(len(self.Past)-2):
            self.Past[i][1] -= 1
            if self.Past[i][1] >= 1:
                pygame.draw.line(gameDisplay, Colors[1],(self.Past[i][0]),(self.Past[i+1][0]),self.Past[i][1]+10)
                pygame.draw.line(gameDisplay, Colors[0],(self.Past[i][0]),(self.Past[i+1][0]),self.Past[i][1])
        #Old Version
        '''for point in self.Past:
            point[1] -= 1
            if point[1] >= 0:
                pygame.draw.rect(gameDisplay,Colors[0],(point[0][0],point[0][1]-int(point[1]/2),point[2], point[1]),0)
                pygame.draw.rect(gameDisplay,Colors[1],(point[0][0],point[0][1]-int(point[1]/2),point[2], point[1]),5)'''

    def update(self, Colors):
        """Calls every function to update them"""
        self.draw(Colors)
        #Updating the lines
        pos = pygame.mouse.get_pos()
        change = pygame.mouse.get_rel()
        self.Past.insert(0, [pos, (change[1]+10) % 30, (abs(change[0])*3) % 100])
        if len(self.Past) >= 21:
            self.Past.pop(20)
        #Updating the hitbox
        self.x = pos[0]
        self.y = pos[1]
        self.rect.top = self.y
        self.rect.bottom = self.y + self.height
        self.rect.left = self.x
        self.rect.right = self.x + self.width

class Explosion():
    """A Little class that makes an explosion every time you hit a bomb"""
    def __init__(self,x,y):
        self.x = x
        self.y = y
        self.Life = 20

    def draw(self, Images):
        gameDisplay.blit(pygame.transform.scale(Images["Explosions"],(150,150)),(self.x,self.y))

    def update(self, Images):
        self.draw(Images)
        self.x += random.randint(-5,5)
        self.y += random.randint(-5,5)
        self.Life -= 1

def game_loop(Colors=[(0,255,0),(0,150,0)]):
    global game_run
    Images = load_images("Images")
    Choices = ["Grapes", "Orange", "Apple","Lemon", "Strawberry"]
    player = Player()
    Fruits = []
    # Lives = 30
    score = 100
    mscore = score
    texts=[] #(content,(x,y),color,timeout)
    for i in range(random.randint(2,5)):
        choice = random.choice(Choices)
        if choice == "Strawberry": 
            Fruits.append(Fruit(Images[choice],500,800,random.randint(-20,20),random.randint(-22,-20),125,125))
        else:
            Fruits.append(Fruit(Images[choice]))
    if random.randint(1,4) <= 3:
        Bombs = [Fruit(Images["Bomb"], 500,1000,random.randint(-30,30),-25,100,100)]
    else:
        Bombs = []
    SplitFruit = []
    Explosions = []
    wound=1 # if wounded, the score goes red
    wound_mask = pygame.Surface((DisplayWidth,DisplayHeight))  # the size of your rect
    wound_mask.set_alpha(0)                # alpha level
    wound_mask.fill((255,0,0))           # this fills the entire surface

    while game_run == True:

        wound=wound**0.9
        #gameDisplay.fill((210,140,42))
        gameDisplay.blit(pygame.transform.scale(Images["Bg"],(DisplayWidth,DisplayHeight)),(0,0))

        flag=False
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                game_run=False
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE:
                flag=True
        if flag:
            MainMenu.HomeScreen(mscore)
            # if event.type == pygame.MOUSEBUTTONDOWN:
            #     player.drag = True
            # if event.type == pygame.MOUSEBUTTONUP:
            #     player.Past = []
            #     player.drag = False

        #Drawing the lives
        if score > 0:
            if score>mscore:
                mscore=score
            text_surface, _ = font_75.render(str(score), (255,255,255))
            gameDisplay.blit(text_surface,(20,20))

            # for i in range(Lives):
            #     pygame.draw.rect(gameDisplay,(250,0,0),(25+(i*55),10,50,50),0)
            #     pygame.draw.rect(gameDisplay,(150,0,0),(25+(i*55),10,50,50),5)
        else:
            MainMenu.HomeScreen(mscore)

        text_=[]
        for t,(x,y),color,timeout in texts:
            text_surface, _ = font_50.render(t, color)
            gameDisplay.blit(text_surface,(x,y))
            timeout-=1
            if timeout>0:
                text_.append((t,(x,y-1),color,timeout))
        texts=text_


        #Drawing all the fruit and its sliced counterparts
        stop = False
        bombed=False
        for fruit in Bombs:
            fruit.update()
            if fruit.y <= 800:
                stop = True
            if pygame.sprite.collide_rect(player, fruit) == True and player.drag:
                Explosions.append(Explosion(fruit.x,fruit.y))
                # Lives -= 1
                punish=int(score*0.03)*10
                texts.append((f'-{punish}',(fruit.x,fruit.y-40),(255,0,0),40))
                score -= punish
                bombed=True
                wound=0.1
                fruit.x = -100
                fruit.y = 900

        score_= 3 if bombed else 10

        for fruit in Fruits:
            fruit.update()
            if fruit.y <= 800:
                stop = True
            if pygame.sprite.collide_rect(player, fruit) == True and player.drag and not fruit.split:
                fruit.split = True
                if fruit.Image == Images["Grapes"]:
                    fruit.Image = Images["GrapeTop"]
                    Fruits.append(Fruit(Images["GrapeBottom"],fruit.x,fruit.y,fruit.Vx*-2,fruit.gravity*1.5))
                elif fruit.Image == Images["Orange"]:
                    fruit.Image = Images["OrangeTop"]
                    Fruits.append(Fruit(Images["OrangeBottom"],fruit.x,fruit.y,fruit.Vx*-2,fruit.gravity*1.5))
                elif fruit.Image == Images["Apple"]:
                    fruit.Image = Images["AppleTop"]
                    Fruits.append(Fruit(Images["AppleBottom"],fruit.x,fruit.y,fruit.Vx*-2,fruit.gravity*1.5))
                elif fruit.Image == Images["Lemon"]:
                    fruit.Image = Images["LemonTop"]
                    Fruits.append(Fruit(Images["LemonBottom"],fruit.x,fruit.y,fruit.Vx*-2,fruit.gravity*1.5))
                elif fruit.Image == Images["Strawberry"]:
                    fruit.Image = Images["StrawberryTop"]
                    Fruits.append(Fruit(Images["StrawberryBottom"],fruit.x,fruit.y,fruit.Vx*-2,fruit.gravity*1.5,125,125))
                Fruits[-1].split = True
                score += score_
                texts.append((f'+{score_}',(fruit.x,fruit.y-40),(255,255,255),30))

                
        if stop == False:
            for fruit in Fruits:
                if fruit.split == False:
                    score -= 10
                    texts.append(('-30',(fruit.x,DisplayHeight-60-random.randint(0,70)),(255,0,0),30))
            Fruits = []
            for i in range(random.randint(2,5)):
                choice = random.choice(Choices)
                if choice == "Strawberry": 
                    Fruits.append(Fruit(Images[choice],500,800,random.randint(-20,20),random.randint(-22,-20),125,125))
                else:
                    Fruits.append(Fruit(Images[choice]))
            if random.randint(1,4) <= 3:
                Bombs = [Fruit(Images["Bomb"],500,800,random.randint(-40,40),-20,100,100)]
            else:
                Bombs = []
        for explosion in Explosions:
            explosion.update(Images)
            if explosion.Life <= 0:
                Explosions.pop(Explosions.index(explosion))

        #Drawing the slashy thingy
        if player.drag == True:
            player.update(Colors)

        # draw wound
        wound_mask.set_alpha((1-wound)*255)
        gameDisplay.blit(wound_mask,(0,0))
        # draw blade
        x,y = pygame.mouse.get_pos()
        gameDisplay.blit(pygame.transform.rotate(pygame.transform.scale(Images['Blade'],(100,100)),30).convert_alpha(),(x-70,y-50))

        pygame.display.flip()
        clock.tick(60)


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


def PointCloud():
    global radar_pos, game_run
    write_to_board = True  # set to true if it's the first time to run
    cfgFileName = 'profile01.cfg'
    comportUser = 'COM3'  # standard, for commands
    comportData = 'COM4'  # enhanced, for data
    time.sleep(10)
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

        data = []

        xmin = -0.9
        xmax = 0.9
        ymax = 0.9
        ymin = 0.1
        last_p = last_p_ = last_pp = [0, 0]
        momentum = 0.6
        thres = 0.4**2
        gap = 0
        gap_thres = 30

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
                    assert game_run
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
                    # points = b2n(data[12:16])
                    data = data[36:-8]
                    data = [b2n(i, signed=True) /
                            ONE_QFORMAT for i in zip(data[::2], data[1::2])]
                    xs = [-x for x in data[3::6]]  # flip over y axis
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
                        last_p_ = mp
                        if (last_p[0]-last_p_[0])**2+(last_p[1]-last_p_[1])**2>0.0008: #0.0001373291015625
                            last_p=last_p_
                    last_pp = [last_pp[0]*momentum+last_p[0] *
                            (1-momentum), last_pp[1]*momentum+last_p[1]*(1-momentum)]
                    x=int((np.clip(last_pp[0],-0.18,0.18)/0.18+1)/2*DisplayWidth)
                    y=int((1-np.clip(last_pp[1]-0.2,0.0,0.5)/0.5)*DisplayHeight)
                    radar_pos_=(x,y)
                    xx,yy=radar_pos
                    if (xx-x)**2+(yy-y)**2>0.006:
                        radar_pos=(x,y)
                    # print(frame, radar_pos)
                    # print([num2str(frame),':',num2str(points)])
                    # sleep(0.01)
                ser_cmd.write(b'sensorStop\n')
                print('Sensor Stopped')
            except Exception:
                ser_cmd.write(b'sensorStop\n')
                print('Sensor Stopped')


if __name__ == "__main__":
    radar=threading.Thread(target=PointCloud)
    radar.deamon=True
    radar.start()
    MainMenu.HomeScreen()
