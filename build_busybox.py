from subprocess import run
from abc import ABC
from sys import exit


class BoxBuilder(ABC):
    def __init__(self) -> None:
        super().__init__()
        self.__command = "make"
        self.__busybox_dir = "busybox"

    def build(self, procs: str) -> None:
        raise NotImplementedError

    def _goto_busybox_folder(self) -> None:
        run(f"cd {self.__busybox_dir}", shell=True, check=True)

    def _dump_log(self) -> str:
        raise NotImplementedError


class CrossBoxBuilder(BoxBuilder):
    def __init__(self, compiler: str) -> None:
        super().__init__()
        self._cross_compiler = compiler
        self._arch = ""


# CROSS_COMPILE=arm-linux-gnueabi-
class ARMBoxBuilder(CrossBoxBuilder):
    def __init__(self, compiler: str) -> None:
        super().__init__()
        self._arch = "arm"

    def build(self, procs: str) -> None:
        self._goto_busybox_folder()

        run(
            f"{self._BoxBuilder__command} -j{procs} ARCH={self._arch} CROSS_COMPILE={self._cross_compiler} {self._dump_log()}",
            shell=True,
            check=True,
        )
        run(
            f"{self._BoxBuilder__command} ARCH={self._arch} CROSS_COMPILE={self._cross_compiler} install {self._dump_log()}",
            shell=True,
            check=True,
        )

    def _dump_log(self) -> str:
        return "2>&1 | tee -a ${basedir}/log"


class X86_64BoxBuilder(BoxBuilder):
    def __init__(self) -> None:
        super().__init__()

    def build(self, procs: str) -> None:
        self._goto_busybox_folder()

        run(
            f"{self._BoxBuilder__command} -j{procs} {self._dump_log()}",
            shell=True,
            check=True,
        )
        run(
            f"{self._BoxBuilder__command} CONFIG_PREFIX=initrd install {self._dump_log()}",
            shell=True,
            check=True,
        )

    def _dump_log(self) -> str:
        return "2>&1 | tee -a ${basedir}/log"


if __name__ == "__main__":
    exit(0)
