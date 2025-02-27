import subprocess
import docker
from time import time

from Forge.Logger import Logger, logit
from Forge.ErrorCodes import ErrorCode, NetworkCommandError


class Network:

    def __init__(
            self,
            name: str,
            driver: str,
            subnet: str = None,
            gateway: str = None,
            logger: Logger = Logger(),
            sandbox: bool = False,
            requires_sudo: bool = False,
            base_conditions: dict = None
        ):
        
        self.name: str = name
        self.driver: str = driver
        self.subnet: str = subnet if subnet else ""
        self.gateway: str = gateway if gateway else ""
        self.logger: Logger = logger
        self.sandbox: bool = sandbox
        self.requires_sudo: bool = requires_sudo

        self.network_id: str = ""

        self.veths: dict[str, str] = {}
        self.veths_last_computed: float = 0.0

        self.base_conditions: dict = {
            "delay": 0.0,
            "perc_loss": 0.0,
            "delay_deviation": 0.000001,
            "distribution": "normal",
            "perc_corrupt": 0.0
        } if not base_conditions else base_conditions

        self.network_conditions: dict[str, dict[str, float]] = {}

        self.veth_recompute_time: float = -1.0

        return

    @logit
    def commit(self, command: str, throw: bool = False, sudo: bool = False, format: bool = True) -> bool | subprocess.CompletedProcess:
        """
        Commit a command from startup, run, or stop
        """
        
        if format:
            command = command.format(**locals())

        if self.requires_sudo or sudo: command = "sudo " + command

        self.logger.trail(command=command)
        p = False
        if not self.sandbox:
            p = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

            if p.returncode == 2: # 2 is error for trying to delete non-existing rules, not an issue
                # self.logger.log(
                #     message=f" name: '{self.name}' command: '{command}' code: '{p.returncode}' message: '{p.stderr.decode()}'",
                #     type="warning"
                # )
                return False

            if p.returncode != 0 and p.returncode != 2:
                if throw:
                    raise NetworkCommandError(
                        self.logger,
                        ErrorCode.ERR_NETWORK_COMMAND_ERROR,
                        detail=p.stderr.decode()
                    )
                else:
                    self.logger.log(
                        message=f" name: '{self.name}' command: '{command}' code: '{p.returncode}' message: '{p.stderr.decode()}'",
                        type="error"
                    )
                return False

        return p

    @logit
    def createNetwork(self) -> None:
        _subnet: str = f" --subnet {self.subnet}" if self.subnet else ""
        _gateway: str = f" --subnet {self.gateway}" if self.gateway else ""
        runner: str = f"docker network create -d {self.driver}{_subnet}{_gateway} {self.name}"
        self.logger.log(
            message=f"Network {self.name} running command {runner}",
            type="info"
        )
        if self.commit(command=runner):
            try:
                client = docker.from_env()
                self.network_id = f"br-{client.networks.get(self.name).short_id}"
            except Exception as e:
                self.logger.log(
                    message=f"Failed to connect to docker sdk: {e}",
                    type="warning"
                )
            self.logger.log(
                message=f"Created network {self.name} successfully",
                type="ok"
            )
        return

    @logit
    def removeNetwork(self) -> None:
        runner: str = f"docker network rm {self.name}"
        if self.commit(command=runner):
            self.logger.log(
                message=f"Removed network {self.name} successfully",
                type="ok"
            )
        return
    
    @logit
    def getContainerVeths(self) -> bool:

        # print("CALCULATING VETHS")

        if self.sandbox:
            return True

        try:
            client = docker.from_env()
        except Exception as e:
            self.logger.log(
                message=f"Failed to connect to docker sdk: {e}",
                type="error"
            )
            return False
        
        containers = client.networks.get(self.name).containers

        for container in containers:
            name = container.name
            pid = container.attrs["State"]["Pid"]

            if not self.commit(
                command=f"mkdir -p /var/run/netns",
                sudo=True
            ): return False

            if not self.commit(
                command=f"ln -sf /proc/{pid}/ns/net '/var/run/netns/{name}'",
                sudo=True
            ): return False

            eth_no = self.commit(
                command=f"sudo ip netns exec '{name}' ip route show default | awk '/default/ {{print $5}}'",
                sudo=True,
                format=False
            ).stdout.decode().replace("\n", "")

            # print(eth_no, container.name)

            index = self.commit(
                command=f"sudo ip netns exec '{name}' ip link show {eth_no} | head -n1 | sed s/:.*//",
                sudo=True
            )

            if not index: return False

            try:
                index = int(index.stdout.decode().replace("\n", ""))+1
            except ValueError:
                self.logger.log(
                    message=f"Error decoding index: '{index}'",
                    type="error"
                )
                return False

            veth = self.commit(
                command=f"ip link show | grep '^{index}:' | sed 's/{index}: \\(.*\\):.*/\\1/'",
                sudo=True
            )

            if not veth: return False

            veth = veth.stdout.decode().replace("\n", "").split("@")[0]

            self.veths.update({name: veth})

            if not self.commit(
                command=f"rm -f '/var/run/netns/{name}'",
                sudo=True
            ): return False

        self.veths_last_computed = time()

        return True
    
    @logit
    def logNetworkConditions(self,
            container_name: str,
            delay: float,
            delay_deviation: float,
            perc_loss: float,
            distribution: str,
            perc_corrupt: float
        ) -> None:
        self.network_conditions.update({container_name: {
            "delay": delay,
            "loss": perc_loss,
            "delay_deviation": delay_deviation,
            "distribution": distribution,
            "perc_corrupt": perc_corrupt
        }})
        return
    
    @logit
    def checkVethComputation(self) -> bool:

        # If enough time has passed since we last computed container veths
        # compute them again

        if time() - self.veths_last_computed > self.veth_recompute_time:
            if not self.getContainerVeths():
                self.logger.log(
                    message=f"Failed to compute veths",
                    type="error"
                )
                return False
            
        return True
    
    @logit
    def removeNetworkRule(self, container_name: str) -> bool:

        # Check and potentially re-compute container veths

        if not self.checkVethComputation(): return False

        # Check the container is listed in the veths

        if container_name not in self.veths:
            self.logger.log(
                message=f"Failed to find container '{container_name}' to remove network rule",
                type="warning"
            )
            return False
        
        # Get the veth

        veth = self.veths[container_name]

        commit_result: bool = self.commit(
            command=f"tc qdisc del dev {veth} root",
            sudo=True
        )

        # This happens a lot as we try to remove before adding
        # but often there haven't been any rules applied yet

        if not commit_result:
            return False
        
        if container_name in self.network_conditions:
            self.network_conditions.pop(container_name)

        self.logger.log(
            message=f"Successfully removed all networking rules for {container_name}",
            type="ok"
        )

        return True
    
    @logit
    def addNetworkRule(self,
            container_name: str,
            delay: float,
            delay_deviation: float,
            perc_loss: float,
            distribution: str,
            perc_corrupt: float
        ) -> bool:

        # Log the network condition and return if in sandbox mode

        if self.sandbox:
            self.logNetworkConditions(container_name, delay, delay_deviation, perc_loss, distribution, perc_corrupt)
            return True
        
        # Check and potentially re-compute container veths
        
        if not self.checkVethComputation(): return False

        # Check the container is listed in the veths

        if container_name not in self.veths:
            self.logger.log(
                message=f"Failed to find container '{container_name}' to add network rule",
                type="warning"
            )
            return False
        
        # Remove and previously applied rules

        self.removeNetworkRule(container_name)

        # Get the veth

        veth = self.veths[container_name]

        # Commit the network condition

        commit_result: bool = self.commit(
            command=f"tc qdisc add dev {veth} root netem delay {delay}ms {delay_deviation}ms distribution {distribution} loss {perc_loss}% corrupt {perc_corrupt}%",
            sudo=True
        )

        if not commit_result:
            self.logger.log(
                message=f"Failed to add network rule to container '{container_name}'",
                type="warning"
            )
            return False
        
        # Condition success, log it
        
        self.logNetworkConditions(container_name, delay, delay_deviation, perc_loss, distribution, perc_corrupt)

        self.logger.log(
            message=f"Successfully added networking rule for {container_name}",
            type="ok"
        )

        return True
    
    @logit
    def addNetworkRules(self,
            delay: float,
            delay_deviation: float,
            perc_loss: float,
            distribution: str,
            perc_corrupt: float
        ) -> bool:
        
        # Update the base network conditions

        self.base_conditions = {
            "delay": delay,
            "perc_loss": perc_loss,
            "delay_deviation": delay_deviation,
            "distribution": distribution,
            "perc_corrupt": perc_corrupt
        }

        # Check and potentially re-compute container veths

        if not self.checkVethComputation(): return False

        # Add the rules

        for container_name in self.veths.keys():
            if not self.addNetworkRule(container_name, delay, delay_deviation, perc_loss, distribution, perc_corrupt):
                self.logger.log(
                    message=f"Failed to add networking rules for network {self.name}",
                    type="error"
                )
                return False
            
        return True
    
    @logit
    def setBaseConditions(self) -> bool:
        return self.addNetworkRules(**self.base_conditions)
    
    def getNetworkID(self) -> str:
        return self.network_id
    
    def getContainerConditions(self, container_name: str) -> dict[str, float]:
        if container_name in self.network_conditions:
            return self.network_conditions[container_name]
        else:
            return {"delay": 0.0, "loss": 0.0}
    

def main() -> None:
    return

if __name__ == "__main__":
    main()
