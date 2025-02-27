import os
import sys
from time import sleep, time
from threading import Thread, Lock
from random import randint, random

def trunc(path: str, times: int = 1):
    if times == 0: return path
    return trunc(path=os.path.dirname(path), times=times-1)

CAPTURE_DIR = trunc(os.path.abspath(__file__))
ROOT_DIR = trunc(CAPTURE_DIR, times=2)
sys.path.append(ROOT_DIR)

from Forge.Context import Context
from Forge.Controller import Controller
from Forge.Logger import Logger
from Forge.Container import Container
from Forge.Network import Network
from Forge.Traffic import Traffic
from Forge.WebPage import createWebpage


def scenario(
        controller: Controller,
        containers: dict[str, Container],
        networks: dict[str, Network],
        pwd: str,
        logger: Logger,
        sandbox: bool,
    ) -> None:

    def exploit() -> None:

        # sleep(30)
        sleep(randint(0, 10))

        # Run nmap

        containers["exploit"].run(
            command="nmap 172.18.0.2 -oN /usr/share/capture/nmap.txt",
            root_intent="Attack",
            intent="nmap",
            target="wordpress",
            detach=False
        )

        print(f"Nmap complete: {round((time()-start_time)/60, 2)}m")

        # sleep(30)
        sleep(randint(0, 10))

        # Run dirb

        containers["exploit"].run(
            command="dirb http://172.18.0.2 -o /usr/share/capture/dirb.txt",
            root_intent="Attack",
            intent="dirb",
            target="wordpress",
            mode="-it"
        )

        print(f"dirb complete: {round((time()-start_time)/60, 2)}m")

        # sleep(30)
        sleep(randint(0, 10))

        # Run wpscan

        containers["exploit"].run(
            command="bash -c 'touch /usr/share/capture/wpscan.txt && wpscan --update > /dev/null && wpscan --url 172.18.0.2 --plugins-detection aggressive > /usr/share/capture/wpscan.txt'",
            root_intent="Attack",
            intent="wpscan",
            target="wordpress",
            mode="-it" #! WPScan will take literally an hour unless its set to interactive mode, who knows why
        )

        print(f"WPScan complete: {round((time()-start_time)/60, 2)}m")

        # sleep(30)
        sleep(randint(0, 10))

        # Run RCE

        containers["exploit"].run(
            command="bash -c 'chmod +x /usr/share/scripts/exfil_config.sh && /usr/share/scripts/exfil_config.sh'",
            root_intent="Attack",
            intent="rce_exfil_config",
            target="wordpress",
            detach=False
        )

        # sleep(30)
        sleep(randint(0, 10))

        containers["exploit"].run(
            command="bash -c 'chmod +x /usr/share/scripts/exfil_db.sh && /usr/share/scripts/exfil_db.sh'",
            root_intent="Attack",
            intent="rce_exfil_db",
            target="wordpress",
            detach=False
        )

        print(f"rce complete: {round((time()-start_time)/60, 2)}m")

        # sleep(30)
        sleep(randint(0, 10))

        return

    global GENERATE_TRAFFIC

    #! --- CAPTURE STARTUP ---

    try:
        os.system("./tools/clean.sh")
    except Exception as e:
        pass
    
    try:

        controller.startNetworks()

        controller.start()

        # NETWORK CONFIG

        containers["router"].connect(
            network=networks["lan"],
            ip="172.18.0.6"
        )

        networks["wan"].setBaseConditions()
        networks["lan"].setBaseConditions()

        for container in containers.values():

            if container.name in ["router", "mysql_server", "phpmyadmin"] or container.is_service:
                continue

            if container.networks["network"].name == "lan":
                container.run(
                    command="/bin/sh -c 'ip route add 192.168.0.0/16 via 172.18.0.6'"
                )
            else:
                container.run(
                    command="/bin/sh -c 'ip route add 172.18.0.0/16 via 192.168.0.6'"
                )

        startup_successful = True

    except Exception as e:
        logger.log(
            message=f"Failed to start scenario: {e}",
            type="error"
        )
        os.system(f"{ROOT_DIR}/tools/clean.sh")
        raise(e)
    
    # startup_successful = False

    if startup_successful:

        #! ====== MAIN SCENARIO ======

        input("Start?")

        sleep(5)

        start_time: float = time()

        #! Start multithreaded requests

        threads: dict[str, list[Thread, Traffic]] = {}
        for x in range(10):
            container_name: str = f"requests-{x}"
            inst = Traffic(
                container=containers[container_name],
                network=networks["wan"],
                container_command="python3 usr/share/scripts/req.py",
                capture_dir=CAPTURE_DIR,
                options={
                    "root_intent": "Benign",
                    "intent": "req",
                    "target": "wordpress",
                    "subnet": "192.168.0",
                    "forward_via": {
                        "to": "172.18.0.0/16",
                        "via": "192.168.0.6"
                    },
                    # "network_conditions": WAN
                },
                logger=logger,
                dump_command=f"/usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/{container_name}-tcpdump-{{count}}.pcap'"
            )
            threads.update({container_name: [Thread(target=lambda: inst.run(), daemon=True), inst]})
            threads[container_name][0].start()
            sleep(random()+0.2)

        container_name: str = "admin-requests"
        inst = Traffic(
            container=containers[container_name],
            network=networks["lan"],
            container_command="python3 usr/share/scripts/req.py",
            capture_dir=CAPTURE_DIR,
            options={
                "root_intent": "Benign",
                "intent": "admin",
                "target": "wordpress",
                "subnet": "172.18.0",
                "forward_via": {
                    "to": "192.168.0.0/16",
                    "via": "172.18.0.6"
                },
                # "network_conditions": LAN
            },
            logger=logger,
            dump_command=f"/usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/{container_name}-tcpdump-{{count}}.pcap'"
        )
        threads.update({container_name: [Thread(target=lambda: inst.run(), daemon=True), inst]})
        threads[container_name][0].start()

        # Start exploit commands

        exploit()

        sleep(2)

        # input("Finish?")

        # Stop multithreaded requests

        for thread in threads.values():
            thread[1].generate_traffic = False

        for thread in threads.values():
            while thread[0].is_alive():
                sleep(1)

        #! --- CAPTURE TEARDOWN ---

        print("Teardown")

        controller.tearDown()

        for thread in threads.values():
            thread[1].mergePCAP()

        controller.complete(
            trail="data/trail.sh",
            intents="data/intents.txt",
            skip_teardown=True,
            skip_flows=False,
            skip_intents=False,
            skip_trail=False,
            skip_tests=False,
            skip_webpage=False
        )

        # controller.markFlows()

        logger.log(
            message=f"Capture complete in {round((time()-start_time)/60, 2)} minutes",
            type="info"
        )

    logger.outLog(f"{pwd}/data/log.log")

    # controller.executeTests()

    return


def main() -> None:

    sandbox: bool = False

    logger = Logger(rolling_messages=True, filter=["error", "warning"])
    controller: Controller = Controller(
        pwd=CAPTURE_DIR,
        logger=logger,
        sandbox=sandbox,
        requires_sudo=False
    )
    context: Context = controller.context
    containers: dict[str, Container] = context.getContainers()
    networks = context.getNetworks()

    # scenario(
    #     controller=controller,
    #     containers=containers,
    #     networks=networks,
    #     pwd=CAPTURE_DIR,
    #     logger=logger,
    #     sandbox=sandbox
    # )

    controller.executeTests()

    createWebpage(context=context, logger=logger, pwd=CAPTURE_DIR)

    return


if __name__ == "__main__":
    main()
