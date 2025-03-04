import re
import os
import sys
import subprocess
from time import time, sleep
from threading import Thread
from datetime import datetime

def trunc(path: str, times: int = 1):
    if times == 0: return path
    return trunc(path=os.path.dirname(path), times=times-1)

CAPTURE_DIR = trunc(os.path.abspath(__file__))
ROOT_DIR = trunc(CAPTURE_DIR, times=1)
sys.path.append(ROOT_DIR)

from Forge.cli import genCLI


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    ALL = [HEADER, OKBLUE, OKCYAN, OKGREEN, WARNING, FAIL, ENDC, BOLD, UNDERLINE]


RUNNING: bool = False


def run(command: str, sudo: bool, stdout=None, stderr=None) -> None:
    command: list[str] = command.split(" ")
    if sudo: command = ["sudo"] + command
    return subprocess.run(command, stdout=stdout, stderr=stderr)


def remove() -> None:
    
    requires_sudo: int = genCLI(items_in=["no", "yes"], message="Require sudo?")[1]
    if requires_sudo == "QUIT": return
    requires_sudo: bool = requires_sudo == "yes"

    choice: int = 0
    while choice != -1:

        with open("installed.txt", "w") as output_file:
            run("docker images", requires_sudo, stdout=output_file)

        with open("installed.txt", "r") as output_file:
            out_images = output_file.read().split("\n")

        images = []
        for image in out_images[1:-1:]:
            formatted_image = re.sub(r'\s+', ',', image).split(",")
            formatted_image = "".join([formatted_image[0], ":", formatted_image[1]])
            images.append(formatted_image)

        images = sorted(images)
        images.insert(0, "all")

        choice = genCLI(images, message="Remove")[0]

        if choice == -1:
            break

        if choice == 0:
            for image in images[1::]:
                run(f"docker rmi {image}", requires_sudo)
                print(f"Removed Image: {image}")
        else:
            run(f"docker rmi {images[choice]}", requires_sudo)
            print(f"Removed Image: {images[choice]}")

        run("rm installed.txt", requires_sudo)

        sleep(2)
    
    run("rm installed.txt", requires_sudo)

    return


def printProgress(progress):
    global RUNNING
    start = time()
    while RUNNING:
        os.system("clear")
        print(f"{progress} : {round(time() - start, 2)}")
        sleep(1)


def buildImage(image, requires_sudo: bool) -> dict:
    path = f"./containers/{image}"
    tag = f"forge/{image[7::]}"
    start = time()
    with open(f"{path}/build_log.log", "w") as log_file:

        result = run(f"docker build -t {tag} {path}", requires_sudo, stdout=log_file, stderr=subprocess.STDOUT)

    return {
        "code": not result.returncode,
        "state": f"{bcolors.FAIL}Failed" if result.returncode != 0 else f"{bcolors.OKGREEN}Succeeded",
        "time": round(time()-start, 2),
    }


def pull(image: str, requires_sudo: bool) -> dict:

    start = time()
    tag = image[:image.index(":"):] if ":" in image else image
    log_name = tag.replace("/", "")

    with open(f"./containers/standard-logs/{log_name}.log", "w") as log_file:

        result = run(f"docker pull {image}", requires_sudo, stdout=log_file, stderr=subprocess.STDOUT)

    if result.returncode == 0:
        run(f"docker tag {image} {tag}", requires_sudo)

    return {
        "code": not result.returncode,
        "state": f"{bcolors.FAIL}Failed" if result.returncode == 1 else f"{bcolors.OKGREEN}Succeeded",
        "time": round(time()-start, 2),
    }


def build() -> None:

    global RUNNING
    
    requires_sudo: int = genCLI(items_in=["no", "yes"], message="Require sudo?")[1]
    if requires_sudo == "QUIT": return
    requires_sudo: bool = requires_sudo == "yes"

    choice: int = 0
    while choice != -1:

        all_dir = sorted(os.listdir("./containers"))
        STD_IMAGES = set([])

        images = {}
        count = 1
        for image in STD_IMAGES:
            images.update({count: image})
            count += 1

        # Get all images

        for item in all_dir:
            if item[0:7] == "docker-":
                images.update({count: item})
                count += 1

        # Get user input

        choice = genCLI(["all"] + list(images.values()), message="Build")[0]

        if choice != -1:

            # Build images

            os.system("clear")

            to_build = [choice] if choice != 0 else images.keys()

            input("Start?")

            if requires_sudo: os.system("sudo echo ''")

            progress = ""
            total_success = 0
            for key in to_build:
                image = images[key]
                # print(f"{progress}{bcolors.OKBLUE}In Progress : {key} {image}{bcolors.ENDC}")
                RUNNING = True
                Thread(target=lambda: printProgress(f"{progress}{bcolors.OKBLUE}In Progress : {key} {image}{bcolors.ENDC}"), daemon=True).start()
                if image in STD_IMAGES:
                    res = pull(image, requires_sudo)
                else:
                    res = buildImage(image, requires_sudo)
                RUNNING = False
                sleep(1.5)
                progress += f"{res['state']} : {key} {image} : {res['time']}{bcolors.ENDC}\n"
                os.system("clear")
                if res["code"]:
                    total_success += 1

            print(progress)

            progress += f"Total: {total_success}/{len(images)}"
            for code in bcolors.ALL:
                progress = progress.replace(code, "")

            date_time = datetime.now().strftime("%d_%m_%Y_H%H_M%M")

            if not os.path.isdir("./containers/build-logs"):
                os.makedirs("./containers/build-logs", exist_ok=True)

            with open(f"./containers/build-logs/build_result_{date_time}.log", "w") as build_result:
                build_result.write(progress)

            sleep(3)


def main() -> None:
    
    choice = genCLI(items_in=["build", "remove"], message="Select")[1]

    while choice != "QUIT":
        
        if choice == "build":
            build()
        else:
            remove()

        choice = genCLI(items_in=["build", "remove"], message="Select")[1]


if __name__ == "__main__":
    main()
