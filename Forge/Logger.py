from time import time, sleep
import inspect
import os
from datetime import datetime
from threading import Lock


COLOURS: dict[str, str] = {
    "blue": "\033[94m",
    "green": "\033[92m",
    "red": "\033[91m",
    "yellow": "\033[93m",
    "end": "\033[0m",
}

LEVELS: dict[str, str] = {
    "background": "",
    "normal": "",
    "warning": COLOURS["yellow"],
    "error": COLOURS["red"],
    "info": COLOURS["blue"],
    "ok": COLOURS["green"]
}


class Log:

    def __init__(self, time: float, level: str, file: str, method: str, message: str, line_no: str = "", class_name: str = ""):
        self.time: float = time
        self.level: str = level
        self.file: str = file
        self.method: str = method
        self.message: str = message
        self.line_no: str = line_no
        self.class_name: str = class_name

    def __repr__(self):
        level = f"{LEVELS[self.level]}[{self.level}]{COLOURS['end']}"
        classn = f".{self.class_name}" if self.class_name else ""
        file_method = f"{self.file}{classn}.{self.method}()"
        log_time = datetime.fromtimestamp(self.time).strftime("%H:%M:%S")

        spacer_level = " "*(12-len(self.level))
        spacer_message = " "*(45-len(file_method)) + " "

        return f"{log_time}  {level}{spacer_level}{file_method}:{self.line_no}{spacer_message}{self.message}\n"


def logit(func):
    def wrapper(self, *args, **kwargs):
        file = os.path.basename(func.__code__.co_filename)
        class_name = self.__class__.__name__ if hasattr(self, "__class__") else ""
        self.logger.log(message="", type="background", file_name=file, method_name=func.__name__, line_no=":", class_name=class_name)
        return func(self, *args, **kwargs)
    return wrapper


class Logger:

    def __init__(
            self,
            rolling_messages: bool = False,
            interesting_only: bool = False,
            filter: list[str] = [],
            background: bool = False
        ) -> None:
        
        self.rolling_messages: bool = rolling_messages
        self.interesting_only: bool = interesting_only
        self.filter: set[str] = set([x.lower() for x in filter if x in LEVELS])
        self.background: bool = background
        self.lock = Lock()

        self.current_log = {}

        self.levels: dict = {
            "background": "",
            "normal": "",
            "warning": COLOURS["yellow"],
            "error": COLOURS["red"],
            "info": COLOURS["blue"],
            "ok": COLOURS["green"]
        }

        self.current_trail: list[str] = []

        return

    def log(self, message: str = "", type: str = "normal", file_name: str = "", method_name: str = "", line_no: str = "", class_name: str = "") -> None:

        # print("LOGGING")

        type = type.lower() if type.lower() in LEVELS else "normal"

        log_time = time()

        try:

            curframe = inspect.currentframe()
            calframe = inspect.getouterframes(curframe, 2)

            # print(calframe[2][3])

            method = calframe[1][3]
            file = os.path.basename(calframe[1][1])
            line_number = calframe[1][2]

            classn = ""
            caller_self = calframe[1][0].f_locals.get("self", None)  # Get 'self' from caller's frame
            if caller_self:
                classn = caller_self.__class__.__name__

            if f"{file}{method}" == "ErrorCodes.py__init__":
                method = calframe[2][3]
                file = os.path.basename(calframe[2][1])
            # print(f"{file}{method}")

        except:

            method = "UKNWN"
            file = "UNKWN"

        if method_name: method = method_name
        if file_name: file = file_name
        if line_no: line_number = line_no
        if class_name: classn = class_name

        new_log = Log(
            time=log_time,
            level=type,
            file=file,
            method=method,
            message=message,
            line_no=line_number,
            class_name=classn
        )

        self.current_log.update({
            log_time: new_log
        })

        with self.lock:

            if self.rolling_messages:
                if self.filter and type in self.filter:
                    print(new_log)
                elif self.interesting_only and type not in {"normal", "background"}:
                    print(new_log)
                elif self.background or type != "background":
                    print(new_log)
                else:
                    pass

            # sleep(0.2)

        return
    
    def addCallChain(self, chain_item) -> None:
        return
    
    def getLogString(self) -> str:
        out: str = ""
        for value in self.current_log.values():
            out += value.__repr__() + "\n"
        
        return out
    
    def outLog(self, file: str) -> None:

        if not os.path.exists(os.path.dirname(file)):
            self.log(
                message=f"Output directory does not exist for {file}",
                type="error"
            )
            return

        with open(file, "w") as out_file:
            text = self.getLogString()
            for value in COLOURS.values():
                text = text.replace(value, "")
            out_file.write(text)

        return
    
    def trail(self, command: str) -> None:
        self.current_trail.append(command)

    def getTrail(self) -> list[str]:
        return self.current_trail

    
def main() -> None:
    logger = Logger(rolling_messages=True, interesting_only=True)
    logger.log()
    logger.log(message="Test message", type="error")
    logger.log(message="Everything is good!", type="ok")

    # print(logger.getLogString())
    logger.outLog(file="test.txt")


if __name__ == "__main__":
    main()
