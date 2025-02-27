import os
import pandas as pd
import datetime
import subprocess
from threading import Thread
from time import sleep, time

from Forge.Container import Container
from Forge.Network import Network
from Forge.Logger import Logger, logit
from Forge.Context import Context
from Forge.TBag import tBag
from Forge.TestRunner import runTests
from Forge.WebPage import createWebpage


def parse_time(x):
    try:
        return datetime.datetime.strptime(x, "%Y-%m-%d %H:%M:%S.%f %z %Z").timestamp()
    except ValueError:
        return datetime.datetime.strptime(x, "%Y-%m-%d %H:%M:%S %z %Z").timestamp()


class Controller:

    def __init__(
            self,
            pwd: str,
            logger: Logger = Logger(),
            sandbox: bool = False,
            requires_sudo: bool = False
        ) -> None:

        self.pwd: str = pwd
        self.logger: Logger = logger
        self.sandbox: bool = sandbox
        self.requires_sudo: bool = requires_sudo

        self.context: Context = Context(
            pwd=self.pwd,
            logger=self.logger,
            sandbox=self.sandbox,
            requires_sudo=self.requires_sudo
        )

        return
    
    @logit
    def startNetworks(self) -> None:
        """
        Create and start all networks
        """
        for network in self.context.getNetworks().values():
            network.createNetwork()
        return
    
    @logit
    def removeNetworks(self) -> None:
        """
        Stop and delete all networks
        """
        for network in self.context.getNetworks().values():
            network.removeNetwork()
        return
    
    @logit
    def start(self) -> None:
        """
        Start all containers
        """
        containers: dict[str, Container] = self.context.getContainers()
        for container_name in self.context.getStartOrder():
            containers[container_name].start()

        return
    
    @logit
    def tearDown(self, parallel_teardown: bool = True) -> None:
        """
        Stop and remove all containers
        """
        t1 = time()
        containers: dict[str, Container] = self.context.getContainers()
        if not parallel_teardown:
            for container_name in self.context.getStartOrder()[::-1]:
                containers[container_name].stop()
        else:
            shutdown: set[str] = set()
            ths = []
            for container_name in containers:
                if containers[container_name].dependents == [] and not containers[container_name].is_service:
                    # print(f"Threading {container_name} {containers[container_name].dependents}")
                    ths.append(Thread(target=lambda: containers[container_name].stop(), daemon=True))
                    ths[-1].start()
                    shutdown.add(container_name)

            for thread in ths:
                while thread.is_alive():
                    # print("Waitin for thread to finish")
                    self.logger.log(
                        message="Waiting for threads to finish",
                        type="info"
                    )
                    sleep(2)

            for container_name in self.context.getStartOrder()[::-1]:
                if container_name in shutdown:
                    continue
                containers[container_name].stop()

        self.logger.log(
            message=f"Teardown took {round((time()-t1)/60, 2)} minutes",
            type="ok"
        )
        # print(f"Teardown took {round((time()-t1)/60, 2)} minutes")

        return
    
    @logit
    def createFlows(self) -> None:
        """
        Create flows from the captured data
        """
        if not tBag(self.logger, self.pwd):
            return
        
        self.markFlows()

        return
    
    @logit
    def markFlows(self) -> None:
        
        flow_path: str = f"{self.pwd}/data/flows"
        existing_flows: set[str] = {flow[0:-4:] for flow in os.listdir(flow_path) if flow[-4::] == ".csv" and "-updated" not in flow}

        # Get all container command intents (Except for tcpdump)

        intent_historys: dict[str, list[tuple[float, str, str, str]]] = {}
        for name, container in self.context.getContainers().items():
            if "tcpdump" in name:
                continue
            intent_historys.update({name: container.intent_history})

        #! Manually insert intents here if needed

        intent_historys = {
            "nginx-tcpdump": [],
            "nginx": [],
            "siege-0-tcpdump": [],
            "siege-0": [(1739896586.668611, 'Attack', 'Stress', 'nginx')],
            "siege-1-tcpdump": [],
            "siege-1": [(1739896586.771467, 'Attack', 'Stress', 'nginx')],
        }

        # Add command intents, targets, and command received froms to dataframes
        
        flow_tables: dict[str, pd.DataFrame] = {}
        for flow in existing_flows:

            self.logger.log(f"Inserting intents into {flow}", type="info")

            try:
                new_df: pd.DataFrame = pd.read_csv(f"{flow_path}/{flow}.csv")
            except pd.errors.EmptyDataError:
                self.logger.log(
                    message=f"Failed to read flow file '{flow}', no data",
                    type="error"
                )
                # existing_flows.pop(flow)
                continue
            
            new_df["RootIntent"] = ["NA" for _ in range(len(new_df.index))]
            new_df["Intent"] = ["NA" for _ in range(len(new_df.index))]
            new_df["Target"] = ["NA" for _ in range(len(new_df.index))]
            new_df["From"] = ["NA" for _ in range(len(new_df.index))]

            # Change time format to float

            new_df["Process Time"] = new_df["Process Time"].apply(parse_time)

            # Add command intents to dataframe

            for intent in intent_historys[flow]:
                for i in new_df.index:
                    if new_df.at[i, "Process Time"] > intent[0]:
                        if intent[1]: new_df.at[i, "RootIntent"] = intent[1]
                        if intent[2]: new_df.at[i, "Intent"] = intent[2]
                        if intent[3]: new_df.at[i, "Target"] = intent[3]

            flow_tables.update({flow: new_df})

        # Mark targets with command intent of other containers

        self.markTargets(flow_tables)

        # Change time formatting back

        for table in flow_tables.values():
            table["Process Time"] = table["Process Time"].apply(
                lambda x: (datetime.datetime.fromtimestamp(x)).strftime("%Y-%m-%d %H:%M:%S.%f +0000 UTC")
            )

        # Write updated flows

        self.logger.log(f"Writing flows", type="info")
        
        for flow in flow_tables.keys():
            flow_tables[flow].sort_values("Process Time").to_csv(f"{flow_path}/{flow}-updated.csv", sep=",", index=False)
            os.remove(f"{flow_path}/{flow}.csv")

        self.logger.log(f"Finished flow creation", type="ok")

        return
    
    @logit
    def markTargets(self, flow_tables: dict[str, pd.DataFrame]) -> None:
        
        for flow_name, flow_frame in flow_tables.items():
            container: Container = self.context.containers[flow_name]

            # Get network conditions if applicable for use in row identification

            network_conditions: dict[str, float] = {"delay": 0.0, "loss": 0.0}
            if network_name := container.networks.get("network").name:
                #! These network conditions may already be set to 0 once the scenario is torn down
                network_conditions = self.context.networks[network_name].getContainerConditions(container.name)
            else:
                self.logger.log(
                    message=f"Container {flow_name} doesn't seem to be connected to a network",
                    type="warning"
                )

            # Loop through each flow row in the source containers flows

            for i in flow_frame.index:
                
                root_intent = flow_frame.at[i, "RootIntent"]
                intent = flow_frame.at[i, "Intent"]
                target = flow_frame.at[i, "Target"]
                
                if target == "NA" or root_intent == "NA" or target not in flow_tables or target == flow_name:
                    continue

                # Create identification mapping

                mapping = (
                    flow_frame.at[i, "Process Time"],
                    flow_frame.at[i, "Src IP"],
                    flow_frame.at[i, "Dst IP"],
                    flow_frame.at[i, "Src Port"],
                    flow_frame.at[i, "Dst Port"],
                    flow_frame.at[i, "Protocol"],
                )

                # Get target dataframe rows from mapping and mark them

                flow_tables[target].loc[
                    (flow_tables[target]["Process Time"] - 0.5 - network_conditions["delay"] <= mapping[0]) &
                    (mapping[0] <= flow_tables[target]["Process Time"] + 0.5 + network_conditions["delay"]) &
                    (flow_tables[target]["Src IP"] == mapping[1]) &
                    (flow_tables[target]["Dst IP"] == mapping[2]) &
                    (flow_tables[target]["Src Port"] == mapping[3]) &
                    (flow_tables[target]["Dst Port"] == mapping[4]) &
                    (flow_tables[target]["Protocol"] == mapping[5]), ["RootIntent", "Intent", "From"]
                ] = [root_intent, intent, flow_name]

        return
    
    @logit
    def writeTrail(self, out: str) -> None:

        trail = self.logger.getTrail()
        out_trail = "#!/bin/bash\n\n"

        for command in trail:
            out_trail += f"{command}\n"

        out = out.replace(".sh", "")

        shell_file = f"{self.pwd}/{out}.sh"

        with open(shell_file, "w") as out_file:
            out_file.write(out_trail)

        subprocess.run(f"chmod +x {shell_file}", shell=True, check=True)

        return
    
    @logit
    def writeIntents(self, path: str) -> None:
        intents: str = "{\n"
        for container_name, container in self.context.containers.items():
            intents += f'\t"{container_name}": {container.intent_history},\n'
        intents += "}"
        with open(f"{self.pwd}/{path}", "w") as intents_file:
            intents_file.write(intents)
        return
        
    @logit
    def executeTests(self) -> None:
        runTests(self.logger, self.pwd)
        return
    
    @logit
    def genWebpage(self) -> None:
        createWebpage(self.context, self.logger, self.pwd)
        return
    
    @logit
    def complete(self,
            trail: str = "",
            intents: str = "",
            skip_teardown = False,
            skip_networks = False,
            skip_intents = False, 
            skip_trail = False, 
            skip_flows = False,
            skip_tests = False,
            skip_webpage = False
        ) -> None:
        if not skip_teardown: self.tearDown()
        if not skip_networks: self.removeNetworks()
        if not skip_intents: self.writeIntents(intents)
        if not skip_trail: self.writeTrail(trail)
        if not skip_flows: self.createFlows()
        if not skip_tests: self.executeTests()
        if not skip_webpage: self.genWebpage()
        return

    
def main() -> None:

    logger: Logger = Logger(
        rolling_messages=True,
        interesting_only=True
    )

    controller: Controller = Controller(
        # pwd=f"{os.getcwd()}/captures/capture-nmap-loss",
        pwd=f"{os.getcwd()}/scenarios/scenario-nmap-loss",
        logger=logger,
        sandbox=False,
        requires_sudo=False
    )

    controller.markFlows()

    return


if __name__ == "__main__":
    main()
