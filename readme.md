# Forge: A Python-Based Docker Orchestration and Network Analysis Framework

Forge is a Python framework designed to facilitate design and implementation of scenarios using Docker under which network traffic is captured and analyzed. The core features of Forge are:
- Creating scenarios using Docker containers to represent real-world systems and interactions within them
- Programmatic real-time analysis of Docker resources such as containers
- Docker container and network command execution wrappers
- PCAP to flow conversion tools
- Flow labeling based on provided command intent (nmap-scan, attack, rce, etc.)
- Analysis and testing on produced flows for applicability in NIDS training
- Additional tooling such as extensive logging, shell script generation, and scenario results pages

## Credit

This project was built to replicate the functionality of DetGen, another synthetic network traffic generator that can be found here: [DetGen](https://github.com/detlearsom/detgen), under the supervision and guidance of David Aspinall and Robert Flood.

## Any Questions? Any Ideas?

If you have any: questions, ideas, improvements, examples of your benefit or use, please get in touch! You can find me here: [https://sam-mccormack.co.uk](https://sam-mccormack.co.uk)

## Requirements

It is recommended to use Linux for this framework, although I can run most scenarios on a Macbook M2 (excluding flow creation and network condition application)

- Python 3.10
- Docker
- tc-netem package if you wish to do network condition application

I have also included the flowtbag source code (PCAP to flow conversion tool) at `flowtbag` to recompile yourself if `tools/flowtbag` doesn't work.

There is also a simple shell script to create a Python venv for you to use at `setup.sh`.

## Contents

- [The Framework](#the-framework)
    - [Keywords and Terms](#keywords-and-terms)
    - [Key Files](#key-files)
        - [schema.json](#schemajson)
        - [capture.py](#capturepy)
    - [Required Conventions](#required-conventions)
        - [Containers](#containers)
        - [Scenarios](#scenarios)
        - [Schemas](#schemas)
    - [Quality of Life Tooling](#quality-of-life-tooling)
        - [Create Images](#create-images)
        - [Create Scenarios](#create-scenarios)
- [Your First Scenario](#your-first-scenario)
    - [The Schematic](#the-schematic)
    - [The Capture](#the-capture)
        - [Explaining Some Boilerplate Code](#explaining-some-boilerplate-code)
        - [The Meat](#the-meat)
        - [A Final Note](#a-final-note)
- [A Much More Complicated Scenario](#a-much-more-complicated-scenario)

<div style="page-break-after: always;"></div>

# The Framework

## Keywords and Terms

- `Forge`: A python-based framework for the specification, control,
and application of other tooling used within Docker container and network control.
- `Scenario`: A collection of Docker containers and networks controlled via Forge, working to produce some meaningful representation of one or both malicious and benign network traffic.
- `Schematic`: A JSON file that specifies all required information to start a scenario, including, but not limited to: Docker images and networks, dependencies, commands, volumes, etc.
- `Service`: A Docker container attached to another container that is brought up and down automatically with the container that it is attached to.
- `Intents`: The intention of a command run on a Docker container that generates network traffic. Some examples of intents are 'RootIntents' such as 'attack' or 'benign', or more fine grained 'Intents' such as 'nmap-scan' or 'rce-execution'. Intents are recorded along with the timestamp of when the command was run.

## Key Files

The forge framework is found in the `Forge` folder, the files you will interact with are:
- `Context.py` The Context primarily involves its self with the initialization and validation of your scenario schematic.
- `Controller.py` The Controller works to provide abstract interfaces for you to control your scenario, such as startup and teardown, it also works to provide interfaces for other tools such as PCAP to flow conversion.
- `Container.py` Python implementation of a Docker container, contains all the necessary information such as its image, IP, name etc. as well as providing functionality for running commands.
- `Network.py` Python implementation of a Docker network, contains all the necessary information such as bridge, subnet, gateway etc. as well as functions for things like container veth calculation, and network condition application.

### schema.json

`schema.json` is how Forge interprets and creates your scenario. Below you can find an example schema that contains all the available options for containers, services, and networks. To view or update acceptable values that wont be removed by `context.py` on initialization refer to `Forge/Validator.py.__init__`

>schema.json
```json

{
    "containers": {
        "CONTAINER NAME": {
            "ENABLED": true/false,
            "image": "IMAGE",
            "volumes": ["VOLUME"],
            "params": "PARAMS",
            "intent": "INTENT",
            "services": ["SERVICE NAME"],
            "depends_on": ["DEPENDS ON"],
            "CLONES": int,
            "networking": {
                "network": "NETWORK NAME",
                "ip": "IP",
                "ports": "PORTS",
                "mode": "MODE"
            }
        },
        "CONTAINER NAME": {...},
        ...
    },
    "services": {
        "SERVICE NAME": {
            "image": "IMAGE",
            "volumes": ["VOLUME"],
            "command": "STARTUP COMMAND",
            "down_command": "TEARDOWN COMMAND",
            "networking": {
                "network": "NETWORK NAME",
                "ip": "IP",
                "ports": "PORTS",
                "mode": "MODE"
            }
        },
        "SERVICE NAME": {...},
        ...
    },
    "networks": {
        "NETWORK NAME": {
            "driver": "DRIVER",
            "subnet": "SUBNET",
            "gateway": "GATEWAY",
            "base_conditions": {
                "delay": float,
                "delay_deviation": float,
                "perc_loss": float,
                "distribution": "DISTRIBUTION",
                "perc_corrupt": float
            }
        },
        "NETWORK NAME": {...},
        ...
    }
}

```

### capture.py

Capture files are much less constrained that schema files. Whilst its still recommended that you use the provided schematics in order to properly set everything up, after that its up to you!

## Required Conventions

In order for Forge to work properly please follow all these conventions, if you really want to deviate from them you will have to go through and change some of the code in files in `Forge`.

### Containers

Container folders must start with `docker-` and container a `Dockerfile` in order for cont.py to work.

### Scenarios

Scenario folders must start with `scenario-`.

Your schema file must be called `schema.json` and your testing config file must be called `config.json`

If you want to use Forges PCAP to flow conversion tools you must include a `data/pcap` directory in which your PCAP files should be contained.

### Schemas

Refer to [schemas](#schemajson) for information as to what you can put in `schema.json` files, however it must be in the provided format. Anything that is not listed will be removed unless you add the functionality for it yourself.

## Quality of Life Tooling

Forge provides some tools for Docker image management and scenario generation, these tools are entirely optional and are purely for quality of life, so if you don't find them useful don't worry about them.

### Create Images

Feel free to create Docker images however you like, however Forge does contain some tools for image creation. If you do decide to use Forges image tools:

- Create a new folder under `containers` called `docker-name` where name can be anything you find useful to refer to that image
- Create your relevant `Dockerfile` and any other resources required within your folder
- Run `containers/cont.py`
- Build or remove images as desired using the interface

### Create Scenarios

Much like Forges image management, you can create scenarios however you like[[1]](#aside), but we have provided some tools for quick setup. Running `tools/createCapture.py` will bring you to a scenario generation interface that only requires a name. After providing a name for your scenario, Forge will automatically create a folder and files for you under `scenarios`. Here you will find a folder called `scenario-name` where name is the input you provided. The two files that are generated are `capture.py` [capture](#capturepy) and `schema.json` [schema](#schemajson), whos purpose I will get into later. The schematic used to generate these files can be found under `tools/schemas` and can be edited to fit your needs.

[1]<a id="aside"></a> Whilst you can create scenarios how you like, its recommended to follow the naming and layout conventions used in other scenarios in order to maintain some consistency amongst your scenarios. However you **MUST** still respect some aspects of the naming conventions [requirements](#required-conventions) if you want Forge to work!

<div style="page-break-after: always;"></div>

# Your first scenario

Here I will present an example scenario, it employs three containers, two of those containers will be used to run the siege linux command on a third nginx container. We will also use a service called tcpdump in order to capture all the relevant network traffic generated. You can find this scenario at `scenarios/scenario-stress`.

## The Schematic

Starting with the scenario schema:

>scenarios/scenario-stress/schema.json
```json
{
    "containers": {
        "nginx": {
            "enabled": true,
            "intent": "Benign",
            "image": "forge/nginx",
            "volumes": ["{self.pwd}/environment:/usr/share/nginx/html"],
            "services": ["tcpdump"],
            "networking": {
                "network": "main",
                "ip": "192.168.0.5",
                "ports": "8080:80"
            }
        },
        "siege": {
            "enabled": true,
            "clones": 2,
            "intent": "Attack",
            "image": "forge/siege",
            "services": ["tcpdump"],
            "depends_on": ["nginx"],
            "networking": {
                "network": "main"
            }
        }
    },
    "services": {
        "tcpdump": {
            "image": "forge/tcpdump",
            "command": "/usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/{self.name}.pcap'",
            "down_command": "sh -c 'pkill tcpdump'",
            "volumes": ["{self.pwd}/data/pcap:/data/pcap"],
            "networking": {
                "mode": "attach"
            }
        }
    },
    "networks": {
        "main": {
            "driver": "bridge",
            "subnet": "192.168.0.0/24"
        }
    }
}
```

Schema files offer additional functionality beyond specifying standard Docker configurations, in this case these extra configurations are:
- `enabled` Should the container be brought up (useful for testing and debugging)?
- `intent` Specify the overall intent of a container.
- `services` Services are attached to Docker containers, with as many as needed being made. This is useful if you have a container that you wish to attach a lot of times, but dont want to have to create an entry in the schema for each one.
- `clones` How many times do you want to start a container? In this case we want two copies of our `siege` container. Note that each clone is appended with `-num` where num is the clone number. I.e. here we will have two containers called `siege-0` and `siege-1`.

Its also important to note that we can use Python variables within schemas, for example under `volumes` for `nginx` we have specified that the directory includes `{self.pwd}`. Any Python variable that is present in the `Forge/Container.py` `Container()` class can be used, so in this instance we are saying that our volume should be mounted within the scenario folder.

## The Capture

The other core component for this scenario is the `capture.py` file.

>scenario-stress/capture.py
```python
import os
import sys
from time import sleep, time

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


def scenario(
        controller: Controller,
        containers: dict[str, Container],
        networks: dict[str, Network],
        pwd: str,
        logger: Logger,
        sandbox: bool,
    ) -> None:

    # CAPTURE STARTUP

    startup_successful: bool = False
    
    try:

        controller.startNetworks() # Start Docker networks

        controller.start() # Start Docker containers

        startup_successful = True

    except Exception as e:
        logger.log(
            message=f"Failed to start scenario: {e}",
            type="error"
        )
        os.system(f"{ROOT_DIR}/tools/clean.sh")
        logger.outLog(f"{pwd}/data/log.txt")
        raise(e)

    if startup_successful:

        # MAIN SCENARIO

        input("Start scenario?")

        start_time: float = time()

        # Run siege commands on specified containers
        for clone in range(2):
            containers[f"siege-{clone}"].run(
                command="siege -c 50 -d 10 -t4S 192.168.0.5",
                root_intent="Attack",
                intent="Stress",
                target="nginx"
            )

        logger.trail("sleep 5")
        sleep(5)

        # CAPTURE TEARDOWN

        controller.complete(
            trail="/trail.sh",
            intents="/data/intents.txt",
            skip_teardown=False, # Bring the containers down?
            skip_networks=False, # Bring the networks down?
            skip_intents=False, # Write all container intents to a file?
            skip_trail=False, # Create a shell script of the scenario?
            skip_flows=False, # Convert PCAP to flows?
            skip_tests=True, # Run WhiffSuite tests on flows?
            skip_webpage=True # Create a webpage of the test results?
        )

    logger.log(
        message=f"Capture complete in {round((time()-start_time)/60, 2)} minutes",
        type="ok"
    )

    # Write logs to a file
    logger.outLog(f"{pwd}/data/log.log")

    return


def main() -> None:

    sandbox: bool = False

    logger = Logger(rolling_messages=True, interesting_only=True)
    controller: Controller = Controller(
        pwd=CAPTURE_DIR,
        logger=logger,
        sandbox=sandbox,
        requires_sudo=False
    )
    context: Context = controller.context
    containers: dict[str, Container] = context.getContainers()
    networks = context.getNetworks()

    scenario(
        controller=controller,
        containers=containers,
        networks=networks,
        pwd=CAPTURE_DIR,
        logger=logger,
        sandbox=sandbox
    )

    return


if __name__ == "__main__":
    main()
```

Almost all of this file is boilerplate, so we will skip past almost everything outside of the `scenario()` function which contains the core logic for the scenario. Everything else can be automatically generated for you using tools provided [Create a scenario](#create-scenarios). The only points I want to touch on outside of the `scenario()` function are sandboxing and logging.

### Explaining Some Boilerplate Code

You can enable sandboxing by setting the `sandbox: bool` variable to `True` inside the `main()` function. Sandboxing allows you to run through the scenario without using Docker. Whilst this means no data will be created it at least allows you to ensure your schema is correct, identify any issues reported using the logger, and create a runnable shell file of the scenario if you like. Like I say, this is particularly useful in early development of scenarios to check everything is correct before interacting with Docker and generating data.

Logging can be very useful, but can also end up overwhelming the terminal. Make sure to customise the logger how you like before running a scenario, you can also output all the logs collected to a file (the second last line in `scenario()`). The parameters of the Logger are as follows:

- `rolling_messages: bool = False` Should logs be printed to the standard output
- `interesting_only: bool = False` Should we only print logs if they are not of the type 'background' or 'normal'
- `filter: list[str] = []` List of log types we want to see printed (takes precedence over `interesting_only`)
- `background: bool = False` Should we print logs marked `background`

### The Meat

After we have successfully brought up all our containers, as indicated by the `if startup_successful` guard, we can begin performing actions on containers in order to generate our traffic. In this scenario all this amounts to is running siege commands using our siege containers on the nginx container. We can do this via the `run` command implemented in our `Forge/Container.py` class. Since we spun up two clones of this container, we need to append `-num` onto the end of the container where num starts at 0, so in this case we are running commands on `siege-0` and `siege-1`. When we run commands on containers we can specify a number of parameters in order to both control how commands are run, and some metadata for use in analysis later. In this case we specify `root_intent`, `intent`, and `target`. These three parameters are fairly self explanatory and are only used in flow labelling later. Below I have provided a very short extract of flows generated by this scenario.

>scenario-stress/data/flows/siege-0-updated.csv
```csv

Process Time,Src IP,Src Port,Dst IP,Dst Port,...,RootIntent,Intent,Target,From
2025-02-18 16:57:53.312541 +0000 UTC,192.168.0.2,51092,192.168.0.5,80,...,Attack,Stress,nginx,NA
2025-02-18 16:57:53.312542 +0000 UTC,192.168.0.2,51100,192.168.0.5,80,...,Attack,Stress,nginx,NA

```

After we have run our commands (which in this case are non-blocking at least to the extent that we don't wait for the siege commands to complete) we use `logger.trail("sleep 5")` in order to ensure our sleep is added to our constructed shell file, and then sleep for 5 seconds with Pythons command `sleep(5)`. Note, all commands run through the framework are automatically added to the shell file, but commands like `sleep(5)` that are not controlled by Forge will need to be explicitly added to the trail.

Finally we run `controller.complete()` along with the provided arguments to specify how we wish to teardown the scenario, and what extra tooling to employ after the fact. In this case we want to:

- Teardown the networks
- Teardown the containers
- Write container intent information to a file (useful for creating flows later from PCAP files and intent data)
- Write our trail (create a runnable shell file)
- Create flows from our captured network traffic
- Skip WhiffSuite testing
- Skip webpage generation (as we will have no test results to display anyway)

And thats us done! We should be able to see our network traffic PCAP files under `scenario-stress/data/pcap`, our flows under `scenario-stress/data/flows` and see our generated shell file under `scenario-stress/trail.sh`. I will also quickly display what our shell file has generated here:

```bash
#!/bin/bash

mkdir /Users/sammccormack/Documents/Uni/Year4/Diss/Forge/scenarios/scenario-stress/data/pcap
docker network create -d bridge --subnet 192.168.0.0/24 main
docker run --name nginx -v /Users/sammccormack/Documents/Uni/Year4/Diss/Forge/scenarios/scenario-stress/environment:/usr/share/nginx/html -p 8080:80 --ip 192.168.0.5 --network=main -itd forge/nginx
docker run --name nginx-tcpdump -v /Users/sammccormack/Documents/Uni/Year4/Diss/Forge/scenarios/scenario-stress/data/pcap:/data/pcap --network=container:nginx -itd forge/tcpdump
docker exec -d nginx-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/nginx-tcpdump.pcap'
docker run --name siege-0 --network=main -itd forge/siege
docker run --name siege-0-tcpdump -v /Users/sammccormack/Documents/Uni/Year4/Diss/Forge/scenarios/scenario-stress/data/pcap:/data/pcap --network=container:siege-0 -itd forge/tcpdump
docker exec -d siege-0-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/siege-0-tcpdump.pcap'
docker run --name siege-1 --network=main -itd forge/siege
docker run --name siege-1-tcpdump -v /Users/sammccormack/Documents/Uni/Year4/Diss/Forge/scenarios/scenario-stress/data/pcap:/data/pcap --network=container:siege-1 -itd forge/tcpdump
docker exec -d siege-1-tcpdump /usr/sbin/tcpdump 'not(ip6 or arp or (udp and (src port 5353 or src port 57621 or src port 1900)))' -v -w '/data/pcap/siege-1-tcpdump.pcap'
docker exec -d siege-0 siege -c 50 -d 10 -t4S 192.168.0.5
docker exec -d siege-1 siege -c 50 -d 10 -t4S 192.168.0.5
sleep 5
docker exec -d siege-0-tcpdump sh -c 'pkill tcpdump'
docker exec -d siege-1-tcpdump sh -c 'pkill tcpdump'
docker stop siege-1-tcpdump && docker rm siege-1-tcpdump
docker stop siege-0-tcpdump && docker rm siege-0-tcpdump
docker stop siege-1 && docker rm siege-1
docker stop siege-0 && docker rm siege-0
docker exec -d nginx-tcpdump sh -c 'pkill tcpdump'
docker stop nginx-tcpdump && docker rm nginx-tcpdump
docker stop nginx && docker rm nginx
docker network rm main
```

Please note, that whilst the shell files are good for quickly re-running the scenario, they cannot employ any of the additional tooling such as:
- PCAP to flow conversion
- Testing

### A final note

Whilst I did not explain testing this scenario, I have run testing on this scenario before (although its not very interesting) but the files are available under `scenario-stress/data/test-results`, the config file for the tests is at `scenario-stress/config.json`, and the webpage for these test results can be found at `scenario-stress/data/result.html`.

# A much more complicated scenario

I've included two other scenarios, one is slightly more complex and the other is much more complex:
- `scenarios/scenario-ssh-bruteforce` (Medium complexity) NMAP, Siege, Hydra ssh password bruteforce, sensitive documents exfil
- `scenarios/scenario-alert` (Complex) NMAP, WPScan, Dirb, Wordpress site RCE dumps wp-config.php and the users database table, along with background traffic generation. This is a simplified recreation of [This dataset](https://ieeexplore.ieee.org/document/9866880/). This scenario is much more complicated and as such may be a bit buggy at times, or not particularly well refined.