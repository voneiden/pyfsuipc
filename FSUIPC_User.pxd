cdef extern from "FSUIPC_User.h":

    ctypedef unsigned long DWORD
    ctypedef int BOOL

    # Globals accessible from main code

    cdef int SIM_ANY = 0

    cdef extern DWORD FSUIPC_Version	# HIWORD is 1000 x Version Number, minimum 1998
                                            # LOWORD is build letter, with a = 1 etc. For 1998 this must be at least 5 (1998e)
    #extern DWORD FSUIPC_FS_Version;
                                            # FS98=1, FS2k=2, CFS2=3. See above.
    #extern DWORD FSUIPC_Lib_Version;
                                            # HIWORD is 1000 x version, LOWORD is build letter, a = 1 etc.

    # Library routines
    #extern BOOL FSUIPC_Open(DWORD dwFSReq, DWORD *pdwResult); // For use externally (IPCuser.lib)
    #extern BOOL FSUIPC_Open2(DWORD dwFSReq, DWORD *pdwResult, BYTE *pMem, DWORD dwSize); // For use internally (ModuleUser.lib)
    cdef extern BOOL FSUIPC_Open(DWORD dwFSReq, DWORD *pdwResult);
    cdef extern void FSUIPC_Close()
    cdef extern BOOL FSUIPC_Read(DWORD dwOffset, DWORD dwSize, void *pDest, DWORD *pdwResult);
    cdef extern BOOL FSUIPC_ReadSpecial(DWORD dwOffset, DWORD dwSize, void *pDest, DWORD *pdwResult);
    cdef extern BOOL FSUIPC_Write(DWORD dwOffset, DWORD dwSize, void *pSrce, DWORD *pdwResult);
    cdef extern BOOL FSUIPC_Process(DWORD *pdwResult);
    #extern BOOL FSUIPC_Read(DWORD dwOffset, DWORD dwSize, void *pDest, DWORD *pdwResult);
    #extern BOOL FSUIPC_ReadSpecial(DWORD dwOffset, DWORD dwSize, void *pDest, DWORD *pdwResult);
    #extern BOOL FSUIPC_Write(DWORD dwOffset, DWORD dwSize, void *pSrce, DWORD *pdwResult);
    #extern BOOL FSUIPC_Process(DWORD *pdwResult);

#cdef int dude = 3
