from __future__ import annotations

import subprocess
from time import time, sleep

from Forge.Network import Network
from Forge.Logger import Logger, logit
from Forge.ErrorCodes import ErrorCode, ContainerCommandError


class Container:

    def __init__(
            self,
            # Startup
            name: str,
            image: str,
            volumes: list[str] = None,
            networking: dict = None,
            command: str = "",
            services: list[Container] = None,
            params: str = "",
            # Down
            down_command: str = "",
            # Info
            logger: Logger = None,
            is_service: bool = False,
            sandbox: bool = False,
            requires_sudo: bool = False,
            order: int = -1,
            intent: str = "",
            pwd: str = ""
        ) -> None:

        self.logger: Logger = Logger() if logger == None else logger
        self.logger.log(type="background")

        # Startup

        self.name: str = name
        self.image: str = image
        self.volumes: str = [] if volumes == None else volumes
        self.networks: dict = {} if networking == None else networking
        self.startup_cmd: str = command
        self.parents: list[Container] = []
        self.services: list[Container] = [] if services == None else services
        self.params: str = params

        # Down

        self.down_cmd: str = down_command

        # Info

        self.is_service: bool = is_service
        self.type: str = "Container" if not self.is_service else "Service"
        self.sandbox: bool = sandbox
        self.requires_sudo: bool = requires_sudo
        self.order: int = order
        self.intent: str = intent
        self.pwd: str = pwd

        # Active

        self.time_started: float = time()
        self.running: bool = False
        self.intent_history: list[tuple[float, str, str, str]] = []
        self.dependents: list[Container] = []

        for service in self.services:
            service.registerParent(self)

        return
    
    def __repr__(self) -> str:
        return f"{self.type} {self.name}"
    
    @logit
    def registerParent(self, container: Container) -> None:
        self.parents.append(container)
        return
    
    @logit
    def registerDependent(self, container: Container) -> None:
        self.dependents.append(container)
        return
    
    @logit
    def markIntent(self, root_intent: str, intent: str, time: time, target: str = "") -> None:
        self.intent_history.append((time, root_intent, intent, target))
        return
    
    @logit
    def checkParentsHealth(self, attempts: int = 3) -> tuple[bool, Container|None]:
        """
        Check all containers that this container is dependant on are running
        """
        
        count: int = 0
        for parent in self.parents:
            while not parent.running and count < attempts:
                count += 1
                self.logger.log(
                    message=f"Parent container '{parent.name}' for '{self.name}' is not running, attempt: {attempts}",
                    type="warning"
                )
                sleep(1)
            
            if count >= attempts:
                self.logger.log(
                    message=f"Failed to start container '{self.name}' due to inactive parent '{parent.name}'",
                    type="error"
                )
                return (False, parent)
            
            count = 0

        return (True, None)
    
    @logit
    def commit(self, command: str, throw: bool = False, root_intent: str = "", intent: str = "", target: str = "") -> bool:
        """
        Commit a command from startup, run, or stop
        """
        
        try:
            command = command.format(**locals())
        except Exception as e:
            print(f"Failed to format command: {command}")

        if self.requires_sudo: command = "sudo " + command

        start_time = time()
        self.logger.trail(command=command)
        if not self.sandbox:

            p = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

            if p.returncode != 0:
                if throw:
                    raise ContainerCommandError(
                        self.logger,
                        ErrorCode.ERR_CONTAINER_COMMAND_ERROR,
                        detail=f"{p.stderr.decode()}: {command}"
                    )
                else:
                    self.logger.log(
                        message=f" name: '{self.name}' command: '{command}' code: '{p.returncode}' message: '{p.stderr.decode()}'",
                        type="error"
                    )
                return False
            
        if root_intent: self.markIntent(root_intent=root_intent, intent=intent, time=start_time, target=target)
        return True

    @logit
    def start(self, alterations: dict = None) -> None:
        """
        Start the container
        """

        # Check containers this container depends on are running
        
        if not self.checkParentsHealth()[0]:
            return
        
        # Register this container as a dependent for auto shutdown when parent shuts down
        
        if not self.is_service:
            for parent in self.parents:
                parent.registerDependent(container=self)

        # Generate start command

        _nwk: str = f" --network={self.networks['network'].name}" if "network" in self.networks else ""
        _ports: str = f" -p {self.networks['ports']}" if "ports" in self.networks else ""
        _ip: str = f" --ip {self.networks['ip']}" if "ip" in self.networks else ""
        _v: str = ""
        for volume in self.volumes: _v += f" -v {volume}"
        if self.params != "" and self.params[0] != " ": self.params = f" {self.params}"
        _mode: str = f" --network=container:{self.parents[0].name}" if self.networks.get("mode", "") == "attach" else ""

        if alterations:
            if "_ip" in alterations:
                _ip = alterations["_ip"]

        runner: str = f"docker run --name {self.name}{_v}{_ports}{_ip}{_nwk}{_mode}{self.params} -itd {self.image}"

        # Commit command to start container

        self.logger.log(message=f"Starting {self.type}: {self.name} {runner}", type="info")

        if self.commit(command=runner, throw=True):

            # Set running and start time

            self.time_started = time()
            self.running = True

            self.logger.log(message=f"Started {self.type}: {self.name}", type="ok")

            # Start services

            for service in self.services:
                service.start()

            # Run startup command if applicable

            if self.startup_cmd: self.run(self.startup_cmd)
        
        return
    
    @logit
    def run(self,
            command: str,
            root_intent: str = "",
            intent: str = "",
            target: str = "",
            detach: bool = True,
            mode: str = ""
        ) -> bool:
        """
        Run a command on the active container
        """

        if not self.running:
            self.logger.log(
                message=f"Unable to run command '{command}' on inactive container '{self.name}'",
                type="warning"
            )
            return
        
        # if intent: self.markIntent(intent=intent)

        _mode = " -d" if detach else ""
        _mode = f" {mode}" if mode else _mode
        
        runner: str = f"docker exec{_mode} {self.name} {command}"

        self.logger.log(message=f"{self.type}: {self.name} running command: {command}", type="info")

        if self.commit(command=runner, root_intent=root_intent, intent=intent, target=target):
            self.logger.log(message=f"{self.type}: {self.name} ran command successfully", type="ok")
            return True
        
        return False
    
    @logit
    def disconnect(self) -> bool:
        if network := self.networks.get("network"):
            network_name: str = network.name
            runner: str = f"docker network disconnect {network_name} {self.name}"
            self.logger.log(
                message=f"{self.type}: {self.name} running command: {runner}",
                type="info"
            )
            if self.commit(command=runner, intent="NA", target="NA"):
                self.logger.log(
                    message=f"{self.type}: {self.name} ran command successfully",
                    type="ok"
                )
                return True
            
        return False
    
    @logit
    def connect(self, network: Network, ip: str="") -> bool:
        _ip = f" --ip {ip}" if ip else ""
        runner: str = f"docker network connect{_ip} {network.name} {self.name}"
        self.logger.log(
            message=f"{self.type}: {self.name} running command: {runner}",
            type="info"
        )
        if self.commit(command=runner, intent="NA", target="NA"):
            self.logger.log(
                message=f"{self.type}: {self.name} ran command successfully",
                type="ok"
            )
            network.addNetworkRule(self.name, **network.base_conditions)
            return True

        return False
    
    @logit
    def stop(self) -> None:
        """
        Stop the active container
        """

        if not self.running:
            self.logger.log(
                message=f"Didn't stop already inactive container '{self.name}'",
                type="warning"
            )
            return
        
        # Bring down any services

        for service in self.services:
            if service.running:
                service.stop()

        # Bring down any dependents

        for dependent in self.dependents:
            if dependent.running:
                dependent.stop()

        # If theres a command to run on down, run it

        if self.down_cmd: self.run(self.down_cmd, intent="sys")

        runner: str = f"docker stop {self.name} && docker rm {self.name}"

        self.logger.log(message=f"Stopping {self.type}: {self.name}", type="info")

        if self.commit(command=runner):

            self.running = False

            self.logger.log(message=f"Stopped {self.type}: {self.name}", type="ok")
        
        return
    
    def getInfo(self) -> dict:
        return {
            "name": self.name,
            "parents": self.parents,
            "dependents": self.dependents,
            "services": self.services
        }
    

def main() -> None:
    return


if __name__ == "__main__":
    main()
