"""
   pyfsuipc - Python 3 compatible library written in Cython to interface with FSUIPC
   Copyright (C) 2015 Matti Eiden

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software Foundation,
   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

   (or you know, fetch it online from http://www.gnu.org/copyleft/gpl.html )
"""

cimport FSUIPC_User as fsuipc
import struct

from cpython.mem cimport PyMem_Malloc, PyMem_Free

include "exceptions.pyx"
include "modes.pyx"

ctypedef unsigned long DWORD


cdef class Pyfsuipc:
    cdef void *read_pointers[10000]
    cdef void *write_pointers[10000]
    cdef list read_keys
    cdef list offset_keys
    cdef dict offsets

    def __cinit__(self):
        """
        Only *read_pointers array will remain NULL as they will be initialized on demand.

        offset_keys is used to determine which read_pointers/write_pointers pointer corresponds to which offset.
        It's also cdeffed to ensure that it's not accessible from Python side of things, as modifying it without
        proper care would likely lead into mismatched pointers and a crash.
        """

        self.read_keys = []
        self.offset_keys = []
        self.offsets = {}


    def read(self, offset_key):
        """
        Make a read request to FSUIPC using FSUIPC_User Read call.

        Parameters
        ----------
        offset_key : string
            determines the offset to be read, see self.load_offsets

        result : int,
        """

        try:
            (offset, format, multiplier) = self.offsets[offset_key]
            index = self.offset_keys.index(offset_key)
            size = struct.calcsize(format)
        except KeyError:
            print("Error: offset key not found")
            return

        if size > 8:
            print("Error: size too large")
            return

        cdef void *ptr

        if self.read_pointers[index] == NULL:
            ptr = self.allocate_format(format)
            self.read_pointers[index] = ptr
        else:
            ptr = self.read_pointers[index]

        self.read_keys.append(offset_key)

        cdef DWORD error
        if not fsuipc.FSUIPC_Read(offset, size, ptr, &error):
            self.handle_error(error)



    def write(self, offset_key, value):
        """
        Add a write request in the queue

        Parameters
        ----------
        offset_key  : string
        value   : int or float, based on offset format
        """

        (offset, format, multiplier) = self.offsets[offset_key]
        index = self.offset_keys.index(offset_key)
        size = struct.calcsize(format)

        # Verify the value type
        if format != 'f' and format != 'd':
            if not isinstance(value, int):
                value = int(value)
        else:
            assert isinstance(value, float)

        cdef void *ptr
        if self.read_pointers[index] == NULL:
            ptr = self.allocate_format(format)
            self.write_pointers[index] = ptr
        else:
            ptr = self.read_pointers[index]

        self.set_pointer_value(ptr, format, value)
        cdef DWORD error
        if not fsuipc.FSUIPC_Write(offset, size, ptr, &error):
            self.handle_error(error)


    def start(self, unsigned long mode=SIM_ANY):
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
            raise ExecuteError()


    def process(self):
        """
        Process the queued read and write requests.

        Returns
        -------
        results : dict
            read results in {offset_key: value} format.
        """
        cdef DWORD error
        if not fsuipc.FSUIPC_Process(&error):
            self.handle_error(error)

        # Convert values
        cdef void *ptr
        cdef double *d_ptr
        cdef long *l_ptr
        cdef unsigned short *h_ptr

        results = {}

        for i in range(len(self.read_keys)):
            key = self.read_keys[i]
            (offset, format, multiplier) = self.offsets[key]
            index = self.offset_keys.index(key)

            value = self.get_pointer_value(self.read_pointers[index], format)

            value *= multiplier
            results[key] = value

        # Clear the result keys list
        self.read_keys = []

        return results


    def read_all(self):
        """
        Read all loaded offset values
        """
        for key in self.offsets.keys():
            self.read(key)


    def handle_error(self, error):
        """
        Handle an error number returned by the FSUIPC_User library
        """
        if error != 0:
            if error in exception_mapping:
                raise exception_mapping[error]()
            else:
                raise FSUIPCError()
        else:
            return True

    def add_offset(self, key, offset, format, multiplier=1):
        """
        Configure a new offset
        """
        self.offsets[key] = (offset, format, multiplier)
        self.offset_keys.append(key)

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
                self.offset_keys.append(name)


    cdef void* allocate_format(self, format):
        """
        Allocates memory based on the defined offset format.
        """
        cdef void* ptr
        cdef char *b_ptr
        cdef short *h_ptr
        cdef long *l_ptr
        cdef long long *q_ptr
        cdef float *f_ptr
        cdef double *d_ptr

        if format == 'b' or format == 'B':
            b_ptr = <char *> PyMem_Malloc(sizeof(char))
            b_ptr[0] = 0
            ptr = <void *> b_ptr

        elif format == 'h' or format == 'H':
            h_ptr = <short*> PyMem_Malloc(sizeof(short))
            h_ptr[0] = 0
            ptr = <void*> h_ptr

        elif format == 'i' or format == 'I' or format == 'l' or format == 'l':
            l_ptr = <long*> PyMem_Malloc(sizeof(long))
            l_ptr[0] = 0
            ptr = <void*> l_ptr

        elif format == 'q' or format == 'Q':
            q_ptr = <long long*> PyMem_Malloc(sizeof(long long))
            q_ptr[0] = 0
            ptr = <void*> q_ptr

        elif format == 'f':
            f_ptr = <float*> PyMem_Malloc(sizeof(float))
            f_ptr[0] = 0
            ptr = <void *> f_ptr

        elif format == 'd':
            d_ptr = <double*> PyMem_Malloc(sizeof(double))
            d_ptr[0] = 0
            ptr = <void *> d_ptr

        else:
            raise NotImplementedError

        if not ptr:
                raise MemoryError

        return ptr


    cdef get_pointer_value(self, void *ptr, format):
        """
        Dereference a ptr depending on respective format
        """
        if ptr == NULL:
            raise RuntimeError

        if format == 'b':
            value = (<char*> ptr)[0]

        elif format == 'B':
            value = (<unsigned char*> ptr)[0]

        elif format == 'h':
            value = (<short*> ptr)[0]

        elif format == 'H':
            value = (<unsigned short*> ptr)[0]

        elif format == 'i':
            value = (<int*> ptr)[0]

        elif format == 'I':
            value = (<unsigned int*> ptr)[0]

        elif format == 'l':
            value = (<long*> ptr)[0]

        elif format == 'L':
            value = (<unsigned long*> ptr)[0]

        elif format == 'q':
            value = (<long long*> ptr)[0]

        elif format == 'Q':
            value = (<unsigned long long*> ptr)[0]

        elif format == 'f':
            value = (<float*> ptr)[0]

        elif format == 'd':
            value = (<double*> ptr)[0]

        else: # This must fail because it shouldn't happen here
            raise NotImplementedError

        return value


    cdef set_pointer_value(self, void *ptr, format, value):
        """
        Set the value of a pointer based on the format
        """
        if ptr == NULL:
            raise RuntimeError

        if format == 'b':
            (<char*> ptr)[0] = value

        elif format == 'B':
            (<unsigned char*> ptr)[0] = value

        elif format == 'h':
            (<short*> ptr)[0] = value

        elif format == 'H':
            (<unsigned short*> ptr)[0] = value

        elif format == 'i':
            (<int*> ptr)[0] = value

        elif format == 'I':
            (<unsigned int*> ptr)[0] = value

        elif format == 'l':
            (<long*> ptr)[0] = value

        elif format == 'L':
            (<unsigned long*> ptr)[0] = value

        elif format == 'q':
            (<long long*> ptr)[0] = value

        elif format == 'Q':
            (<unsigned long long*> ptr)[0] = value

        elif format == 'f':
            (<float*> ptr)[0] = value

        elif format == 'd':
            (<double*> ptr)[0] = value

        else: # This must fail because it shouldn't happen here
            raise NotImplementedError