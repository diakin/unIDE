'=======================================================
' Type Objet
' Classe QTextEdit
'=======================================================
$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

$IFNDEF boolean
  $DEFINE boolean integer
$ENDIF

Declare Function SendMessageA Lib "user32" Alias "SendMessageA" (hwnd As Long, wMsg As Long, wParam As Long, lParam As Long) As Long

TYPE QTEXTEDIT EXTENDS QRICHEDIT
  PRIVATE:
    MaxMenu AS QPOPUPMENU
    mnuUndo AS QMENUITEM
    mnuSep1 AS QMENUITEM
    mnuCut  AS QMENUITEM
    mnuCopy AS QMENUITEM
    mnuPaste AS QMENUITEM
    mnuSep2 AS QMENUITEM
    mnuSelectAll AS QMENUITEM
    
    EVENT MaxMenu.OnPopup
      QTEXTEDIT.mnuUndo.Enabled=SendMessageA(QTEXTEDIT.Handle,&HC6,0,0)
      if QTEXTEDIT.SelLength>0 then
        QTEXTEDIT.mnuCut.Enabled =true
        QTEXTEDIT.mnuCopy.Enabled=true
      else
        QTEXTEDIT.mnuCut.Enabled=false
        QTEXTEDIT.mnuCopy.Enabled=false
      end if
      if LEN(ClipBoard.Text)>0 then 
        QTEXTEDIT.mnuPaste.Enabled=true
      else 
        QTEXTEDIT.mnuPaste.Enabled=false
      end if
      if LEN(QTEXTEDIT.Text)>0 then 
        QTEXTEDIT.mnuSelectAll.Enabled=true
      else
        QTEXTEDIT.mnuSelectAll.Enabled=false
      end if
    END EVENT
        
  PUBLIC:
    UsePopup AS boolean PROPERTY SET Set_Popup
    UndoCaption as string PROPERTY SET SetUndoCaption
    CutCaption as string PROPERTY SET SetCutCaption
    CopyCaption as string PROPERTY SET SetCopyCaption
    PasteCaption as string PROPERTY SET SetPasteCaption
    SelectAllCaption as string PROPERTY SET SetSelectAllCaption
    
    '========================================
    ' Proprieté utilisation du menu popup
    '========================================          
    PROPERTY SET Set_Popup(Use as boolean)
      QTEXTEDIT.MaxMenu.AutoPopup=Use
    END PROPERTY
    
    '========================================
    ' Proprieté libellé du menu annuler
    '========================================          
    PROPERTY SET SetUndoCaption(caption as string)
      QTEXTEDIT.mnuUndo.Caption=caption
    END PROPERTY
     
    '========================================
    ' Proprieté libellé du menu couper
    '========================================          
    PROPERTY SET SetCutCaption(caption as string)
      QTEXTEDIT.mnuCut.Caption=caption
    END PROPERTY
    
    '========================================
    ' Proprieté libellé du menu copier
    '========================================          
    PROPERTY SET SetCopyCaption(caption as string)
      QTEXTEDIT.mnuCopy.Caption=caption
    END PROPERTY
    
    '========================================
    ' Proprieté libellé du menu coller
    '========================================          
    PROPERTY SET SetPasteCaption(caption as string)
      QTEXTEDIT.mnuPaste.Caption=caption
    END PROPERTY
    
    '========================================
    ' Proprieté libellé du menu selectionner
    '========================================          
    PROPERTY SET SetSelectAllCaption(caption as string)
      QTEXTEDIT.mnuSelectAll.Caption=caption
    END PROPERTY
        
    '========================================
    ' Méthode annuler derniere modification
    '========================================          
    SUB Undo
      SendMessage(QTEXTEDIT.Handle,&HC7,0,0)
    END SUB 
        
    '========================================
    ' Méthode couper
    '========================================          
    SUB Cut
      QTEXTEDIT.CutToClipBoard
    END SUB
        
    '========================================
    ' Méthode copier
    '========================================          
    SUB Copy
      QTEXTEDIT.CopyToClipboard
    END SUB
        
    '========================================
    ' Méthode coller
    '========================================          
    SUB Paste
      QTEXTEDIT.PasteFromClipboard
    END SUB
                
    '========================================
    ' Méthode selectionner tout
    '========================================          
    SUB SelectAl
      QTEXTEDIT.SelectAll
    END SUB
        
    '========================================
    ' Méthode limitation nombre de caractere
    '========================================          
    SUB Limit(value as long)
      SendMessage(QTEXTEDIT.handle,&hc5,value,0)
    End Sub

    '========================================
    ' Méthode remplace le texte selectionner
    '========================================          
    SUB ReplaceSel(text as string)
      dim replace as string
      
      if QTEXTEDIT.SelLength>0 then
        replace=text
        SendMessage(QTEXTEDIT.handle,&hc2,0,varptr(replace))
      end if
    End Sub
    
    '========================================================================
    ' Méthode recherche de chaine,retourne la position de la chaine trouvée
    '========================================================================
    Function Find(start as long,text as string,case as boolean) as long
      if case then
        if Instr(start,QTEXTEDIT.Text,text)>0 then 
          QTEXTEDIT.SelStart = Instr(start,QTEXTEDIT.Text,text)-1
          QTEXTEDIT.SelLength = Len(text)
          result=QTEXTEDIT.SelStart+1
        else
          result=0
        end if
      else
        if Instr(start,Ucase$(QTEXTEDIT.Text),Ucase$(text))>0 then 
          QTEXTEDIT.SelStart = Instr(start,Ucase$(QTEXTEDIT.Text),Ucase$(text))-1
          QTEXTEDIT.SelLength = Len(text)
          result=QTEXTEDIT.SelStart+1
        else
          result=0
        end if
      end if
    End Function
    
    '=================================================
    ' Méthode deplace le curseur a la ligne demandée
    '=================================================          
    Sub LinesScroll(number as long)
      dim i as integer
      dim count as long
      
      if number<=QTEXTEDIT.LineCount then
        for i=0 to number-2
          count=count+len(QTEXTEDIT.line(i))+2
        next i
        QTEXTEDIT.SelStart=count
      end if
    end sub

    '=================================================
    ' Méthode retourne la possibilité d'annulation
    '=================================================
    Function CanUndo as boolean
      result=SendMessageA(QTEXTEDIT.Handle,&HC6,0,0)
    End Function          
                        
    constRUCTOR
      mnuUndo.Caption="&Undo"
      mnuUndo.OnClick=QTEXTEDIT.Undo
      mnuUndo.ShortCut="CTRL+Z"
      mnuSep1.Caption="-"
      mnuCut.Caption="Cu&t"
      mnuCut.OnClick=QTEXTEDIT.Cut
      mnuCut.ShortCut="CTRL+X"
      mnuCopy.Caption="&Copy"
      mnuCopy.OnClick=QTEXTEDIT.Copy
      mnuCopy.ShortCut="CTRL+C"
      mnuPaste.Caption="&Paste"
      mnuPaste.OnClick=QTEXTEDIT.Paste
      mnuPaste.ShortCut="CTRL+V"
      mnuSep2.Caption="-"
      mnuSelectAll.Caption="Select &All"
      mnuSelectAll.OnClick=QTEXTEDIT.SelectAl
      mnuSelectAll.ShortCut="CTRL+A"
      MaxMenu.AddItems QTEXTEDIT.mnuUndo,QTEXTEDIT.mnuSep1,QTEXTEDIT.mnuCut,QTEXTEDIT.mnuCopy,QTEXTEDIT.mnuPaste,QTEXTEDIT.mnuSep2,QTEXTEDIT.mnuSelectAll
      PopupMenu=QTEXTEDIT.MaxMenu
      UsePopup=1
    END constRUCTOR
END TYPE

$UNDEF QRICHEDIT
$DEFINE QRICHEDIT QTEXTEDIT
      