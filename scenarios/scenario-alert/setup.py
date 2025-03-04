import os
import sys
from time import sleep, time

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


def scenario(
        controller: Controller,
        containers: dict[str, Container],
        networks: dict[str, Network],
        pwd: str,
        logger: Logger,
        sandbox: bool,
    ) -> None:

    # CAPTURE STARTUP

    startup_successful: bool = False
    
    try:

        controller.startNetworks()

        controller.start()

        startup_successful = True

    except Exception as e:
        logger.log(
            message=f"Failed to start scenario: {e}",
            type="error"
        )
        os.system(f"{ROOT_DIR}/tools/clean.sh")
        logger.outLog(f"{pwd}/data/log.txt")
        raise(e)

    if startup_successful:

        # MAIN SCENARIO

        input("Finished?")

        # CAPTURE TEARDOWN

        controller.complete(
            trail="/trail.sh",
            intents="/data/intents.txt",
            skip_teardown=False,
            skip_networks=False,
            skip_intents=True,
            skip_trail=True,
            skip_flows=True,
            skip_tests=True,
            skip_webpage=True
        )

    logger.outLog(f"{pwd}/data/log.log")

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
