#include once "rqreg.bi"
Dim Registry As QREGISTRY
Print "root "; Hex(Registry.RootKey)
Print "open "; Registry.OpenKey("Software\RqLclTest\Sub1", 1)
Print "path "; Registry.CurrentPath
Registry.WriteString "Name", "Привет"
Registry.WriteString "Empty", ""
Registry.WriteInteger "Count", 12345
Registry.WriteFloat "Pi", 3.25
Dim Bytes(0 To 3) As UByte = {1, 2, 3, 250}
Registry.WriteBinary "Bin", Bytes(), 4
Print "str ["; Registry.ReadString("Name"); "] empty ["; Registry.ReadString("Empty"); "] missing ["; Registry.ReadString("Nope"); "]"
Print "int "; Registry.ReadInteger("Count"); " float "; Registry.ReadFloat("Pi"); " bin "; Registry.ReadBinary("Bin", 3)
Print "exists "; Registry.ValueExists("Count"); Registry.ValueExists("Nope")
Print "values "; Registry.ValueItemCount; " first "; Registry.ValueItem(0)
Print "rename "; Registry.RenameValue("Count", "Count2"); " "; Registry.ReadInteger("Count2")
Print "missing int "; Registry.ReadInteger("Nope")
Print "type "; Registry.GetDataType("Pi"); " size "; Registry.GetDataSize("Name")
Print "create "; Registry.CreateKey("Child\Deep")
Print "subkeys "; Registry.KeyItemCount; " "; Registry.KeyItem(0); " has "; Registry.HasSubKeys
Print "open rel "; Registry.OpenKey("Child", 0); " path "; Registry.CurrentPath
Print "open abs "; Registry.OpenKey("\Software\RqLclTest", 0); " path "; Registry.CurrentPath
Print "move "; Registry.MoveKey("Sub1", "Sub2", 1); " "; Registry.KeyExists("Sub1"); Registry.KeyExists("Sub2"); Registry.KeyExists("Sub2\Child\Deep")
Print "moved value "; Registry.OpenKey("Sub2", 0); " "; Registry.ReadString("Name")
Registry.CloseKey
Registry.RootKey = &H80000002
Print "hklm "; Registry.OpenKey("\Software", 0); " "; Registry.KeyItemCount > 0
Registry.RootKey = &H80000001
Print "delete "; Registry.DeleteKey("\Software\RqLclTest"); " "; Registry.KeyExists("\Software\RqLclTest")
