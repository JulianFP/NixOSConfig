import sys, termios, subprocess
from typing import Callable
import yaml

#explanation terminal arguments:
#1: path to file with current nebula config (generated by nixos nebula module)
#2: path to file where all the unsafeRoutes are stored in yaml format (generated by my nixos module)
#3: path to file where new config file should be written to (should be an absolute path for systemd!)
#4: path to EnvironmentFile that the systemd service reads to know which config file it should take

#the callables are expected to print exactly(!) one line of text into the terminal (not more, not less)
class selectMenu:
    def __init__(self, options: list[tuple[str, bool, Callable[[str, bool], None]]]):
        self.options = options
        self.selected = 0

        #get terminal settings and modify them for our use case
        self.fd = sys.stdin.fileno()
        self.oldTerminalSettings = termios.tcgetattr(self.fd)
        self.newTerminalSettings = termios.tcgetattr(self.fd)
        self.newTerminalSettings[3] = self.newTerminalSettings[3] & ~(termios.ICANON | termios.ECHO)
        self.newTerminalSettings[1] = self.newTerminalSettings[1] &~termios.ONLCR

        #store how many lines of prompt are currently shown
        self.promptLines = 0

    def __show(self):
        for i in range(len(self.options)):
            print("{2} {0}. {1} {3}".format(i+1, self.options[i][0], ">" if self.selected == i else " ", "*" if self.options[i][1] else " "))

    def __redraw(self):
        #go through every line and erase it first
        for _ in range(len(self.options)):
            print("\x1b[1A", end="")
            print("\x1b[2K", end="")
        self.__show()
    
    def __rawread(self, numberOfChars, fd, oldTerminalSettings, newTerminalSettings) -> str:
        try:
            termios.tcsetattr(fd, termios.TCSADRAIN, newTerminalSettings)
            key = sys.stdin.read(numberOfChars)
        except KeyboardInterrupt:
            print("\x1b[{0}B".format(self.promptLines), end="") #make sure prompt gets not overwritten
            raise KeyboardInterrupt
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, oldTerminalSettings)
        return key

    def __up(self):
        if self.selected == 0:
            return
        self.selected -= 1
        self.__redraw()

    def __down(self):
        if self.selected+1 == len(self.options):
            return
        self.selected += 1
        self.__redraw()

    def wait(self):
        print("Choose an option:")
        self.__show()

        key = ""
        while key != "q":
            key = self.__rawread(1, self.fd, self.oldTerminalSettings, self.newTerminalSettings)
            if key == "\x1b":
                key += self.__rawread(2, self.fd, self.oldTerminalSettings, self.newTerminalSettings)

            if key == "j" or key == "\x1b[B":
                self.__down()
            elif key == "k" or key == "\x1b[A":
                self.__up()
            elif key == "\n":
                clickedOption = self.options[self.selected]

                #move cursor down to prompt position and erase that line
                if self.promptLines != 0:
                    print("\x1b[{0}B".format(self.promptLines), end="")
                print("\x1b[2K", end="")

                clickedOption[2](clickedOption[0], clickedOption[1])
                self.options[self.selected] = (clickedOption[0], not clickedOption[1], clickedOption[2])
                self.promptLines += 1

                #move cursor back and redraw
                print("\x1b[{0}A".format(self.promptLines), end="")
                self.__redraw()
        print("\x1b[{0}B".format(self.promptLines), end="") #make sure prompt gets not overwritten


def addNebulaUnsafeRouteFor(routeName: str, selected: bool):
    if selected:
        nebulaConfig["tun"]["unsafe_routes"].remove(unsafeRoutes[routeName])
    else:
        if noneSelected:
            nebulaConfig["tun"]["unsafe_routes"] = []
        nebulaConfig["tun"]["unsafe_routes"].append(unsafeRoutes[routeName])

    newConfigFile = open(sys.argv[3], "w")
    try:
        yaml.dump(nebulaConfig, newConfigFile)
        newConfigFile.close()
    except:
        print("Error: Couldn't open file {0}".format(sys.argv[3]))
        newConfigFile.close()
        return

    envFile = open(sys.argv[4], "w")
    try:
        envFile.write("NEBULA_CONFIG_PATH=\"{0}\"".format(sys.argv[3])) #write path to new config file into envFile
        envFile.close()
    except:
        print("Error: Couldn't open file {0}".format(sys.argv[4]))
        envFile.close()
        return

    try:
        subprocess.run(["systemctl", "restart", "nebula-custom_serverNetwork.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        print("Successfully added {0} to unsafe_routes!".format(routeName))
    except subprocess.CalledProcessError:
        print("Error: Couldn't restart systemd service")


nebulaConfig = {}
noneSelected = False

with open(sys.argv[2], "r") as stream:
    unsafeRoutes = yaml.safe_load(stream)

try:
    stream = open(sys.argv[3], "r")
    nebulaConfig = yaml.safe_load(stream)
except FileNotFoundError:
    noneSelected = True
    with open(sys.argv[1], "r") as stream2:
        nebulaConfig = yaml.safe_load(stream2)
finally:
    stream.close()

try:
    _ = nebulaConfig["tun"]["unsafe_routes"]
except:
    noneSelected = True


menuItems = []
for key in unsafeRoutes.keys():
    route = unsafeRoutes[key]["route"]
    selected = False
    if not noneSelected:
        for configRoute in nebulaConfig["tun"]["unsafe_routes"]:
            if configRoute.get("route") == route:
                selected = True
    menuItems.append((key, selected, addNebulaUnsafeRouteFor))

menu = selectMenu(menuItems)
menu.wait()
