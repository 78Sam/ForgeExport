import os
import json

from Forge.Logger import Logger


def runTests(logger: Logger, pwd: str) -> None:

    logger.log()

    if not os.path.isdir(pwd):
        logger.log(
            message=f"Provided path {pwd} doesn't exist",
            type="error"
        )
        return

    # Check flow path exists

    flow_path = f"{pwd}/data/flows"

    if not os.path.isdir(flow_path):
        logger.log(
            message=f"No flow directory at: {flow_path}",
            type="error"
        )
        return
    
    # Check some flows do exist
    
    existing_flows = {flow[0:-4:] for flow in os.listdir(flow_path) if flow[-4::] == ".csv"}

    if len(existing_flows) == 0:
        logger.log(
            message=f"No flows available in: {flow_path}",
            type="error"
        )
        return
    
    # Check that there is a config file for the tests and read it
    
    config_path = f"{pwd}/config.json"

    if not os.path.exists(config_path):
        logger.log(
            message=f"No config.json file found at: {pwd}/config.json",
            type="error"
        )
        return

    testing_data = {}
    with open(config_path, "r") as json_file:
        testing_data = json.loads(json_file.read())

    # Check that some tests have been selected to be run

    if not testing_data["tests"] or len(testing_data["tests"]) == 0:
        logger.log(
            message=f"No tests to run in: {config_path}",
            type="error"
        )
        return
    
    # Flag a default metadata config being available if there is one
    
    has_default_metadata = bool("default_metadata" in testing_data and testing_data["default_metadata"])

    for test in testing_data["tests"]:

        test_name = test["name"]

        if "enabled" in test and not test["enabled"]:
            continue

        if bool("metadata" in test and test["metadata"]):
            metadata = test["metadata"]
        elif has_default_metadata:
            metadata = testing_data["default_metadata"]
        else:
            logger.log(
                message=f"No metadata found for test: {test_name}, skipping test",
                type="warning"
            )
            continue

        # python3 ./src/netstats.py --metadata metadata/cic2018/metadata.json --results results/CIC18_trunc/ --target FTP-BruteForce --folder --csv data/CIC18_trunc/ --test CosineTest

        # whiff_path: str = f"{os.path.dirname(os.path.dirname(__file__))}/WhiffSuite"
        whiff_path: str = f"{os.path.dirname(os.path.dirname(__file__))}/WhiffSuite"

        # print(whiff_path)
        
        if not os.path.isdir(f"{whiff_path}/temp"):
            os.system(f"mkdir {whiff_path}/temp")

        with open(f"{whiff_path}/temp/temp_meta.json", "w") as temp_metadata_file:
            json.dump(metadata, temp_metadata_file)

        os.system(f"python3 {whiff_path}/src/whiff.py --metadata {whiff_path}/temp/temp_meta.json --results {pwd}/data/test-results/ --target Attack --csv {flow_path}/ --sniff {test_name}")

    return