'ComPort.cmp  ' inc2026: file renamed from COMPORTxp.CMP to COMPORTxp.inc (header keeps the original name ComPort.cmp)
'Version 0.9
'December 13, 2001
'by Pete Kleinschmidt
'loosely based on VB code by David M. Hitchner
'http://www.thescarms.com/vbasic/CommIO.asp

'Win32 Communications User Defined Types

'Structure containing time-out parameters for a communications device
TYPE COMMTIMEOUTS
        ReadIntervalTimeout AS DWORD
        ReadTotalTimeoutMultiplier AS DWORD
        ReadTotalTimeoutConstant AS DWORD
        WriteTotalTimeoutMultiplier AS DWORD
        WriteTotalTimeoutConstant AS DWORD
END TYPE

'Device Control Block
'Structure that defines the control settings for a serial communications device
TYPE DCB
        DCBlength AS DWORD        'sizeof DCB
        BaudRate AS DWORD         'current baud rate
        DCBflags AS DWORD         'fBinary            1 bit binary mode, no EOF check
                                  'fParity            1 bit enable parity checking
                                  'fOutxCtsFlow       1 bit CTS output flow control (hardware flow control setting)
                                  'fOutxDsrFlow       1 bit DSR output flow control (hardware flow control setting)
                                  'fDtrControl        2 bit DTR flow control type (hardware flow control setting)
                                  'fDsrSensitivity    1 bit DSR sensitivity (hardware flow control setting)
                                  'fTXContinueOnXoff  1 bit XOFF continues Tx (software flow control setting)
                                  'fOutX              1 bit XON/XOFF out flow control (software flow control setting)
                                  'fInX               1 bit XON/XOFF in flow control (software flow control setting)
                                  'fErrorChar         1 bit enable error replacement
                                  'fNull              1 bit enable null stripping
                                  'fRtsControl        2 bit RTS flow control (hardware flow control setting)
                                  'fAbortOnError      1 bit abort on error (hardware flow control setting)
                                  'fDummy2           17 bit reserved
        wReserved AS WORD         'reserved
        XonLim AS WORD            'transmit XON threshold (software flow control setting)
        XoffLim AS WORD           'transmit XOFF threshold (software flow control setting)
        ByteSize AS BYTE          'number of bits/byte, 4-8
        Parity AS BYTE            '0-4=no,odd,even,mark,space
        StopBits AS BYTE          '0,1,2=1,1.5,2
        XonChar AS BYTE           'Tx and Rx XON character (software flow control setting)
        XoffChar AS BYTE          'Tx and Rx XOFF character (software flow control setting)
        ErrorChar AS BYTE         'error replacement character
        EofChar AS BYTE           'end of input character
        EvtChar AS BYTE           'received event character
        wReserved1 AS WORD        'reserved; do not use
END TYPE

'Structure containing current Comm Port State
Type COMSTAT
        COMSTATflags AS DWORD     'fCtsHold           1 bit Specifies whether waiting for CTS signal
                                  'fDsrHold           1 bit Specifies whether waiting for DSR signal
                                  'fRlsHold           1 bit Specifies whether waiting for RLSD signal
                                  'fXoffHold          1 bit Specifies whether waiting because XOFF character was received
                                  'fXoffSent          1 bit Specifies whether waiting because XOFF character was transmitted
                                  'fEof               1 bit Specifies whether EOF char has been received
                                  'fTxim              1 bit character queued for transmission because of TransmitCommChar
                                  'fReserved         25 bit Reserved
        cbInQue As DWORD          'number of bytes received but not yet read
        cbOutQue As DWORD         'number of bytes remaining to be transmitted
END TYPE

'Win32 File Handling User Defined Types

'Structure that contains the security descriptor for an object
'not currently used by us
TYPE SECURITYATTRIBUTES
        nLength AS DWORD 
        lpSecurityDescriptor AS LONG
        bInheritHandle AS LONG
END TYPE

'Structure containing info used in Overlapped (asynchronous) I/O
'not currently used by us
TYPE OVERLAPPED
        Internal AS LONG
        InternalHigh AS LONG
        offset AS DWORD
        OffsetHigh As DWORD
        hEvent AS LONG
END TYPE

'DCB Constants
'Parity
CONST NOPARITY              = 0
CONST ODDPARITY             = 1
CONST EVENPARITY            = 2
CONST MARKPARITY            = 3
CONST SPACEPARITY           = 4
'StopBits
CONST ONESTOPBIT            = 0
CONST ONE5STOPBITS          = 1
CONST TWOSTOPBITS           = 2

'PurgeCOM constants
'dwFlags
CONST PURGE_RXABORT         = &H2
CONST PURGE_RXCLEAR         = &H8
CONST PURGE_TXABORT         = &H1
CONST PURGE_TXCLEAR         = &H4

'Win32 File Handling Constants

'dwDesired Access Constants
Const GENERIC_READ_cmp          = &H80000000
CONST GENERIC_WRITE_cmp         = &H40000000
'dwShareMode Constants
'CONST FILE_SHARE_READ       = &H1
'CONST FILE_SHARE_WRITE      = &H2
'dwCreationDisposition Constants
'CONST CREATE_NEW            = 1
'CONST CREATE_ALWAYS         = 2
'CONST OPEN_EXISTING         = 3
CONST OPEN_ALWAYS           = 4
CONST TRUNCATE_EXISTING     = 5
'dwFlagsAndAttributes
'CONST FILE_ATTRIBUTE_NORMAL = &H80

'Win32 Error Constants
CONST FORMAT_MESSAGE_ALLOCATE_BUFFER  = &H100
CONST FORMAT_MESSAGE_FROM_SYSTEM      = &H1000
CONST LANG_NEUTRAL                    = &H0
CONST SUBLANG_DEFAULT                 = &H1
CONST ERROR_BAD_USERNAME              = 2202&

'Error Message Constants
CONST ERROR_OPEN_PORT                 = "There was an error opening the Comm Port.  "
CONST ERROR_PORT_BUFFERS              = "There was an error creating the Comm Port Buffers.  "
CONST ERROR_PURGE_BUFFERS             = "There was an error purging old data from the Comm Port Buffers.  "
CONST ERROR_TIMEOUTS                  = "There was an error setting the Comm Port timeouts.  "
CONST ERROR_RETRIEVE_PORTSETTINGS     = "There was an error retrieving the existing Comm Port settings.  "
CONST ERROR_CHANGING_PORTSETTINGS     = "There was an error changing the Comm Port settings.  "
CONST ERROR_CLOSING_PORT              = "There was an error closing the Comm Port.  "
CONST ERROR_WRITING_PORT              = "There was an error writing data to the Comm Port.  "
CONST ERROR_SENDING_DATA              = "Could not send all the data in time specified.  Try increasing your wait time."
CONST ERROR_GETTING_PORT_STATUS       = "There was an error getting the Comm Ports current status.  " 
CONST ERROR_READING_PORT              = "There was an error reading data from the Comm Port.  "

'Win32 Function Declarations

'Suspends the execution of the current thread for the specified interval. 
DECLARE SUB Sleep Lib "kernel32" ALIAS "Sleep" _
    (dwMilliseconds AS DWORD)

'Win32 Error Messages

'Several Win32 functions set an error code if they fail.  This retrieves them.
'Note, If a function succeeds, it may not set this code.  If you retrieve it
'after a function succeeds, it may return an error code for a previous function that failed.
DECLARE FUNCTION GetLastError Lib "kernel32" ALIAS "GetLastError" _
    () _
        AS DWORD                                    'Returns last error code value
                                                    'See http://msdn.microsoft.com/library/default.asp?url=/library/en-us/debug/errlist_7oz7.asp
                                                    'for what codes mean

'Converts GetLastError codes to string messages.
Declare Function FormatMessage Lib "kernel32" Alias "FormatMessageA" _
    (dwFlags AS DWORD, _                            '[IN] Specifies aspects of the formatting process and how to interpret lpSource
    BYREF lpSource As LONG, _                       '[IN] Specifies the location of the message definition
    dwMessageId AS DWORD, _                         '[IN] Specifies the message identifier for the requested message
    dwLanguageId AS DWORD, _                        '[IN] Specifies the language identifier for the requested message
    BYREF lpBuffer As STRING, _                     '[OUT] Pointer to a buffer for the formatted message
    nSize AS DWORD, _                               '[IN] specifies the max number of characters that can be stored in the output buffer
    BYREF Arguments As Long) _                      '[IN] Pointer to an array of values that are used as insert values in the formatted message
      AS LONG                                       ''If function succeeds, returns non-zero. If function fails, returns 0. 

'Win32 Communication Functions

' Initializes the communications parameters for a specified
' communications device.
DECLARE FUNCTION SetupComm Lib "kernel32" ALIAS "SetupComm"_
    (hFile AS LONG,_                                '[IN] Handle to open Comm device
     dwInQueue AS DWORD,_                           '[IN] specifies number of bytes of input buffer
     dwOutQueue AS DWORD) _                         '[IN] specifies number of bytes of output buffer
        AS LONG                                     'If function succeeds, returns non-zero. If function fails, returns 0. 

' Discards all characters from the output or input buffer of a
' specified communications resource. It can also terminate
' pending read or write operations on the resource.
DECLARE FUNCTION PurgeComm Lib "kernel32" ALIAS "PurgeComm"_
    (hFile AS LONG, _                               '[IN] Handle to open Comm device
     dwFlags AS DWORD) _                            '[IN] Action to perform flag
        AS LONG                                     'If function succeeds, returns non-zero. If function fails, returns 0. 

' Sets the time-out parameters for all read and write operations on a
' specified communications device.
DECLARE FUNCTION SetCommTimeouts Lib "kernel32" ALIAS "SetCommTimeouts"_
    (hFile AS LONG,_                                '[IN] Handle to open Comm device
     lpCommTimeouts AS COMMTIMEOUTS) _              '[IN] Structure containing timeout values
        AS LONG                                     'If function succeeds, returns non-zero. If function fails, returns 0. 

'Retrieves current Device Control Block (DCB)
DECLARE FUNCTION GetCommState Lib "kernel32" ALIAS "GetCommState" _
    (hFile AS LONG, _                               '[IN] Handle to open Comm device
    lpDCB AS DCB) _                                 '[OUT] Pointer to structure containing config info
        AS LONG                                     'If function succeeds, returns non-zero. If function fails, returns 0. 

'Sets Device Control Block (DCB)
DECLARE FUNCTION SetCommState Lib "kernel32" ALIAS "SetCommState" _
    (hFile AS LONG, _                               '[IN] Handle to open Comm device
    lpDCB AS DCB) _                                 '[IN] Pointer to structure containing config info
        AS LONG                                     'If function succeeds, returns non-zero. If function fails, returns 0. 

' Retrieves information about a communications error and reports
' the current status of a communications device. Clears the
' device's error flag to enable additional input and output
' (I/O) operations.
DECLARE FUNCTION ClearCommError Lib "kernel32" ALIAS "ClearCommError" _
    (hFile AS LONG,_                                '[IN] Handle to open Comm device
     BYREF lpErrors AS DWORD,_                      '[OUT] Pointer to var to be filled with a mask indicating the type of error
     lpStat AS COMSTAT) _                           '[OUT] Pointer to structure containing devices status info
        AS LONG                                     'If function succeeds, returns non-zero. If function fails, returns 0. 

'Win32 File Handling Functions

'Create or open a new Comm device/file
DECLARE FUNCTION CreateFile Lib "kernel32" Alias "CreateFileA"_
    (lpFileName AS STRING, _                        '[IN] String that specifies name of object to create or open
    dwDesiredAccess AS DWORD, _                     '[IN] Specifies type of access to object
    dwShareMode AS DWORD, _                         '[IN] Specifies how object is to be shared
    lpSecurityAttributes AS SECURITYATTRIBUTES, _   '[IN] Pointer to Structure that determines whether object can be inherited by child processes
    dwCreationDisposition AS DWORD, _               '[IN] Specifies which action to take on files that exist/do not exist
    dwFlagsAndAttributes AS DWORD,_                 '[IN] Specifies the file attributes and flags
    hTemplateFile AS LONG) _                        '[IN] handle to template that supplies file attributes
        AS LONG                                     'If successful, returns handle to object/file created

' Writes data to a file 
' We are not using Overlapped (asynchronous) I/O 
DECLARE FUNCTION WriteFile Lib "kernel32" ALIAS "WriteFile"_
    (hFile AS LONG, _                               '[IN] Handle to open Comm device/file
     lpBuffer AS String, _                          '[IN] Pointer to buffer containing the data to be written to Comm device/file
     nNumberOfBytesToWrite AS DWORD, _              '[IN] Specifies number of bytes to write to file
     BYREF lpNumberOfBytesWritten AS DWORD, _       '[OUT] Pointer to var containing number of bytes written
     lpOverlapped AS OVERLAPPED) _                  '[IN] Pointer to structure containing info if Comm device/file was opened in Overlapped mode.
        AS LONG                                     'If function succeeds, returns non-zero. If function fails, returns 0. 
     
'Reads data from a file
'We are not using Overlapped (asynchronous) I/O 
DECLARE FUNCTION ReadFile Lib "kernel32" ALIAS "ReadFile"_
    (hFile AS LONG, _                               '[IN] Handle to open Comm device/file
     BYREF lpBuffer AS STRING, _                    '[OUT] Pointer to buffer that receives data from Comm device/file
     nNumberOfBytesToRead AS DWORD, _               '[IN] Specifies number of bytes to be read from file
     BYREF lpNumberOfBytesRead AS DWORD, _          '[OUT] Specifies number of bytes read from file
     lpOverlapped AS OVERLAPPED) _                  '[IN] Pointer to structure containing info if Comm device/file was opened in Overlapped mode.
        AS LONG                                     'If function succeeds, returns non-zero. If function fails, returns 0. 

DECLARE FUNCTION CloseHandle Lib "kernel32" ALIAS "CloseHandle" _
    (hObject AS LONG) _                             '[IN/OUT] Handle to open Comm device/file
        AS LONG                                     'If function succeeds, returns non-zero. If function fails, returns 0. 

'Internal Declarations
DECLARE SUB OnComError_EventTemplate (strErrorMessage AS STRING)
DECLARE SUB OnOpen_EventTemplate
DECLARE SUB OnClose_EventTemplate
DECLARE SUB OnWriteString_EventTemplate
DECLARE SUB OnReadString_EventTemplate


TYPE MyCom_Port EXTENDS QObject

  'EVENTS
  OnComError    AS EVENT (OnComError_EventTemplate)
  OnOpen        AS EVENT (OnOpen_EventTemplate)
  OnClose       AS EVENT (OnClose_EventTemplate)
  OnWriteString AS EVENT (OnWriteString_EventTemplate)
  OnReadString  AS EVENT (OnReadString_EventTemplate)

  'PROPERTIES
  Handle            AS LONG
  Port              AS STRING
  BaudRate          AS DWORD
  DataBits          AS BYTE
  Parity            AS BYTE
  StopBits          AS BYTE
  ReadBufSize       AS DWORD
  WriteBufSize      AS DWORD
  BytesNotRead      AS DWORD
  BytesNotWritten   AS DWORD
  Connected         AS BYTE

  'Default property values
  CONSTRUCTOR
    Port            = "COM1"
    BaudRate        = 9600
    DataBits        = 8
    Parity          = NOPARITY
    StopBits        = 1
    ReadBufSize     = 1024
    WriteBufSize    = 1024
    BytesNotRead    = 0
    BytesNotWritten = 0
    Connected       = FALSE
  END CONSTRUCTOR

  'METHODS

  'Method FormatError (Convert GetLastError codes to String messages)
  PRIVATE:
  FUNCTION FormatError AS STRING

    DIM lngSource     AS LONG
    DIM lngArguments  AS LONG
    DIM Buffer        AS STRING
    DIM lngRet        AS LONG

    lngSource   =0
    lngArguments=0
    Buffer=SPACE$(1024)
    
    lngRet=FormatMessage (FORMAT_MESSAGE_FROM_SYSTEM, _
                         lngSource, _
                         GetLastError, _
                         LANG_NEUTRAL, _
                         Buffer, _
                         LEN(Buffer), _
                         lngArguments)
                         
    Result=LEFT$(Buffer,lngRet)
  
  END FUNCTION

  'Method GetStatus
  PRIVATE:
  SUB GetCommStatus

    DIM lngStatus     AS LONG
    DIM dwErrorFlags  AS DWORD
    DIM udtCommStat   AS COMSTAT
  
  'Clear any previous errors and get current status.
    lngStatus = ClearCommError(MyCom_Port.Handle, _
                               dwErrorFlags, _
                               udtCommStat)
                               
    IF lngStatus = 0 THEN
      IF MyCom_Port.OnComError > 0 THEN
        CALLFUNC (MyCom_Port.OnComError, ERROR_CHANGING_PORTSETTINGS & MyCom_Port.FormatError)
      END IF 
    ELSE
      'Set BytesNotWritten and BytesNotRead Property
      MyCom_Port.BytesNotWritten = udtCommStat.cbOutQue
      MyCom_Port.BytesNotRead    = udtCommStat.cbInQue        
    END IF
    
  END SUB      

  'Method Open Port
  PUBLIC:
  SUB Open
    
    Dim udtCommTimeOuts As COMMTIMEOUTS
    DIM udtDCB          AS DCB
    DIM lngStatus       AS LONG
    
    'Open the Comm Port
    MyCom_Port.Handle = CreateFile(MyCom_Port.Port, _
                                GENERIC_READ_cmp OR GENERIC_WRITE_cmp, _
                                FILE_SHARE_READ OR FILE_SHARE_WRITE, _
                                0&, _ 
                                OPEN_EXISTING, _
                                FILE_ATTRIBUTE_NORMAL, _
                                0&)

    IF MyCom_Port.Handle = -1 THEN
      IF MyCom_Port.OnComError > 0 THEN
        CALLFUNC (MyCom_Port.OnComError,ERROR_OPEN_PORT & MyCom_Port.FormatError)
      END IF
      EXIT SUB
    END IF

    'Setup device buffers (1K is default).
    lngStatus = SetupComm(MyCom_Port.Handle,_
                    MyCom_Port.ReadBufSize,_
                    MyCom_Port.WriteBufSize)
                    
    IF lngStatus = 0 THEN
      IF MyCom_Port.OnComError > 0 THEN
        CALLFUNC (MyCom_Port.OnComError, ERROR_PORT_BUFFERS & MyCom_Port.FormatError)
      END IF 
      EXIT SUB
    END IF

    'Purge existing data in buffers.
    lngStatus = PurgeComm(MyCom_Port.Handle,_
                      PURGE_TXABORT Or PURGE_RXABORT Or PURGE_TXCLEAR Or PURGE_RXCLEAR)

    IF lngStatus = 0 THEN
      IF MyCom_Port.OnComError > 0 THEN
        CALLFUNC (MyCom_Port.OnComError, ERROR_PURGE_BUFFERS & MyCom_Port.FormatError)
      END IF 
      EXIT SUB
    END IF

    ' Set serial port timeouts values.
    udtCommTimeOuts.ReadIntervalTimeout         = -1
    udtCommTimeOuts.ReadTotalTimeoutMultiplier  = 0
    udtCommTimeOuts.ReadTotalTimeoutConstant    = 1000
    udtCommTimeOuts.WriteTotalTimeoutMultiplier = 0
    udtCommTimeOuts.WriteTotalTimeoutMultiplier = 1000


    lngStatus = SetCommTimeouts(MyCom_Port.Handle,_
                      udtCommTimeOuts)
                      
    IF lngStatus = 0 THEN
      IF MyCom_Port.OnComError > 0 THEN
        CALLFUNC (MyCom_Port.OnComError, ERROR_TIMEOUTS & MyCom_Port.FormatError)
      END IF 
      EXIT SUB
    END IF

    'Get the current state (DCB) - we retain current values for 
    'communication settings we don't explicitly set.
    lngStatus = GetCommState (MyCom_Port.Handle, _
                              udtDCB)

    IF lngStatus = 0 THEN
      IF MyCom_Port.OnComError > 0 THEN
        CALLFUNC (MyCom_Port.OnComError, ERROR_RETRIEVE_PORTSETTINGS & MyCom_Port.FormatError)
      END IF 
      EXIT SUB
    END IF

    'Set our Communications State
    udtDCB.BaudRate = MyCom_Port.BaudRate
    udtDCB.ByteSize = MyCom_Port.DataBits
    udtDCB.Parity   = MyCom_Port.Parity
    udtDCB.StopBits = MyCom_Port.StopBits

    'This changes our settings
    lngStatus = SetCommState (MyCom_Port.Handle, _
                              udtDCB)
                              
    IF lngStatus = 0 THEN
      IF MyCom_Port.OnComError > 0 THEN
        CALLFUNC (MyCom_Port.OnComError, ERROR_CHANGING_PORTSETTINGS & MyCom_Port.FormatError)
      END IF 
    ELSE
      'Set Connected Property
      MyCom_Port.Connected = TRUE
      'Raise OnOpen Event
      IF MyCom_Port.OnOpen > 0 THEN
        CALLFUNC MyCom_Port.OnOpen
      END IF 
    END IF

  END SUB

  'Method Close
  PUBLIC:
  SUB Close
  
    DIM lngStatus AS LONG
    
    'Close COM Port
    lngStatus = CloseHandle (MyCom_Port.Handle)

    IF lngStatus = 0 THEN
      IF MyCom_Port.OnComError > 0 THEN
        CALLFUNC (MyCom_Port.OnComError, ERROR_CLOSING_PORT & MyCom_Port.FormatError)
      END IF 
    ELSE
      'Set Connected Property
      MyCom_Port.Connected = FALSE
      'Raise OnClose Event
      IF MyCom_Port.OnClose > 0 THEN
        CALLFUNC MyCom_Port.OnClose
      END IF 
    END IF

  END SUB
  
  'Method Writestring
  PUBLIC:
  SUB WriteString (strData AS STRING, intWait AS INTEGER)

    DIM lngStatus       AS LONG
    DIM dwBytesToWrite  AS DWORD
    DIM dwByesWritten   AS DWORD
  
    'Set number of bytes to be sent.
    dwBytesToWrite=LEN(strData)

    'Output the data.
    lngStatus = WriteFile(MyCom_Port.Handle, _
                          strData, _
                          dwBytesToWrite, _
                          dwByesWritten, _
                          0&)
                       
    IF lngStatus = 0 THEN
      IF MyCom_Port.OnComError > 0 THEN
        CALLFUNC (MyCom_Port.OnComError, ERROR_WRITING_PORT & MyCom_Port.FormatError)
      END IF 
    ELSE
      'Wait for data to be written
      Sleep(intWait)
      'See if there are any bytes still waiting to be written
      MyCom_Port.GetCommStatus
      'If all data has been sent Raise OnWriteString event
      IF MyCom_Port.BytesNotWritten = 0 THEN
        IF MyCom_Port.OnWriteString > 0 THEN
          CALLFUNC MyCom_Port.OnWriteString
        END IF
      ELSE
        IF MyCom_Port.OnComError > 0 THEN
        CALLFUNC (MyCom_Port.OnComError, ERROR_SENDING_DATA)
      END IF
      END IF 
    END IF

  END SUB

  'Method ReadString
  PUBLIC:
  FUNCTION ReadString (dwRdSize AS DWORD, intWait AS INTEGER) AS STRING

    DIM lngStatus     AS LONG
    DIM dwBytesRead   AS DWORD
    DIM strReadBuffer AS STRING

    'Make enough space in memory for ReadFile to put data in.
    strReadBuffer=SPACE$(MyCom_Port.ReadBufSize)
      
    'Read data from buffer
    lngStatus = ReadFile(MyPort.Handle, _
                         strReadBuffer, _
                         dwRdSize, _
                         dwBytesRead, _
                         0&)
                         
    IF lngStatus = 0 THEN
      IF MyCom_Port.OnComError > 0 THEN
        CALLFUNC (MyCom_Port.OnComError, ERROR_READING_PORT & MyCom_Port.FormatError)
      END IF 
    ELSE
      'Set Return value for this Function
      Result = LEFT$(strReadBuffer, dwBytesRead)
      'Wait for more data to arrive in buffer
      Sleep(intWait)
      'Get number of bytes now waiting to be read
      MyCom_Port.GetCommStatus
      'Raise OnReadString event
      IF MyCom_Port.OnReadString > 0 THEN
        CALLFUNC MyCom_Port.OnReadString
      END IF 

    END IF

  END FUNCTION

END TYPE

