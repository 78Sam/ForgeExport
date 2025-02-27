

from Forge.Logger import Logger, logit
from Forge.ErrorCodes import ErrorCode, SchemaValidationError


class SchemaValidator:

    def __init__(self, logger: Logger, schema: dict) -> None:
        
        self.logger: Logger = logger
        self.schema: dict = schema

        self.container_params: set[str] = set([
            "intent",
            "image",
            "volumes",
            "services",
            "depends_on",
            "networking",
            "command",
            "down_command",
            "params",
            "clones",
            "enabled"
        ])

        self.container_network_params: set[str] = set([
            "network",
            "ip",
            "ports",
            "mode"
        ])

        self.service_params: set[str] = set([
            "image",
            "volumes",
            "networking",
            "command",
            "down_command",
            "params"
        ])

        self.service_network_params: set[str] = set([
            "network",
            "ip",
            "ports",
            "mode"
        ])

        self.network_params: set[str] = set([
            "driver",
            "subnet",
            "gateway",
            "base_conditions"
        ])

        return
    
    def checkParams(self, to_check: dict, against: set[str], type: str, name: str) -> list[str]:
        to_remove: list[str] = []
        for param in to_check.keys():
            if param not in against:
                self.logger.log(
                    message=f"Removing unknown schema parameter '{param}' from {type} '{name}'",
                    type="warning"
                )
                to_remove.append(param)
        
        return to_remove

    @logit
    def validateContainers(self) -> None:

        if "containers" not in self.schema:
            self.logger.log(message=f"No containers found in schema", type="error")
            raise SchemaValidationError(self.logger, ErrorCode.ERR_NO_CONTAINERS_LISTED)

        if len(self.schema["containers"]) == 0:
            self.logger.log(message=f"No containers found in schema", type="error")
            raise SchemaValidationError(self.logger, ErrorCode.ERR_NO_CONTAINERS_LISTED)
        
        for container_name in self.schema["containers"]:
            container: dict = self.schema["containers"][container_name]

            for to_remove in self.checkParams(
                container,
                self.container_params,
                "container",
                container_name
            ): container.pop(to_remove)

            if "image" not in container or container["image"] == "":
                raise SchemaValidationError(
                    self.logger,
                    ErrorCode.ERR_CONTAINER_NO_IMAGE,
                    detail=container_name
                )
            
            if container_network := container.get("networking", {}):
                for to_remove in self.checkParams(
                    container_network,
                    self.container_network_params,
                    "container network",
                    container_name
                ): container_network.pop(to_remove)

            if network := container.get("networking", {}).get("network"):

                if "networks" not in self.schema:
                    raise SchemaValidationError(
                        self.logger,
                        ErrorCode.ERR_UNDEFINED_NETWORK,
                        detail=f"{container_name} : {network}"
                    )
                
                if network not in self.schema["networks"]:
                    raise SchemaValidationError(
                        self.logger,
                        ErrorCode.ERR_UNDEFINED_NETWORK,
                        detail=f"{container_name} : {network}"
                    )
                
            if services := container.get("services"):

                if type(services) != list:
                    raise SchemaValidationError(
                        self.logger,
                        ErrorCode.ERR_SERVICES_NOT_LIST,
                        detail=f"{container_name} : {services}"
                    )
                
                for service in services:

                    if service not in self.schema.get("services", {}):

                        raise SchemaValidationError(
                            self.logger,
                            ErrorCode.ERR_UNDEFINED_SERVICE,
                            detail=f"{container_name} : {service}"
                        )
                    
            if dependents := container.get("depends_on"):

                if type(dependents) != list:
                    raise SchemaValidationError(
                        self.logger,
                        ErrorCode.ERR_DEPENDS_ON_NOT_LIST,
                        detail=f"{container_name} : {dependents}"
                    )
                
                for depends_on in dependents:

                    if depends_on not in self.schema.get("containers", {}):

                        raise SchemaValidationError(
                            self.logger,
                            ErrorCode.ERR_UNDEFINED_DEPENDENT,
                            detail=f"{container_name} : {depends_on}"
                        )
                    
                    if depends_on == container_name:

                        raise SchemaValidationError(
                            self.logger,
                            ErrorCode.ERR_LOOPING_DEPENDENT,
                            detail=f"{container_name} : {depends_on}"
                        )
                    
        # TODO: Add checks for clones

        return
    
    @logit
    def validateNetworks(self) -> None:
        
        if "networks" not in self.schema:
            self.logger.log(
                message="No networks in schema",
                type="warning"
            )
        
        if len(self.schema["networks"]) == 0:
            self.logger.log(
                message="No networks in schema",
                type="warning"
            )

        for network_name in self.schema["networks"]:

            network = self.schema["networks"][network_name]

            for to_remove in self.checkParams(
                network,
                self.network_params,
                "network",
                network_name
            ): network.pop(to_remove)

            if "driver" not in network:
                raise SchemaValidationError(
                    self.logger, ErrorCode.ERR_NO_NETWORK_DRIVER,
                    detail=network_name
                )
        
        return
    
    @logit
    def validateServices(self) -> None:
        
        if "services" in self.schema:

            for service_name in self.schema["services"]:

                service = self.schema["services"][service_name]

                for to_remove in self.checkParams(
                    service,
                    self.service_params,
                    "service",
                    service_name
                ): service.pop(to_remove)

                if "image" not in service or service["image"] == "":
                    raise SchemaValidationError(
                        self.logger, ErrorCode.ERR_SERVICE_NO_IMAGE,
                        detail=service_name
                    )
                
                if service_network := service.get("networking"):
                    for to_remove in self.checkParams(
                        service_network,
                        self.service_network_params,
                        "service network",
                        service_name
                    ): service_network.pop(to_remove)
                
        return
    
    @logit
    def validateSchema(self):
        self.validateContainers()
        self.validateNetworks()
        self.validateServices()
        return
    

def main() -> None:
    return


if __name__ == "__main__":
    main()
