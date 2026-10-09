$INCLUDE "API.INC"
$TYPECHECK ON
TYPE QMenu EXTENDS QOBJECT

    PUBLIC:
       Descrip AS WORD
       Panel AS WORD
       Font AS QFONT
       imgs AS QIMAGELIST              'List of images for menu
       
    PRIVATE:
    
       Bmp AS QBITMAP
       hWnd AS INTEGER
       pOldProc AS LONG
       lpfnWndProc AS LONG
       retval AS LONG
       bitmap() AS LONG
       descp() AS STRING

    PRIVATE:
       
       FUNCTION GetMenuName(Mhnd AS LONG, ID AS LONG) AS STRING
          DIM Buffer AS STRING, retval AS LONG, MenuStr AS STRING
          WITH mii
             .cbSize = SIZEOF (mii)
             .fMask = MIIM_STATE OR MIIM_TYPE OR MIIM_SUBMENU OR MIIM_ID
             ' Make room in the string buffer.
             Buffer = SPACE$(256)
             .dwTypeData = VARPTR(Buffer)
             .cch = 256
             retval = GetMenuItemInfo(Mhnd, ID, MF_BYCOMMAND, mii)
             MenuStr = LEFT$(VARPTR$(.dwTypeData), .cch)
          END WITH
          result = MenuStr
       END FUNCTION
       
       SUB ShowDescription (wParam AS LONG, LParam AS LONG)
          DIM MainM AS LONG, a AS STRING
          a = LEFT$(hex$(wParam),4)
          if lParam = 0 and a = "FFFF" then  ' The system has closed the menu
             StatusBar.Panel(QMenu.Panel).Caption = ""  
          ELSE                               ' Find Description
              MainM = GetMenu (QMenu.hWnd)
             IF lParam = MainM THEN
                StatusBar.Panel(QMenu.Panel).Caption = "Press ESC key to exit menu mode" 
              ELSE
                  With mii
                  .fMask = MIIM_ID
                  QMenu.retval = GetMenuItemInfo(lParam, wParam MOD &H10000, MF_BYCOMMAND, mii)
                  StatusBar.Panel(QMenu.Panel).Caption = QMenu.descp(.wID)
              END IF
              END WITH
          END IF
       END SUB
           
       SUB DrawText (Hilite AS WORD)
          DIM S AS STRING, I AS WORD, clr AS LONG
          IF HILITE THEN clr = clWhite ELSE clr = 0
          S = QMenu.GetMenuName(DrawItem.hwndItem, DrawItem.itemID)
          S = REPLACESUBSTR$(S, CHR$(9), "      ")
          I = INSTR(S, "&")
          WITH QMenu
             IF I THEN
                .Bmp.TextOut(DrawItem.left+21,DrawItem.top+3,LEFT$(S, I-1),clr, -1)
                .Font.AddStyles(fsUnderline)
                .Bmp.Font = .Font
                .Bmp.TextOut(DrawItem.left + 21 + .Bmp.TextWidth(LEFT$(S, I-1)),DrawItem.top+3,MID$(S, I+1, 1),clr,-1)
                .Font.DelStyles(fsUnderline)
                .Bmp.Font = .Font
                S = S - "&"
                .Bmp.TextOut(DrawItem.left + 21 + .Bmp.TextWidth(LEFT$(S, I)),DrawItem.top+3,MID$(S, I+1, LEN(S)),clr,-1)
             ELSE
                .Bmp.TextOut(DrawItem.left + 21,DrawItem.top+3,S,clr,-1)
             END IF
          END WITH
       END SUB
    
       FUNCTION WindowProc (hwnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
          SELECT CASE uMsg
             CASE WM_MEASUREITEM
                Mem.Position = 0
                Mem.MemCopyFrom(lParam, SIZEOF(MeasureItem))
                Mem.Position = 0
                Mem.ReadUDT(MeasureItem)
                IF MeasureItem.CtlType = ODT_MENU THEN
                   MeasureItem.itemWidth = 60      '-- Should be big enough to fit
                   MeasureItem.itemHeight = 19     '-- your items.
                   Mem.Position = 0
                   Mem.WriteUDT(MeasureItem)       '-- Write structure back to memory
                   Mem.Position = 0
                   Mem.MemCopyTo(lParam, SIZEOF(MeasureItem))
                   Result = -1
                ELSE
                   WindowProc = CallWindowProc(QMenu.pOldProc, hwnd, uMsg, wParam, lParam)
                END IF
             CASE WM_DRAWITEM 
                Mem.Position = 0
                Mem.MemCopyFrom(lParam, SIZEOF(DrawItem))
                Mem.Position = 0
                Mem.ReadUDT(DrawItem)
                IF DrawItem.CtlType = ODT_MENU THEN
                   WITH Qmenu
                   .Bmp.Handle = DrawItem.hDC
                   IF (ODS_SELECTED AND DrawItem.itemState) <> 0 THEN
                      .Bmp.FillRect(DrawItem.left+20,DrawItem.top,DrawItem.right,DrawItem.bottom, &H800000)
                      .Bmp.Draw (DrawItem.left+1,DrawItem.top+1,.imgs.GetBMP(.bitmap(DrawItem.itemID)))
                      .Bmp.Line (DrawItem.left,DrawItem.top,DrawItem.left+18,DrawItem.top,&HFFFFFF)
                      .Bmp.Line (DrawItem.left,DrawItem.top,DrawItem.left,DrawItem.top+18,&HFFFFFF)
                      .Bmp.Line (DrawItem.left,DrawItem.top+18,DrawItem.left+18,DrawItem.top+18,&H808080)
                      .Bmp.Line (DrawItem.left+18,DrawItem.top+18,DrawItem.left+18,DrawItem.top,&H808080)
                      .DrawText 1
                   ELSE
                      .Bmp.FillRect(DrawItem.left,DrawItem.top,DrawItem.right,DrawItem.bottom, clMenu)
                      .Bmp.Draw (DrawItem.left+1,DrawItem.top+1,.imgs.GetBMP(.bitmap(DrawItem.itemID)))
                      .DrawText 0
                   END IF
                   END WITH
                   Result = -1
                ELSE 
                   WindowProc = CallWindowProc(QMenu.pOldProc, hwnd, uMsg, wParam, lParam)
                END IF
             CASE WM_MENUSELECT
                IF QMenu.Descrip THEN
                   QMenu.ShowDescription wParam, LParam
                END IF
                WindowProc = CallWindowProc(QMenu.pOldProc, hwnd, uMsg, wParam, lParam)
             CASE ELSE
                WindowProc = CallWindowProc(QMenu.pOldProc, hwnd, uMsg, wParam, lParam)
          END SELECT
       END FUNCTION
       
       
    PUBLIC:
    
       SUB Set (form AS QFORM)
          WITH QMenu
             .hWnd = form.Handle
             .lpfnWndProc = CODEPTR(QMenu.WindowProc)
             .pOldProc = SetWindowLong(.hWnd, GWL_WNDPROC, .lpfnWndProc)
          END WITH
       END SUB
       
       SUB Close
          WITH QMenu
           .retval = SetWindowLong(.hWnd, GWL_WNDPROC, .pOldProc)
          END WITH
       END SUB
       
       SUB OwnerDraw(ParentItem AS QMENUITEM, MenuItem AS QMENUITEM, dibu AS LONG, descripcion AS STRING)
          DIM ParentHnd AS LONG, S AS STRING
          ParentHnd = ParentItem.Handle
          WITH mii
            .cbSize = SIZEOF(mii) 
            .fMask = MIIM_TYPE OR MIIM_STATE OR MIIM_ID OR MIIM_DATA
            ' This is a regular text item.
            .fType = MFT_STRING OR MFT_OWNERDRAW
            ' The option is enabled.
            .fState = MFS_ENABLED
            ' It has an ID (this identifies it in the window procedure).
            .wID = MenuItem.Command
            ' The text to place in the menu item.
            S = MenuItem.Caption
            .dwItemData = = VARPTR(S)
            .cch = Len(S)
         END WITH
         WITH QMenu
            .retval = SetMenuItemInfo(ParentHnd, MenuItem.Command, MF_BYCOMMAND, mii)
            .bitmap(MenuItem.Command)= dibu
            .descp(MenuItem.Command)= descripcion
         END WITH
      END SUB
      
      SUB Description (MenuItem AS QMENUITEM, descripcion AS STRING)
            QMenu.descp(MenuItem.Command)= descripcion
      END SUB
             
       constRUCTOR
          imgs.masked = 0
          Descrip = 0
          Panel = 0
       END constRUCTOR
END TYPE  