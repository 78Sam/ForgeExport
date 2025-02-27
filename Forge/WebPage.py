import os
import json
import pandas as pd
import datetime

from Forge.Logger import Logger, logit
from Forge.Context import Context


def readData(logger: Logger, pwd: str) -> dict:

    test_results_dir: str = f"{pwd}/data/test-results"

    # Check results folder exists

    if not os.path.isdir(test_results_dir):
        logger.log(
            message=f"No test results directory at '{test_results_dir}'",
            type="warning"
        )
        return {}

    test_results_folders: list[str] = os.listdir(test_results_dir)

    # Check results folder has items

    if len(test_results_folders) == 0:
        logger.log(
            message="Results directory is empty",
            type="error"
        )
        return {}

    data_points: dict = {}

    for test in test_results_folders:

        test_folder: str = f"{test_results_dir}/{test}"

        if os.path.isdir(test_folder):

            result: str = sorted([result for result in os.listdir(test_folder) if result[-8::] == ".results"])[-1]

            logger.log(
                message=f"Selected result file: {result}",
                type="info"
            )

            with open(f"{test_folder}/{result}", "r") as result_file:

                data: dict = json.loads(result_file.read())
                if data:
                    key: str = list(data.keys())[0]
                    data_points.update({key: data[key]})

    return data_points


def getFlowStatistics(logger: Logger, pwd: str) -> dict:

    flow_path: str = f"{pwd}/data/flows"

    if not os.path.exists(flow_path):
        logger.log(
            message=f"Unable to find flow directory at '{flow_path}' flow statistics will be disabled",
            type="warning"
        )
        return {}
    
    flow_files: list[str] = [f"{flow_path}/{flow}" for flow in os.listdir(flow_path) if flow[-4::] == ".csv"]

    logger.log(
        message=f"Found flows: {flow_files}",
        type="info"
    )

    if len(flow_files) == 0:
        logger.log(
            message=f"Unable to find any flow files in '{flow_path}' flow statistics will be disabled",
            type="warning"
        )
        return {}
    
    stats: dict = {}
    
    df: pd.DataFrame = pd.concat(map(pd.read_csv, flow_files))

    # nums_unique = df.nunique()

    # print(nums_unique)

    unique_ips: int = int(pd.concat([df["Src IP"], df["Dst IP"]]).nunique())
    unique_ports: int = int(pd.concat([df["Src Port"], df["Dst Port"]]).nunique())

    attack_rows: pd.DataFrame = df.loc[df["RootIntent"] == "Attack"]
    attack_rows_with_target = attack_rows.dropna(subset=["Target"])
    benign_rows: pd.DataFrame = df.loc[df["RootIntent"] == "Benign"]

    # print(type(attack_rows.iloc[5]["Target"]))

    # print(attack_rows_with_target)

    stats.update({
        "total_flows": len(df.index),
        "total_ips": unique_ips,
        "total_ports": unique_ports,
        "total_attack_flows": len(attack_rows),
        "total_benign_flows": len(benign_rows),
        "total_attack_descriptors": int(attack_rows.nunique()["Intent"]),
        "total_attack_targets": int(attack_rows_with_target.nunique()["Target"])
    })

    stats.update({
        "total_unlabelled_flows": stats["total_flows"]-stats["total_attack_flows"]-stats["total_benign_flows"]
    })

    return stats


def getImageData(context: Context, logger: Logger, pwd: str) -> list:

    containers_data: list[dict] = []
    for container_name, container in context.getContainers().items():
        containers_data.append({"name": container_name, "image": container.image})

    return containers_data

def createWebpage(context: Context, logger: Logger, pwd: str) -> bool:

    test_results: dict = readData(logger=logger, pwd=pwd)
    flow_statistics: dict = getFlowStatistics(logger=logger, pwd=pwd)
    image_data: list[dict] = getImageData(context=context, logger=logger, pwd=pwd)

    result_html: str = ""
    with open(f"{os.getcwd()}/Forge/template.html") as template_file:
        result_html = template_file.read()

    for key, value in flow_statistics.items():
        result_html = result_html.replace("{{" + key + "}}", str(round(value, 4)))

    result_html = result_html.replace("{{capture_name}}", os.path.basename(pwd))
    result_html = result_html.replace("{{capture_date}}", datetime.datetime.now().strftime("%H:%M %d-%m-%Y"))

    nav_links: list[tuple[str, str]] = [("#data-section-general", "General")]

    sniff_tooltips: dict[str, str] = {
        "BackwardPacketsSniff": "",
        "CosineSniff": "",
        "BackwardPacketsSniff": "",
        "BackwardPacketsSniff": "",
    }

    test_results_html: str = ""
    for key, value in test_results.items():
        nav_links.append((f"#data-section-{key}", key))
        test_results_html += f"\t\t\t<div class='data-section' id='data-section-{key}'>\n"
        test_results_html += f"\t\t\t\t<h1>\n\t\t\t\t{key}\n\t\t\t</h1>\n"
        for sub_test, result in value.items():
            test_results_html += f"\t\t\t\t<div class='datapoint'>\n"
            test_results_html += f"\t\t\t\t\t<span>\n"
            test_results_html += f"\t\t\t\t\t\t<h2>{sub_test}</h2>\n"
            # num = [round(x, 4) for x in result] if type(result) == list else round(result, 4)
            test_results_html += f"\t\t\t\t\t\t<h2 class='number'>{result}</h2>\n"
            test_results_html += f"\t\t\t\t\t</span>\n"
            test_results_html += f"\t\t\t\t\t<p class='hint'>Tooltip</p>\n"
            test_results_html += f"\t\t\t\t</div>\n"
        test_results_html += f"\t\t\t</div>\n\n"

    result_html = result_html.replace("<!-- test_results -->", test_results_html)

    nav_links.append(("#data-section-images", "Images"))
    image_results_html: str = f"\t\t<div class='data-section' id='data-section-images'>\n"
    image_results_html += f"\t\t\t\t<h1>\n\t\t\t\tImages\n\t\t\t</h1>\n"
    for container in image_data:
        image_results_html += f"\t\t\t\t<div class='datapoint'>\n"
        image_results_html += f"\t\t\t\t\t<span>\n"
        image_results_html += f"\t\t\t\t\t\t<h2>{container['name']}</h2>\n"
        # image_results_html += f"\t\t\t\t\t\t<h2 class='number'>{round(result, 4)}</h2>\n"
        image_results_html += f"\t\t\t\t\t</span>\n"
        image_results_html += f"\t\t\t\t\t<p class='hint'>{container['image']}</p>\n"
        image_results_html += f"\t\t\t\t</div>\n"
    image_results_html += f"\t\t\t</div>"

    result_html = result_html.replace("<!-- image_results -->", image_results_html)

    nav_html: str = ""
    for nav_link in nav_links:
        nav_html += f"\t\t\t\t<a href='{nav_link[0]}'>{nav_link[1]}</a>\n"

    result_html = result_html.replace("<!-- nav-links -->", nav_html)
    
    if os.path.exists(f"{pwd}/data/results.html"):
        os.remove(f"{pwd}/data/results.html")

    with open(f"{pwd}/data/result.html", "w") as result_file:
        result_file.write(result_html)

    # print(result_html)

    return True


def main() -> None:
    return


if __name__ == "__main__":
    main()
