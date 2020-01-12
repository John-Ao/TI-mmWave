#Importing all the modules
try:
    import time, random, sys, os
except ImportError:
    print("Make sure to have the time module")
    sys.exit()
try:
    import pygame
except ImportError:
    print("Make sure you have python 3 and pygame.")
    sys.exit()
try:
    import main
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
pygame.display.set_caption("水果忍者")
font_100 = pygame.freetype.Font("Font.ttf", 100)
font_50 = pygame.freetype.Font("Font.ttf", 50)
font_75 = pygame.freetype.Font("Font.ttf", 75) 
SizeCheck = pygame.font.Font("Font.ttf", 50)
SizeCheck_75 = pygame.font.Font("Font.ttf", 75)
font_35 = pygame.freetype.Font("Font.ttf", 35)
first_run=True


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

def shorten(Num):
    count = 0
    let = ""
    while Num >= 1000:
        Num /= 1000
        count += 1
    Num = str(Num)
    Num2 = ""
    if count >= 1:
        for i in range(Num.index(".")+2):
            Num2 += Num[i]
        Num = Num2
    if count == 1:
        Num += "K"
    if count == 2:
        Num += "M"
    if count == 3:
        Num += "B"
    if count == 4:
        Num += "T"
    if count == 5:
        Num += "q"
    if count == 6:
        Num += "Q"
    if count == 7:
        Num += "s"
    if count == 8:
        Num += "S"
    return Num

def HomeScreen(score=0):
    global game_run,first_run
    game_run=True
    screen = "Main"
    Colors = [(0,250,0),(250,0,0),(0,0,250),(255,255,0),(0,255,255)]
    SubColors = [(0,150,0),(150,0,0),(0,0,150),(150,150,0),(0,150,150)]
    ColorSelection = 0
    Images = load_images("Images")
    
    while game_run:
        #gameDisplay.blit(pygame.transform.scale(Images["Bg"],(DisplayWidth,DisplayHeight)),(0,0))
        pos = pygame.mouse.get_pos()
        if screen == "Main":
            if first_run:
                gameDisplay.blit(pygame.transform.scale(Images["splash2"],(DisplayWidth,DisplayHeight)),(0,0))
                text_surface, rect = pygame.freetype.Font("Font.ttf", 40).render(("可先在此界面熟悉用手势操控水果刀,按空格开始游戏"), (255,255,255))
                pygame.draw.rect(gameDisplay,(252,91,49),(20,600-5,950,50),0)
                gameDisplay.blit(text_surface, (25, 600))
            else:
                gameDisplay.fill((0,162,232))

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                game_run=False
                pygame.quit()
                sys.exit()
            if pos[0]>=0 and event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE:
                first_run=False
                main.game_loop([Colors[ColorSelection],SubColors[ColorSelection]])
                                

        if screen == "Main":
            if score != 0:
                gameDisplay.fill((0,162,232))
                text_surface, rect = font_75.render(("Score: " + shorten(score)), (255,255,255))
                gameDisplay.blit(text_surface, (440 - SizeCheck_75.size(shorten(score))[0], 300))
                text_surface, rect = font_50.render(("按空格重玩"), (255,255,255))
                gameDisplay.blit(text_surface, (360, 400))


        x,y = pygame.mouse.get_pos()
        if x<0 or y<0:
            text_surface, rect = pygame.freetype.Font("Font.ttf", 100).render(("加载中"), (255,255,255))
            pygame.draw.rect(gameDisplay,(252,91,49),(350-10,300-10,320,120),0)
            gameDisplay.blit(text_surface, (350, 300))
        else:
            gameDisplay.blit(pygame.transform.rotate(pygame.transform.scale(Images['Blade'],(100,100)),30).convert_alpha(),(x-70,y-50))

        pygame.display.flip()
        clock.tick(60)



if __name__ == "__main__":
    HomeScreen()
