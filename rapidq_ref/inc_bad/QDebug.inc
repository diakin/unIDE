'QDEBUG.cmp 
'Version 0.9
'March 2, 2002
'by Pete Kleinschmidt

Declare Function EnableWindow Lib "user32" Alias "EnableWindow" _ 'Win32 fuction to enable or disable mouse and keyboard input to a specified window or control.
      (ByVal hwnd AS LONG, _                                      '[IN] Handle to window to be enabled or disabled
       ByVal fEnable AS LONG) _                                   '[IN] If TRUE (1), Window is enabled. If FALSE (0), Window is disabled.
         AS LONG                                                  'If window was previously disabled, the return value is nonzero
                                                                  'If window was not previously disabled, the return value is 0

DECLARE SUB frmDebugResize                          'Declare our resize Sub

CREATE frmDebug AS QFORM                            'Create our Debug form
 Caption = "Debug"
 OnResize    = frmDebugResize                       'When we resize, resize the Richedit box with it
 CREATE edtDebug AS QRICHEDIT                       'Add a Richedit box to it
  Height  = frmDebug.ClientHeight
  Width   = frmDebug.ClientWidth
  END CREATE
END CREATE

SUB frmDebugResize                                  'Richedit resize sub
  edtDebug.Height  = frmDebug.ClientHeight
  edtDebug.Width   = frmDebug.ClientWidth
END SUB

TYPE QDebug EXTENDS QObject                         'Begin defining our QDebug object
  Enabled AS SHORT PROPERTY SET Set_Enabled

  PROPERTY SET Set_Enabled(EnabledValue AS SHORT)   'Property Set for Enabled property
    IF EnabledValue = True THEN                     'If Enabled property is set to True
      frmDebug.Show                                 'Then show our Debug window
    ELSE                                            'Otherwise
      frmDebug.Close                                'Close the Debug window if it is open
    END IF
  END PROPERTY
  
  CONSTRUCTOR
    Enabled=True                                    'Default to Enabled
  END CONSTRUCTOR
  
  SUB Print (StringToPrint AS STRING)               'Debug.Print method
    IF QDebug.Enabled = True THEN                   'If Debug Enabled property is True
      edtDebug.AddStrings(StringToPrint)            'Add the value to our Richedit box
      edtDebug.selstart=len(edtDebug.text)          'Move the cursor to the last character in the RichEdit box
      SENDMESSAGE(edtDebug.handle, &HB7, 0, 0)      'send message to richedit control to scroll so cursor is in view (&HB7 = EM_SCROLLCARET)
      EnableWindow (frmDebug.Handle, True)          'enable mouse and keyboard input to the Debug form.
      DOEVENTS                                      'Let Windows do stuff
    END IF
  END SUB
  
END TYPE

DIM Debug AS QDebug                                 'Create our Debug object
Debug.Enabled = True                                'Set the Enabled property to show the Debug form