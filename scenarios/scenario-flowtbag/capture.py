import os
import sys
from time import sleep

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

        # NETWORK CONFIG

        # networks["NETWORK"].addNetworkRules(delay=0.0, perc_loss=0.0)

        startup_successful = True

    except Exception as e:
        logger.log(
            message=f"Failed to start scenario: {e}",
            type="error"
        )
        os.system(f"{ROOT_DIR}/tools/clean.sh")

    if startup_successful:

        # MAIN SCENARIO

        # input("Start scenario?")

        containers["flowtbag"].run(
            command="python3 /usr/share/data/run.py",
            intent="INTENT",
            target="TARGET"
        )

        input("Finished?")

        # CAPTURE TEARDOWN

        controller.tearDown()

        # controller.removeNetworks()

        # controller.createFlows()
        # controller.markFlows()

        # controller.writeTrail("trail")

    # logger.outLog(f"{pwd}/log.txt")

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
