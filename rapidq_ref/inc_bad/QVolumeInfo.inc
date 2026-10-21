'************************************************************************************
'*                                                                                  *
'*  QVolumeInfo: Retrieve infromation from your connected volumes                   *
'*  ------------------------------------------------------------------------------  *
'*                                                                                  *
'*  Poperties:                                                                      *
'*      Serial: Serial given to volume during creation of partitions                *
'*      Name: Name of Drive                                                         *
'*      FileSystem: NTFS, FAT32 etc...                                              *
'*      DriveRoot: Driveletter of current drive                                     *
'*                                                                                  *
'*      Bytes: bytes / sector                                                       *
'*      Sectors: sectors / cluster                                                  *
'*      TotalClusters: total number of cluster on volume                            *
'*      FreeClusters: number of free clusters on volume                             *
'*      TotalBytes: total number of bytes on volume                                 *
'*      FreeBytes: number of free bytes on volume                                   *
'*      TotalSpace: short string representation of total space on volume            *
'*      FreeSpace: short string representation of free space on volume              *
'*                                                                                  *
'*      DriveType: drivetype as integer                                             *
'*      DriveTypeString: string representation of drivetype                         *
'*      DriveTypeUnknown: 0 if drivetype is known, 1 if drivetype is unknown        *
'*                                                                                  *
'*  ------------------------------------------------------------------------------  *
'*                                                                                  *
'*  Methods                                                                         *
'*      SelectDrive(DriveRoot): call this first before retrieving properties        *
'*      GetStringFormat(NumberOfBytes): returns a short string rep. (xx KB, MB, GB) *
'*                                                                                  *
'*  ------------------------------------------------------------------------------  *
'*  Author: Alain Besseleer alias Midipro2000                                       *
'*  Date: July 25, 2009                                                             *
'*  Version: 1.0                                                                    *
'*                                                                                  *
'************************************************************************************

$DEFINE __QVOLUMEINFO_INC

$IFNDEF __WIN32API				   'windows 32 definitions
$IFNDEF __QDRIVE_INC                'shared constants

    Const DRIVE_UNKNOWN As Long = 0
    Const DRIVE_NO_ROOT_DIR As Long = 1
    Const DRIVE_REMOVABLE As Long = 2
    Const DRIVE_FIXED As Long = 3
    Const DRIVE_REMOTE As Long = 4
    Const DRIVE_CDROM As Long = 5
    Const DRIVE_RAMDISK As Long = 6
$ENDIF
$ENDIF


Declare Function GetVolumeInformation_INC Lib "Kernel32" Alias "GetVolumeInformationA" _
    (ByVal lpRootPathName As String,  _
    byref lpVolumeNameBuffer As string, _ 
    ByVal nVolumeNameSize As Long,  _
    Byref lpVolumeSerialNumber As long,  _
    ByVal lpMaximumComponentLength As Long, _ 
    ByVal lpFileSystemFlags As Long,  _
    ByRef lpFileSystemNameBuffer As string, _ 
    ByVal nFileSystemNameSize As Long) As Long

Private Declare Function GetDiskFreeSpace_INC Lib "kernel32" Alias "GetDiskFreeSpaceA" _
    (ByVal lpRootPathName As String, _
    byref lpSectorsPerCluster As Long, _
    byref lpBytesPerSector As Long, _
    byref lpNumberOfFreeClusters As Long, _
    byref lpTtoalNumberOfClusters As Long) As Long

Declare Function GetDriveType_INC Lib "kernel32" Alias "GetDriveTypeA" _
    (ByVal nDrive As String) As Long


type QVolumeInfo extends QObject
    
    Public:
        Serial as string
        Name as string
        FileSytem as string
        DriveRoot as string
        
        Bytes as long
        Sectors as long
        TotalClusters as long
        FreeClusters as long
        
        TotalBytes as double
        FreeBytes as double
        
        TotalSpace as string
        FreeSpace as string
        
        DriveType as long
        DriveTypeString as string
        DriveTypeUnknown as integer
        
        
    function GetStringFormat(Bytes as double) as string
        select case bytes
        case is < 1024
            result = str$(Bytes) + " Bytes"
            
        case 1024 to 1024^2 -1
            result = format$("%.1f KB", Bytes/1024)
            
        case 1024^2 to 1024^3 -1
            result = format$("%.1f MB", Bytes/1024^2)
            
        case 1024^3 to 1024^4 -1
            result = format$("%.1f GB", Bytes/1024^3)
        
        case is => 1024^4
            result = format$("%.1f TB", Bytes/1024^4)
            
        end select
    end function
    
    
    sub SelectDrive(DriveRoot as string)
        'format driveroot
        DEFSTR MyDriveRoot = left$(DriveRoot, 1) + ":\"         'need to copy this string!
        QVolumeInfo.Driveroot = MyDriveRoot - "\"
        
        '--- first call: GetVolumeInformation 
        Dim Serial As long
        Dim VName As string
        Dim FSName As String

        'Create buffers
        VName = String$(255, Chr$(0))
        FSName = String$(255, Chr$(0))

        'Get the volume information
        GetVolumeInformation_INC (MyDriveRoot, VName, 255, Serial , 0, 0, FSName, 255)
    
        'Strip the extra chr$(0)'s
        VName = VName - Chr$(0)
        FSName = FSName - Chr$(0)
        QVolumeInfo.Serial = hex$(Serial)
        QVolumeInfo.Name = VName
        QVolumeInfo.FileSytem = FSName
        
        '--- second call: GetDiskFreeSpace 
        
        Dim Bytes as Long
        Dim Sectors as Long
        Dim TotalClusters as Long
        Dim FreeClusters as Long
        
        Dim TotalBytes as double
        Dim FreeBytes as double
    
        'Retrieve information
        GetDiskFreeSpace_INC (MyDriveRoot, Sectors, Bytes, FreeClusters, TotalClusters)
        
        QVolumeInfo.Sectors = Sectors 
        QVolumeInfo.Bytes = Bytes 
        QVolumeInfo.FreeClusters = FreeClusters 
        QVolumeInfo.TotalClusters = TotalClusters 
    
        TotalBytes = TotalClusters * Sectors * Bytes
        QVolumeInfo.TotalBytes = TotalBytes 
    
        FreeBytes = FreeClusters * Sectors * Bytes
        QVolumeInfo.FreeBytes = FreeBytes 
        
        QVolumeInfo.TotalSpace = QVolumeInfo.GetStringFormat(TotalBytes)
        QVolumeInfo.FreeSpace = QVolumeInfo.GetStringFormat(FreeBytes)
        
        '--- third call: GetDriveType
        
        Dim DType as long
        
        DType = GetDriveType_INC(MyDriveRoot)
        QVolumeInfo.DriveType = DType 
        
        select case DType 
        Case 2
            QVolumeInfo.DriveTypeString = "Removable"
            QVolumeInfo.DriveTypeUnknown = 0
        Case 3
            QVolumeInfo.DriveTypeString = "Drive Fixed"
            QVolumeInfo.DriveTypeUnknown = 0
        Case Is = 4
            QVolumeInfo.DriveTypeString = "Remote"
            QVolumeInfo.DriveTypeUnknown = 0
        Case Is = 5
            QVolumeInfo.DriveTypeString = "Cd-Rom"
            QVolumeInfo.DriveTypeUnknown = 0
        Case Is = 6
            QVolumeInfo.DriveTypeString = "Ram disk"
            QVolumeInfo.DriveTypeUnknown = 0
        Case Else
            QVolumeInfo.DriveTypeString = "Unknown"
            QVolumeInfo.DriveTypeUnknown = 1
        End Select

    End sub 
    
end type


