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

#from cpython cimport array as c_array
from cpython.mem cimport PyMem_Malloc, PyMem_Free

#from array import array

include "exceptions.pyx"
include "modes.pyx"

ctypedef unsigned long DWORD



cdef class Pyfsuipc:
    cdef void *result_pointers[10000]
    cdef list result_keys
    cdef list offsets_keys
    cdef dict offsets

    def __cinit__(self):
        """
        Initialize the class.
        Only *result_pointers array will remain NULL as they will be initialized on demand
        """

        self.result_keys = []
        self.offsets_keys = []
        self.offsets = {}

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

        cdef char *b_ptr
        cdef short *h_ptr
        cdef long *l_ptr
        cdef long long *q_ptr
        cdef float *f_ptr
        cdef double *d_ptr

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

            self.result_pointers[index] = ptr
        else:
            ptr = self.result_pointers[index]

        self.result_keys.append(offset_key)

        cdef DWORD error
        fsuipc.FSUIPC_Read(offset, size, ptr, &error)
        error = 0
        return error


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
        cdef DWORD error
        if not fsuipc.FSUIPC_Process(&error):
            self.handle_error(error)

        # Convert values
        cdef void *ptr
        cdef double *d_ptr
        cdef long *l_ptr
        cdef unsigned short *h_ptr

        print("Starting process")
        results = {}

        for i in range(len(self.result_keys)):
            key = self.result_keys[i]
            (offset, format, multiplier) = self.offsets[key]
            index = self.offsets_keys.index(key)

            ptr = self.result_pointers[index]
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

            print("Print")
            print(key, value)
            value *= multiplier
            results[key] = value

        # Clear the result keys list
        self.result_keys = []

        return results

    def read_all(self):
        for key in self.offsets.keys():
            self.read(key)

    def handle_error(self, error):
        if error != 0:
            if error in exception_mapping:
                raise exception_mapping[error]()
            else:
                raise FSUIPCError()
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

