import os
from threading import Lock
from time import sleep
from random import randint

from Forge.Container import Container
from Forge.Network import Network
from Forge.Logger import Logger, logit


class Traffic:

    in_use_octets = set()
    octet_lock = Lock()

    def __init__(self,
        container: Container,
        network: Network,
        container_command: str,
        capture_dir: str,
        options: dict,
        logger: Logger = Logger(),
        dump_command: str = None,
    ):
        """
        options: {
            'root_intent': str,
            'intent': str,
            'target': str,
            'subnet': str (192.168.0),
            'forward_via': dict [optional] {
                'to': str,
                'via': str
            },
            'network_conditions': dict [optional] {
                'delay': float,
                'delay_deviation': float,
                'perc_loss': float,
                'distribution': str,
                'perc_corrupt': float
            }
        }
        """
        self.container: Container = container
        self.network: Network = network
        self.container_command: str = container_command
        self.capture_dir = capture_dir
        self.options: dict = options

        self.logger: Logger = logger
        self.dump_command: str = "" if dump_command == None else dump_command

        self.octet: int = -1
        self.octet = self.getOctet()
        self.files: list[str] = []
        self.dump_container: Container = self.container.services[0]
        self.generate_traffic: bool = True

    def getOctet(self) -> int:

        with self.octet_lock:

            try: self.in_use_octets.remove(self.octet)
            except KeyError: pass

            octet: int = randint(25, 250)
            while octet in self.in_use_octets:
                octet: int = randint(25, 250)
            self.in_use_octets.add(octet)

            sleep(0.5)

        return octet
    
    @logit
    def hopIP(self) -> None:
        success: bool = False
        while not success and self.generate_traffic:
            self.container.disconnect()
            self.octet = self.getOctet()
            ip: str = f"{self.options['subnet']}.{self.octet}"
            success = self.container.connect(
                network=self.network,
                ip=ip
            )
            if not success:
                self.logger.log(
                    message=f"Container {self.container.name} failed to connect to network {self.network.name} with IP {ip}",
                    type="warning"
                )
            sleep(3)

        if "forward_via" in self.options:
            self.container.run(
                command=f"/bin/sh -c 'ip route add {self.options['forward_via']['to']} via {self.options['forward_via']['via']}'"
            )

        # if "network_conditions" in self.options:
        #     self.network.addNetworkRule(
        #         self.container.name,
        #         **self.options["network_conditions"]
        #     )

        return
    
    @logit
    def run(self) -> None:
        count: int = 0
        while self.generate_traffic:
            self.hopIP()
            sleep(2)
            if self.dump_command:
                to_run = self.dump_command.format(**locals())
                self.dump_container.run(
                    command=to_run
                )
            sleep(2)
            self.container.run(
                command=self.container_command,
                root_intent=self.options["root_intent"],
                intent=self.options["intent"],
                target=self.options["target"],
                detach=False
            )
            sleep(2)
            self.files.append(f"{self.capture_dir}/data/pcap/{self.container.name}-tcpdump-{count}.pcap")
            count += 1
            
        return

    @logit
    def mergePCAP(self) -> None:
        cmd_files = " ".join(self.files)
        os.system(f"mergecap -w {self.capture_dir}/data/pcap/{self.container.name}-tcpdump.pcap {cmd_files}")
        for file in self.files:
            os.system(f"rm -f {file}")
        return
    

def main() -> None:
    return


if __name__ == "__main__":
    main()