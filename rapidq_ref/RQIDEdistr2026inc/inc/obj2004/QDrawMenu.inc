'=======================================================
' Type Objet
' Classe QDrawMenu Version 1.3
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

Const ODT_MENU=1
Const ODS_SELECTED=1
Const ODS_GRAYED=2
Const ODS_DISABLED=4
Const ODS_CHECKED=8
Const WM_DRAWITEM=&H2B
Const WM_MEASUREITEM=&H2C
Const MF_BYCOMMAND=0
Const MF_BYPOSITION=&H400
Const MF_OWNERDRAW=&H100
Const MF_GRAYED=&H1
Const MF_DISABLED=&H2
Const MF_STRING=0
Const MF_BITMAP=4

Const COLOR_MENU=4 'Menu
Const COLOR_MENUTEXT=7 'Window Text
Const COLOR_HIGHLIGHT=13 'Selected item background
Const COLOR_HIGHLIGHTTEXT=14 'Selected menu item
Const COLOR_GRAYTEXT=17 'Grey text, of zero if dithering is used.

TYPE TMEASUREITEMSTRUCT
    CtlType AS LONG
    CtlID AS LONG
    itemID AS LONG
    itemWidth AS LONG
    itemHeight AS LONG
    itemData AS DWORD
END TYPE

TYPE TDRAWITEMSTRUCT
    CtlType AS LONG
    CtlID AS LONG
    itemID AS LONG
    itemAction AS LONG
    itemState AS LONG
    hwndItem AS LONG
    hDC AS LONG
    left AS LONG
    top AS LONG
    right AS LONG
    bottom AS LONG
    itemData AS DWORD
END TYPE

DIM MeasureItem AS TMEASUREITEMSTRUCT
DIM DrawItem AS TDRAWITEMSTRUCT
DIM Mem AS QMEMORYSTREAM

Declare Function GetSysColor Lib "user32" Alias "GetSysColor" (nIndex As Long) As Long
DECLARE FUNCTION ModifyMenu LIB "USER32" ALIAS "ModifyMenuA" (hMenu AS LONG,uPosition AS LONG,uFlags AS LONG,uIDNewItem AS LONG,lpNewItem AS LONG) AS LONG

Type QdrawMenu extends QOBJECT
  PRIVATE:
    Text as qbitmap
    Bitmap AS QBITMAP
    Font AS QFONT
    image(10000) as QBitmap
    button(10000) as boolean

  '=======================================
  ' Mйthode affiche le texte de menu
  '=======================================
  Sub DrawText(cl as integer)
    dim S as string
    dim I as integer
    dim X as integer
    dim Y as integer

    S=VARPTR$(DrawItem.itemData)
    X=QDrawMenu.image(DrawItem.itemId).width+9
    if INSTR(S,"&")>0 then
      QDrawMenu.Font.AddStyles(2)
      QDrawMenu.Bitmap.Font=QDrawMenu.Font
      Y=((DrawItem.bottom-DrawItem.top)-QDrawMenu.Bitmap.TextHeight(S))\2  
      QDrawMenu.Font.DelStyles(2)
      QDrawMenu.Bitmap.Font=QDrawMenu.Font
    else
      Y=((DrawItem.bottom-DrawItem.top)-QDrawMenu.Bitmap.TextHeight(S))\2  
    end if
    I=INSTR(S, "&")
    IF I THEN
      QDrawMenu.Bitmap.TextOut(DrawItem.left+X,DrawItem.top+Y,LEFT$(S, I-1),cl,-1)
      QDrawMenu.Font.AddStyles(2)
      QDrawMenu.Bitmap.Font=QDrawMenu.Font
      QDrawMenu.Bitmap.TextOut(DrawItem.left+X+QDrawMenu.Bitmap.TextWidth(LEFT$(S, I-1)),DrawItem.top+Y,MID$(S, I+1, 1),cl,-1)
      QDrawMenu.Font.DelStyles(2)
      QDrawMenu.Bitmap.Font=QDrawMenu.Font
      S=S - "&"
      QDrawMenu.Bitmap.TextOut(DrawItem.left+X+QDrawMenu.Bitmap.TextWidth(LEFT$(S, I)),DrawItem.top+Y,MID$(S, I+1, LEN(S)),cl,-1)
    ELSE
      QDrawMenu.Bitmap.TextOut(DrawItem.left+X,DrawItem.top+Y,S,cl,-1)
    END IF
  End Sub

  '=======================================
  ' Mйthode affiche le bouton de menu
  '=======================================
  Sub DrawButton()
    dim width as integer
    dim height as integer

    width=QDrawMenu.image(DrawItem.itemId).width+2
    height=QDrawMenu.image(DrawItem.itemId).height+2  
    QDrawMenu.Bitmap.Line(DrawItem.left,DrawItem.top,DrawItem.left+width,DrawItem.top,&HFFFFFF)
    QDrawMenu.Bitmap.Line (DrawItem.left,DrawItem.top,DrawItem.left,DrawItem.top+height,&HFFFFFF)
    QDrawMenu.Bitmap.Line (DrawItem.left,DrawItem.top+height,DrawItem.left+width,DrawItem.top+height,&H808080)
    QDrawMenu.Bitmap.Line (DrawItem.left+width,DrawItem.top+height,DrawItem.left+width,DrawItem.top,&H808080)
  end sub

  PUBLIC:  

  '========================================
  ' Procedure winproc pour la gestion menu
  '========================================
  Sub MenuProc (hwnd AS LONG,uMsg AS LONG,wParam AS LONG,lParam AS LONG)

      IF uMsg=WM_MEASUREITEM THEN
         Mem.Position = 0
         '-- lParam& is a pointer to the TMeasureItem structure
         Mem.MemCopyFrom(lParam, SIZEOF(MeasureItem))
         Mem.Position = 0
         '-- After we copy it we have to read the structure
         Mem.ReadUDT(MeasureItem)
         IF MeasureItem.CtlType = ODT_MENU THEN
            '-- There are other types, such as listboxes, etc. that we
            '-- want to avoid.
            MeasureItem.itemWidth = QDrawMenu.Text.TextWidth(VARPTR$(MeasureItem.itemData)-"&")+QDrawMenu.image(MeasureItem.itemId).width+9      '-- Should be big enough to fit
            MeasureItem.itemHeight = QDrawMenu.image(MeasureItem.itemId).height+3     '-- your items.
            Mem.Position = 0
            Mem.WriteUDT(MeasureItem)       '-- Write structure back to memory
            Mem.Position = 0
            '-- Copy this structure back to the original address, so
            '-- changes can take effect
            Mem.MemCopyTo(lParam, SIZEOF(MeasureItem))
         END IF
      ELSEIF uMsg=WM_DRAWITEM THEN
         Mem.Position = 0
         Mem.MemCopyFrom(lParam, SIZEOF(DrawItem))
         Mem.Position = 0
         Mem.ReadUDT(DrawItem)
         IF DrawItem.CtlType = ODT_MENU THEN
            QDrawMenu.Bitmap.Handle = DrawItem.hDC
            QDrawMenu.image(DrawItem.itemId).transparent=true
            'QDrawMenu.image(DrawItem.itemId).transparentColor=GetSysColor(COLOR_MENU)
            IF (ODS_SELECTED AND DrawItem.itemState) <> 0 THEN
               if QDrawMenu.button(DrawItem.itemId) then
                 QDrawMenu.Bitmap.FillRect(DrawItem.left+QDrawMenu.image(DrawItem.itemId).width+4,DrawItem.top,DrawItem.right,DrawItem.bottom,GetSysColor(COLOR_HIGHLIGHT))
               else
                 QDrawMenu.Bitmap.FillRect(DrawItem.left,DrawItem.top,DrawItem.right,DrawItem.bottom,GetSysColor(COLOR_HIGHLIGHT))
               end if
               QDrawMenu.Bitmap.Draw (DrawItem.left+1,DrawItem.top+1,QDrawMenu.image(DrawItem.itemId).bmp)
               if (ODS_DISABLED and DrawItem.itemState)<>0 then
                 QDrawMenu.DrawText(GetSysColor(COLOR_GRAYTEXT))
               else
                 if QDrawMenu.button(DrawItem.itemId) then QDrawMenu.DrawButton
                 QDrawMenu.DrawText(GetSysColor(COLOR_HIGHLIGHTTEXT))
               end if
            ELSEIF(ODS_DISABLED AND DrawItem.itemState)<>0 THEN 
               QDrawMenu.Bitmap.FillRect(DrawItem.left,DrawItem.top,DrawItem.right,DrawItem.bottom,GetSysColor(COLOR_MENU))
               QDrawMenu.Bitmap.Draw (DrawItem.left+1,DrawItem.top+1,QDrawMenu.image(DrawItem.itemId).bmp)
               QDrawMenu.DrawText(GetSysColor(COLOR_GRAYTEXT))
            ELSE
               QDrawMenu.Bitmap.FillRect(DrawItem.left,DrawItem.top,DrawItem.right,DrawItem.bottom,GetSysColor(COLOR_MENU))
               QDrawMenu.Bitmap.Draw (DrawItem.left+1,DrawItem.top+1,QDrawMenu.image(DrawItem.itemId).bmp)
               QDrawMenu.DrawText(GetSysColor(COLOR_MENUTEXT))
            END IF
         END IF
      END IF
  END Sub

    
  '==============================================
  ' Mйthode ajoute un bitmap a l'item menu 
  '==============================================
  Sub AddBitmap(SubMenu as Qmenuitem,item as Qmenuitem,picture as Qbitmap,button as boolean,backcolor as long)
    dim s as string
    dim flag as integer
  
    s=item.caption
    flag=mf_ByPosition+mf_OwnerDraw
    if item.Enabled=false then flag=flag+mf_disabled
    ModifyMenu(SubMenu.Handle,item.MenuIndex,flag,Item.Command,VARPTR(s))
    QDrawMenu.image(Item.Command).bmp=picture.bmp
    QDrawMenu.image(Item.Command).transparentColor=backcolor
    if button then QDrawMenu.button(Item.Command)=true
  End Sub
  
  '==============================================
  ' Mйthode supprime un bitmap de l'item menu 
  '==============================================
  Sub DelBitmap(SubMenu as Qmenuitem,item as Qmenuitem)
    dim s as string
    dim flag as integer
  
    s=item.caption
    flag=mf_ByPosition+mf_string
    if item.Enabled=false then flag=flag+mf_disabled
    ModifyMenu(SubMenu.Handle,item.MenuIndex,flag,Item.Command,VARPTR(s))
    QDrawMenu.image(Item.Command).transparent=false
  End Sub
End Type
