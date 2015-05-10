cimport FSUIPC_User as fsuipc
from pathlib import _Accessor
import exceptions
import modes
import struct

from cpython cimport array as c_array
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from array import array

ctypedef unsigned long DWORD



cdef class Pyfsuipc:
    #cdef c_array.array
    cdef void *result_pointers[10000]
    cdef int result_counter
    cdef list result_keys
    cdef list offsets_keys
    cdef dict offsets




    def __cinit__(self):
        self.result_counter = 0
        self.result_keys = []
        self.offsets_keys = []
        self.offsets = {}

        if self.result_pointers[2] == NULL:
            print("Its null")
        else:
            print("ITS NOT NULL")


    def read(self, offset_key, size=None):
        """
        Make a read request to FSUIPC using FSUIPC_User Read call.

        Parameters
        ----------
        offset : int
            determines the offset to be read

        size : short
            determines the size of the value to be read, must be 8 or less

        result : double, pointer
        """

        cdef double *d_ptr
        cdef long *l_ptr
        cdef unsigned short *h_ptr

        if isinstance(offset_key, int) and size is not None:
            raise NotImplementedError
        else:
            try:
                (offset, format, multiplier) = self.offsets[offset_key]
                index = self.offsets_keys.index(offset_key)
                size = struct.calcsize(format)
            except KeyError:
                print("Error: offset key not found")
                return

        if size > 8:
            print("Error: size too large")
            return

        cdef void *ptr

        if self.result_pointers[index] == NULL:
            print("Allocating new variable")


            # Allocate result
            if format == 'd':
                d_ptr = <double*> PyMem_Malloc(sizeof(double))
                d_ptr[0] = 0
                ptr = <void *> d_ptr
            elif format == 'l':
                l_ptr = <long*> PyMem_Malloc(sizeof(long))
                l_ptr[0] = 0
                ptr = <void *> l_ptr
                print("Long allocated")

                l_ptr = <long *> ptr
                print(l_ptr[0])

            elif format == 'H':
                h_ptr = <unsigned short*> PyMem_Malloc(sizeof(short))
                h_ptr[0] = 0
                ptr = <void*> h_ptr

            else:
                raise NotImplementedError

            if not ptr:
                raise MemoryError

            self.result_pointers[index] = ptr
        else:
            ptr = self.result_pointers[index]


        #cdef void *ptr

        #ptr = <void*> result
        # Append
        #self.result_values.append(<object> ptr)
        #self.result_pointers[self.result_counter] = ptr
        #self.result_counter += 1
        self.result_keys.append(offset_key)

        cdef DWORD error
        print("Read", offset, size)
        fsuipc.FSUIPC_Read(offset, size, ptr, &error)
        error = 0
        return error


    def start(self, unsigned long mode=modes.SIM_ANY):
        """
        Wrapper for FSUIPC_User Open call. Opens a new connection to FSUIPC.

        Parameters
        ----------
        mode : int, optional
            Defines the required FS version to connect to (pyfsuipc.modes). Defaults to any.

        Returns
        -------
        success
            True or raises an exception on error
        """
        cdef DWORD error
        if not fsuipc.FSUIPC_Open(mode, &error):
            self.handle_error(error)

        _ready = True
        return True

    def stop(self):
        """
        Wrapper for FSUIPC_User Close call. Closes the connection to FSUIPC.
        """
        fsuipc.FSUIPC_Close()
        _ready = False

    def version(self):
        """
        Determine the version of FSUIPC (if connected)
        """
        _ready = True
        if _ready:
            return "{}.{}{}{}".format(0x0f & (fsuipc.FSUIPC_Version >> 28),
                                      0x0f & (fsuipc.FSUIPC_Version >> 24),
                                      0x0f & (fsuipc.FSUIPC_Version >> 20),
                                      0x0f & (fsuipc.FSUIPC_Version >> 16))

        else:
            raise exceptions.ExecuteError()

    def process(self):
        cdef DWORD error
        if not fsuipc.FSUIPC_Process(&error):
            #self.handle_error(error)
            pass

        """
        print("OK")
        cdef void *ptr
        ptr = <void *> self.result_values[0]
        cdef int *pInt
        pInt = <int*>ptr
        print(pInt[0])
        """

        #cdef double value
        #value = <double> ptr
        #print(value)
        #print(ptr)
        #value = *ptr
        #print(value)
        #print(&self.result_values[0])

        # Convert values
        cdef void *ptr
        cdef double *d_ptr
        cdef long *l_ptr
        cdef unsigned short *h_ptr

        print("Starting process")
        results = {}

        for i in range(len(self.result_keys)):
            print("Start")
            key = self.result_keys[i]
            print("Reading key", key)
            (offset, format, multiplier) = self.offsets[key]
            index = self.offsets_keys.index(key)

            print("Offsets read",offset,format,multiplier)
            ptr = self.result_pointers[index]
            if ptr == NULL:
                raise RuntimeError

            print("Pointer set")

            if format == 'd':
                d_ptr = <double*> ptr
                value = d_ptr[0]
                #PyMem_Free(d_ptr)

            elif format == 'l':
                l_ptr = <long*> ptr
                value = l_ptr[0]
                #PyMem_Free(l_ptr)


            elif format == 'H':
                h_ptr = <unsigned short*> ptr
                value = h_ptr[0]
                #PyMem_Free(h_ptr)

            else: # This must fail because it causes a memory leak otherwise
                raise NotImplementedError
            print("Print")
            print(key, value)
            value *= multiplier
            results[key] = value

        #self.result_counter = 0
        self.result_keys = []

        return results

    def read_all(self):
        for key in self.offsets.keys():
            self.read(key)


    """
    def process(self):
        global result_values, result_keys

        cdef DWORD error
        print("Start process")
        fsuipc.FSUIPC_Process(&error)
        print("End process")
        self.check_error(error)

        results = {}
        print("Enter for loop",len(result_values))
        for i in range(len(result_values)):
            print("Go")
            print(str(result_keys))
            print("Get key", len(result_keys), i)
            key = result_keys[i]
            print("Get offset")
            (offset, format, multiplier) = offsets[key]

            # Convert to bytes (array returns double values)
            print(result_values[i])
            value = struct.pack('d', result_values[i])

            # Truncate
            value = value[:struct.calcsize(format)]

            # Convert to correct format
            value = struct.unpack(format, value)[0] * multiplier

            results[key] = value

        # Clear the result arrays
        print("c1")
        result_values = array('d')
        print("c2")
        result_keys = []
        #for i in range(len(result_keys)):
        #    result_keys.pop()
        print("return")
        return results
        """

    def handle_error(self, error):
        if error != 0:
            if error in exceptions.mapping:
                raise exceptions.mapping[error]()
            else:
                raise exceptions.FSUIPCError()
        else:
            return True

    def load_offsets(self, file_name):
        """
        Load an offset file
        """

        f = open(file_name, 'r')
        for line in f.readlines():
            line = line.strip()
            if len(line) == 0 or line[0] == "#":
                continue

            tokens = line.split()
            if len(tokens) < 3:
                continue

            name = tokens[0]
            try:
                offset = int(tokens[1], 16)
            except ValueError:
                continue
            format = tokens[2]
            try:
                multiplier = float(tokens[3]) if len(tokens) > 3 else 1
            except ValueError:
                multiplier = 1
            size = struct.calcsize(format)

            if name not in self.offsets:
                self.offsets[name] = (offset, format, multiplier)
                self.offsets_keys.append(name)
    """
    def get(self, key):
        global result_values, result_keys
        if key not in offsets:
            raise KeyError

        (offset, format, multiplier) = offsets[key]

        result_values.append(0)
        result_keys.append(key)

        result = self.read(offset, struct.calcsize(format), &result_values.data.as_doubles[(len(result_values) - 1)])
    """
    """
    def get_all(self):
        for key in offsets.keys():
            self.get(key)
    """
