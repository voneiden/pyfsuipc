class FSUIPCError(Exception):
    pass

class OpenError(FSUIPCError):
    def __init__(self, value="Connection is already open"):
        self.value = value

class LinkError(FSUIPCError):
    def __init__(self, value="Cannot link to FSUIPC or WideClient"):
        self.value = value

class RegisterError(FSUIPCError):
    def __init__(self, value="Failed to Register common message with Windows"):
        self.value = value

class AtomError(FSUIPCError):
    def __init__(self, value="Failed to create Atom for mapping filename"):
        self.value = value

class MapError(FSUIPCError):
    def __init__(self, value="Failed to create a file mapping object"):
        self.value = value

class ViewError(FSUIPCError):
    def __init__(self, value="Failed to open a view to the file map"):
        self.value = value

class VersionError(FSUIPCError):
    def __init__(self, value="Incorrect version of FSUIPC, or not FSUIPC"):
        self.value = value

class SimVersionError(FSUIPCError):
    def __init__(self, value="Sim is not the version requested"):
        self.value = value

class ExecuteError(FSUIPCError):
    def __init__(self, value="Call cannot execute, link not open or no requests defined"):
        self.value = value

class TimeoutError(FSUIPCError):
    def __init__(self, value="IPC timed out all retries"):
        self.value = value

class RetryError(FSUIPCError):
    def __init__(self, value="IPC sendmessage failed all retries"):
        self.value = value

class DataError(FSUIPCError):
    def __init__(self, value="IPC request contains bad data"):
        self.value = value

class RunningError(FSUIPCError):
    def __init__(self, value="Maybe running on WideClient, but FS not running on Server, or wrong FSUIPC"):
        self.value = value

class MemoryError(FSUIPCError):
    def __init__(self, value="Read or Write request cannot be added, memory for Process is full"):
        self.value = value


mapping = {
    1: OpenError,
    2: LinkError,
    3: RegisterError,
    4: AtomError,
    5: MapError,
    6: ViewError,
    7: VersionError,
    8: SimVersionError,
    9: ExecuteError,
    10: ExecuteError,
    11: TimeoutError,
    12: RetryError,
    13: DataError,
    14: RunningError,
    15: MemoryError
}