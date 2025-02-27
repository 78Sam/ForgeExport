from enum import Enum
from Forge.Logger import Logger


class ErrorCode(Enum):

    OK = "Ok"

    # Validation

    ERR_NO_SCHEMA_FILE = "Failed to find schema file"
    ERR_NO_CONTAINERS_LISTED = "No containers found in schema file"
    ERR_CONTAINER_NO_IMAGE = "No image provided for container"
    ERR_NO_NETWORK_DRIVER = "No driver provided for network"
    ERR_SERVICE_NO_IMAGE = "No image provided for service"
    ERR_UNDEFINED_NETWORK = "Network does not exist in schema file"
    ERR_SERVICES_NOT_LIST = "'services' should be a list of strings"
    ERR_UNDEFINED_SERVICE = "Service does not exist in schema file"
    ERR_DEPENDS_ON_NOT_LIST = "'depends_on' should be a list of strings"
    ERR_UNDEFINED_DEPENDENT = "Dependent does not exist in schema file"
    ERR_LOOPING_DEPENDENT = "Referenced dependent is self"

    # Container

    ERR_CONTAINER_COMMAND_ERROR = "The container has failed to run a command"

    # Network

    ERR_NETWORK_COMMAND_ERROR = "The network has failed to run a command"


class SchemaValidationError(Exception):
    def __init__(self, logger: Logger, error_code: ErrorCode, detail: str = ""):
        self.error_code = error_code
        message: str = f"{error_code.value}"
        logger.log(message=message, type="error")
        super().__init__(f"{error_code.name} {message}\n> {detail}")


class ContainerCommandError(Exception):
    def __init__(self, logger: Logger, error_code: ErrorCode, detail: str = ""):
        self.error_code = error_code
        message: str = f"{error_code.value}"
        logger.log(message=message, type="error")
        super().__init__(f"{error_code.name} {message}\n> {detail}")


class NetworkCommandError(Exception):
    def __init__(self, logger: Logger, error_code: ErrorCode, detail: str = ""):
        self.error_code = error_code
        message: str = f"{error_code.value}"
        logger.log(message=message, type="error")
        super().__init__(f"{error_code.name} {message}\n> {detail}")
       

def main() -> None:
    return


if __name__ == "__main__":
    main()
