import os
import sys
import json
import datetime
import data_manip
import ml
from cli import CLI
import inspect


import sys
def trunc(path: str, times: int = 1):
    if times == 0: return path
    return trunc(path=os.path.dirname(path), times=times-1)
CAPTURE_DIR = trunc(os.path.abspath(__file__))
ROOT_DIR = trunc(CAPTURE_DIR, times=2)
sys.path.append(ROOT_DIR)
from Forge.Logger import Logger, logit


def writeOut(results, iden, path):
    now = datetime.datetime.now().strftime("%d-%m-%Y_%I-%M-%S")
    out_file = os.path.join(f"{path}/{iden}/{now}.results")
    os.makedirs(os.path.dirname(out_file), exist_ok=True)
    with open(out_file, "w+") as f:
        f.write(json.dumps(results))


def main(args):
    """
    Creates a new CLI object and starts parsing arguments.

    :param args: The provided arguments
    """
    try:
        logger: Logger = Logger(rolling_messages=True, interesting_only=False, background=True)
        cli = CLI(logger)
        cli.parse_arguments(args)
    except Exception as _:
        exc_type, _, exc_tb = sys.exc_info()
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        print(exc_type, fname, exc_tb.tb_lineno)

    if cli.args.metriclist:
        cli.processMetricListing()
        exit()

    if cli.args.snifflist:
        cli.processSniffTestListing()
        exit()

    if cli.args.list == True:
        print(cli.manipultor.processed_df[cli.manipulator.label_field].value_counts())
        exit()

    if cli.args.sniff != None:
        out = cli.chooseSniffTest()
        # START SAM
        logger.log(
            message=f"Sniff complete",
            type="ok"
        )
        print(out)
        writeOut(out, cli.args.sniff, cli.args.results)
        # END SAM
        exit()

    if cli.args.metric != None:
        out = cli.chooseMetric()
        print(out)
        exit()
        now = datetime.datetime.now().strftime("%Y-%d-%B-%I-%M-%S")
        out_file = os.path.join(cli.args.results, cli.args.target, "metrics", "{}_{}.results".format(cli.args.metric, now))
        os.makedirs(os.path.dirname(out_file), exist_ok=True)
        with open(out_file, "w+") as f:
            f.write(json.dumps(out))
    if cli.args.ids != None:
        ml.mlPipeline(cli.df, cli.metadata, cli.args.target, cli.args.ids, cli.args.results, cli.args.verbose)

if __name__ == "__main__":
    main(sys.argv[1:])
