import os


def validate(
        pwd: str
    ) -> bool:

    if not os.path.isdir(pwd):
        print(
            f"Provided path {pwd} doesn't exist"
        )
        return False
    
    # Check PCAP folder exists

    pcap_path = f"{pwd}/pcap"

    if not os.path.isdir(pcap_path):
        print(
            f"No pcap directory at {pcap_path}"
        )
        return False
    
    # Check that there are PCAP files to parse

    pcaps = {pcap[0:-5:] for pcap in os.listdir(pcap_path) if pcap[-5::] == ".pcap"}

    if len(pcaps) == 0:
        print(
            f"No PCAP files to convert in {pcap_path}"
        )
        return False

    # Check flow directory exists, if not, make it, and get existing flows

    flow_path = f"{pwd}/flows"

    if not os.path.isdir(flow_path):
        os.mkdir(flow_path)

    existing_flows = {flow[0:-4:] for flow in os.listdir(flow_path) if flow[-4::] == ".csv"}

    # Prevent existing flows from being duplicated

    for flow in existing_flows:
        if flow in pcaps:
            pcaps.remove(flow)
    
    return True


def tBag(
        pwd: str
    ) -> bool:

    print()

    if not validate(pwd=pwd):
        return False

    pcap_path = f"{pwd}/pcap"
    flow_path = f"{pwd}/flows"

    pcaps = {pcap[0:-5:] for pcap in os.listdir(pcap_path) if pcap[-5::] == ".pcap"}

    # Generate flows

    for pcap in pcaps:
        new_name = pcap.replace("-tcpdump", "")
        try:
            os.system(f"./usr/share/data/Flowtbag_mac {pcap_path}/{pcap}.pcap > {flow_path}/{new_name}.csv")
        except:
            print("Error creating flows")
            return False

    print(f"Done: {len(pcaps)} new flow files created")

    return True


def main() -> None:
    cwd = os.getcwd()
    print(cwd)
    tBag(
        pwd="/usr/share/data"
    )


if __name__ == "__main__":
    main()
