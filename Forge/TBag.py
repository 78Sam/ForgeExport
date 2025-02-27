import os
# import pandas as pd

from Forge.Logger import Logger

# from Logger import Logger


def validate(
        logger: Logger,
        pwd: str
    ) -> bool:

    logger.log()

    if not os.path.isdir(pwd):
        logger.log(
            message=f"Provided path {pwd} doesn't exist",
            type="error"
        )
        return False
    
    # Check PCAP folder exists

    pcap_path = f"{pwd}/data/pcap"

    if not os.path.isdir(pcap_path):
        logger.log(
            message=f"No pcap directory at {pcap_path}",
            type="error"
        )
        return False
    
    # Check that there are PCAP files to parse

    pcaps = {pcap[0:-5:] for pcap in os.listdir(pcap_path) if pcap[-5::] == ".pcap"}

    if len(pcaps) == 0:
        logger.log(
            message=f"No PCAP files to convert in {pcap_path}",
            type="warning"
        )
        return False

    # Check flow directory exists, if not, make it, and get existing flows

    flow_path = f"{pwd}/data/flows"

    if not os.path.isdir(flow_path):
        os.mkdir(flow_path)

    existing_flows = {flow[0:-4:] for flow in os.listdir(flow_path) if flow[-4::] == ".csv"}

    # Prevent existing flows from being duplicated

    for flow in existing_flows:
        if flow in pcaps:
            pcaps.remove(flow)
    
    return True


def tBag(
        logger: Logger,
        pwd: str
    ) -> bool:

    logger.log()

    if not validate(logger=logger, pwd=pwd):
        return False

    pcap_path = f"{pwd}/data/pcap"
    flow_path = f"{pwd}/data/flows"

    pcaps = {pcap[0:-5:] for pcap in os.listdir(pcap_path) if pcap[-5::] == ".pcap"}

    # Generate flows

    for pcap in pcaps:
        new_name = pcap.replace("-tcpdump", "")
        try:
            cmd: str = f"{os.path.dirname(__file__)}/../tools/Flowtbag {pcap_path}/{pcap}.pcap > {flow_path}/{new_name}.csv"
            logger.trail(cmd)
            os.system(cmd)
        except:
            logger.log("Error creating flows", type="error")
            return False

    logger.log(f"Done: {len(pcaps)} new flow files created", type="ok")

    return True


def main() -> None:
    logger = Logger(rolling_messages=True, interesting_only=True)
    cwd = os.getcwd()
    tBag(
        logger=logger,
        # pwd=f"{cwd}/captures/capture-hydra"
        pwd=f"{cwd}/scenarios/scenario-hydra"
    )


if __name__ == "__main__":
    main()
