from collections import defaultdict
import json
import os
import copy

from Forge.Network import Network
from Forge.Container import Container
from Forge.Validator import SchemaValidator
from Forge.Logger import Logger, logit
from Forge.ErrorCodes import ErrorCode, SchemaValidationError


def getStartOrder(dependencies: dict) -> list[str]:
    graph = defaultdict(list)
    visited = {}
    stack = []

    # Build the dependency graph
    for item, deps in dependencies.items():
        for dep in deps:
            graph[dep].append(item)

    def visit(node):
        if node in visited:
            return
        visited[node] = True
        for neighbor in graph.get(node, []):
            visit(neighbor)
        stack.append(node)

    # Visit all nodes
    for node in set(dependencies.keys()).union(*dependencies.values()):
        visit(node)

    # Reverse the stack to get the start order
    return stack[::-1]


class Context:

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

        self.schema: dict[str, dict] = {}

        self.networks: dict[str, Network] = {}
        self.containers: dict[str, Container] = {}

        self.dependencies: dict[str, list[str]] = {}
        self.start_order: list[str] = []
        self.disabled_containers: set[str] = set()

        self.schema_success: bool = False

        self.schema_validator: SchemaValidator = None

        self.initSchema()

        return

    @logit
    def readSchema(self) -> None:

        schema_path: str = f"{self.pwd}/schema.json"

        if not os.path.exists(schema_path):
            raise SchemaValidationError(self.logger, ErrorCode.ERR_NO_SCHEMA_FILE, detail=f"{schema_path}")

        with open(schema_path, "r") as json_file:
            self.schema = json.loads(json_file.read())

        return
    
    @logit
    def validateSchema(self) -> None:

        self.readSchema()
        self.schema_validator = SchemaValidator(self.logger, self.schema)
        self.schema_validator.validateSchema()

        return
    
    @logit
    def createNetworks(self, networks: dict) -> None:

        for network in networks:
            self.networks.update({network: Network(
                name=network,
                logger=self.logger,
                sandbox=self.sandbox,
                requires_sudo=self.requires_sudo,
                **networks[network]
            )})

        return
    
    @logit
    def createContainer(self, name: str, container: dict) -> Container:

        if volumes := container.get("volumes"):
            for volume in volumes:
                path = volume.split(":")[0].format(**locals())
                if not os.path.isdir(path):
                    self.logger.trail(command=f"mkdir {path}")
                    try:
                        os.makedirs(path, exist_ok=True)
                    except FileExistsError:
                        print("File exists error despite 'exists_ok=True'")
                    self.logger.log(
                        message=f"Created directory at '{path}'",
                        type="info"
                    )

        if network := container.get("networking", {}).get("network"):
            container["networking"]["network"] = self.networks[network]
        else:
            self.logger.log(message=f"No network specified in container '{container['name']}'", type="info")

        self.containers.update({name: Container(**container)})

        self.logger.log(
            message=f"Created container {name}",
            type="ok"
        )

        return self.containers[name]

    @logit
    def createContainers(self, container_name: str) -> None:
        
        container: dict = self.schema["containers"][container_name]

        if services := container.get("services"):

            created_services: list[Container] = []
            for service_name in services:
                
                service: dict = self.schema["services"][service_name].copy()
                service.update({
                    "name": f"{container_name}-{service_name}",
                    "logger": self.logger,
                    "sandbox": self.sandbox,
                    "is_service": True,
                    "requires_sudo": self.requires_sudo,
                    "pwd": self.pwd
                })
                created_services.append(self.createContainer(name=f"{container_name}-{service_name}", container=service))

            container["services"] = created_services

        if depends_on := container.get("depends_on"):
            
            deps = []
            for dep in depends_on:
                if dep not in self.disabled_containers:
                    deps.append(dep)

            self.dependencies.update({container_name: deps})
            container.pop("depends_on")

        # TODO: Using depends_on for a container that has clones doesn't work
        
        if "depends_on" in container:
            container.pop("depends_on")

        if "clones" in container:
            container.pop("clones")

        if "enabled" in container:
            container.pop("enabled")

        container.update({
            "name": container_name,
            "logger": self.logger,
            "sandbox": self.sandbox,
            "requires_sudo": self.requires_sudo,
            "pwd": self.pwd
        })

        self.createContainer(name=container_name, container=container)

        return
    
    @logit
    def initSchema(self) -> None:

        self.logger.log(
            message="Starting schema init",
            type="info"
        )

        if not self.schema_success:
        
            self.validateSchema()

            if network_schema := self.schema.get("networks"):
                self.createNetworks(networks=network_schema)

            for container_name in self.schema["containers"].copy():

                enabled: bool = True
                if "enabled" in self.schema["containers"][container_name]:
                    # print("Found enabled condition")
                    if not self.schema["containers"][container_name]["enabled"]:
                        # print(f"Removed {container_name}")
                        enabled = False
                        self.schema["containers"].pop(container_name)
                        self.disabled_containers.add(container_name)
                
                if enabled:
                    if clones := self.schema["containers"][container_name].get("clones"):

                        container: dict = self.schema["containers"][container_name].copy()

                        self.schema["containers"].pop(container_name)

                        for clone in range(clones):

                            self.schema["containers"].update({f"{container_name}-{clone}": copy.deepcopy(container)})

            for container_name in self.schema["containers"]:

                # print(f"Creating {container_name}")

                self.createContainers(container_name=container_name)

            for container_name, parents in self.dependencies.items():
                for parent in parents:
                    # if parent in self.disabled_containers:
                    #     continue
                    try:
                        self.containers[container_name].registerParent(self.containers[parent])
                    except KeyError:
                        self.logger.log(
                            message=f"Failed to find parent {parent} for {container_name}\ncontainers: {self.containers.keys()}",
                            type="error"
                        )
                        exit()

            self.start_order = getStartOrder(self.dependencies)

        self.logger.log(
            message="Schema init success",
            type="ok"
        )

        self.schema_success = True

        return
    
    def getContainers(self) -> dict[str, Container]:
        return self.containers
    
    def getNetworks(self) -> dict[str, Network]:
        return self.networks
    
    def getStartOrder(self) -> list[str]:
        if self.start_order == []:
            return [con.name for con in self.containers.values() if not con.is_service]
        return self.start_order


def main() -> None:
    path = os.getcwd()
    print(path)
    logger = Logger(rolling_messages=True)
    context = Context(pwd=f"{path}/src", logger=logger, sandbox=True)
    context.validateSchema()
    context.initSchema()

    print(context.dependencies)
    
    print(context.containers["apache"].getInfo())
    print(context.containers["nmap"].getInfo())
    print(context.containers["requests"].getInfo())

    return


if __name__ == "__main__":
    main()
