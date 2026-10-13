$IFNDEF __QCALENDAR_INC   ' IncManager: include guard
$DEFINE __QCALENDAR_INC
'-------------------------------------------------------------------------------------------
'    QCalendar Control by Pasquale P.C.B.        4-2001
'    Dedicated to my beautiful wife Ana 
'-------------------------------------------------------------------------------------------
$include "ApiDate.inc" ' inc2026: было "apidate.bas" — такого файла нет, функции weekday, lastdaym, SYSTEMTIME, GetDateFormat, GetLocaleInfo есть в ApiDate.inc того же автора (inc2026)
TYPE qcalendar EXTENDS Qpanel
    PUBLIC:
    M AS INTEGER
    Y AS INTEGER
    D AS INTEGER
    w1% AS INTEGER '------------------------------------------<<<<<<<<<<<<<<<<<<'
    PopupMenu AS QPopupMenu
    mesi(1 to 12) AS QmenuItem
    Today AS Qcoolbtn    

    Grid AS QSTRINGGRID
    
    Panel1 AS QPANEL
        BTNprev AS QCOOLBTN
        btnnext AS QCOOLBTN
        bntupy AS QcooLBTN
        bntdowny AS QCOOLBTN
    Panel2 AS QPANEL
'-- ************************************************************************************'
    SUB LoadCal(datum$ as string) 
    'print "datum$=" ,datum$

        nowd$=field$(datum$,"-",2) 
        ''print "nowd$=" ,nowd$

        qcalendar.d=val(nowd$)
        nowm$=field$(datum$,"-",1) 
        ''print "nowm$=" ,nowm$
        qcalendar.m=val(nowm$)
        nowy$=field$(datum$,"-",3)
        qcalendar.y=val(nowy$)
        qcalendar.panel1.caption=qcalendar.mesi(val(nowm$)).caption
        qcalendar.panel1.caption=qcalendar.panel1.caption+" "+nowy$
        qcalendar.w1%=weekday(nowm$+"-"+"01"+"-"+nowy$)

        if qcalendar.w1%=1 then qcalendar.w1%=8
        dim v as integer
        
        if qcalendar.m=1 then
            ld%=val(field$(lastdaym("12-1-"+str$(qcalendar.y-1)),"-",2)) 
            ''print "ld=" ,ld
        else
            ld%=val(field$(lastdaym(str$(qcalendar.m-1)+"-1-"+str$(qcalendar.y)),"-",2))
        end if
        v=0
            ''print "ld%=" ,ld%

''print "qcalendar.w1%=" ,qcalendar.w1%

        for i=qcalendar.w1%-2 to 0 step -1
            qcalendar.grid.cell(i,1)=str$(ld%-v)
 
            ''print "qcalendar.grid.cell(i,1)=" ,qcalendar.grid.cell(i,1)
            v++
        next
        
        lb%=val(field$(lastdaym(datum$),"-",2))
        ri=1:co=0
        if qcalendar.w1%=8 then
            ri=2:co=0
        else
            co=qcalendar.w1%-1
        end if
        i=0

        do      
            for c=co to 6
                i++
                qcalendar.grid.cell(c,ri)=str$(i)
                if i=lb% then exit do
            next
            ri++
            co=0
        loop until i=lb%
        
        i=1
        if c=6 then
            ri++:co=0
        else
            co=c+1
        end if
        do

            for c=co to 6
                qcalendar.grid.cell(c,ri)=str$(i)  
                 
                ''print " qcalendar.grid.cell(,", c,",",ri,")=" ,  qcalendar.grid.cell(c,ri)              
             
                i++
            next
        
            co=0:ri++
        loop until ri=8

        ri=int((val(nowd$)+qcalendar.w1%-2)/7)+1 
        co=weekday(nowm$+"-"+nowd$+"-"+nowy$)-1
        qcalendar.grid.row=ri:qcalendar.grid.col=co             
 
        ''print "SUB LoadCal(datum$ as string) " 
    END SUB
'-- ************************************************************************************'
    SUB mnuclick(s as QmenuItem)
      qcalendar.loadcal(str$(s.menuindex+1)+"-"+str$(qcalendar.d)+"-"+str$(qcalendar.y))        
    END SUB 
'-- ************************************************************************************'
    SUB INIT(inidatum$)
        Dim pBuffer As String , ST As SYSTEMTIME
        if inidatum$<>"" then
            st.wYear=val(field$(inidatum$,"-",3))
            st.wmonth=val(field$(inidatum$,"-",1))
            st.wDay =val(field$(inidatum$,"-",2))
            pbuffer="Init"
            pBuffer = String$(255, 0)
            r=GetDateFormat( ByVal 0&, 0, st, "ddd", Varptr(pBuffer), Len(pBuffer))
            pBuffer = Left$(pBuffer, InStr(1, pBuffer, Chr$(0)) - 1)
            if len(pbuffer)=0 then
                 showmessage inidatum$+" it's not valid. Format must be 'MM-DD-YYYYY' ie. '04-23-2001' and the date must be exist"
                 qcalendar.visible=0
                 exit sub
            end if
        end if
        dim b as string
        b=string$(4,0)  
        getlocaleinfo(ByVal 0&, 5  ,varptr(b),len(b))
        dim todayC as string
        select case val(b)
            case 386
                todayC="Danes"
            case 39
                todayC="Oggi"
            case 33
                todayC="Aujourd'hui"
            case 55,52,34
                todayC="Hoy"
            case 49
                todayC="Heute"
            case else
                todayC="Today"
        end select
        for i = 1 to 12
             b=string$(10,0)  
             getlocaleinfo(ByVal 0&, i+55,varptr(b),len(b))
             qcalendar.mesi(i).OnClick=qcalendar.mnuClick
             qcalendar.mesi(i).Caption = b 
             qcalendar.PopupMenu.AddItems qcalendar.mesi(i)
        next
        qcalendar.panel1.popupmenu=qcalendar.popupmenu
        dim week(1 to 7)as string
        for i=1 to 7
            b=string$(3,0)  
            getlocaleinfo(ByVal 0&, i+48  ,varptr(b),len(b))    
            week(i)=b
        next
        for i=1 to 7 ' inc2026: было до grid.colcount+1 (=9 при ColCount=8, строка 378), стало до 7: массив week(1 TO 7) (строка 153), дней в неделе 7, столбцы 0..6
            qcalendar.grid.cell(i-1,0)=week(i)
        next
        ST.wDay = val(field$(date$,"-",2))
        ST.wMonth = val(field$(date$,"-",1))
        ST.wYear = val(field$(date$,"-",3))
        b=string$(15,0)  
        getlocaleinfo(ByVal 0&, &H20,varptr(b),len(b))
        pBuffer = String$(255, 0)
        GetDateFormat( ByVal 0&, 0, ST, b, Varptr(pBuffer), Len(pBuffer))
        pBuffer = Left$(pBuffer, InStr(1, pBuffer, Chr$(0)) - 1)        
        qcalendar.today.caption=todayC+": "+pbuffer
        qcalendar.grid.deloptions 4
        if inidatum$="" then
            qcalendar.loadcal(date$)
        else
            qcalendar.loadcal(inidatum$)
        end if
    END SUB

'-- ************************************************************************************'
    EVENT grid.onselectcell (Col%, Row%, CanSelect%,s as qstringgrid)
       qcalendar.d=val(s.cell(col%,row%))
       if row%=1 then
           if col%<qcalendar.w1%-1 then
               canselect%=0         
               exit sub
           end if
       end if
       if row%>4 then
            if val(s.cell(col%,row%))<22 then
                canselect%=0
                exit sub
            end if
       end if
       Dim pBuffer As String, ST As SYSTEMTIME
       ST.wDay =qcalendar.d
       ST.wMonth = qcalendar.m
       ST.wYear = qcalendar.y
       dim b as string
       b=string$(15,0)  
       getlocaleinfo(ByVal 0&, &H20,varptr(b),len(b))
       pBuffer = String$(255, 0)
       GetDateFormat( ByVal 0&, 0, ST, b, Varptr(pBuffer), Len(pBuffer))
       pBuffer = Left$(pBuffer, InStr(1, pBuffer, Chr$(0)) - 1)        
       qcalendar.panel2.caption=pBuffer
    END EVENT
'-- ************************************************************************************'
    EVENT bntupy.onclick
        qcalendar.y=qcalendar.y+1
        if val(field$(lastdaym(str$(qcalendar.m)+"-01-"+str$(qcalendar.y)),"-",2))<qcalendar.d then 
            qcalendar.loadcal(lastdaym(str$(qcalendar.m)+"-01-"+str$(qcalendar.y)))
        else
            qcalendar.loadcal(str$(qcalendar.m)+"-"+str$(qcalendar.d)+"-"+str$(qcalendar.y))
        end if    
    END EVENT
'-- ************************************************************************************'
    EVENT  btnnext.onclick(s as qcoolbtn)
        if qcalendar.m=12 then
            qcalendar.m=1:qcalendar.y=qcalendar.y+1
        else
            qcalendar.m=qcalendar.m+1
        end if
        if val(field$(lastdaym(str$(qcalendar.m)+"-01-"+str$(qcalendar.y)),"-",2))<qcalendar.d then 
            qcalendar.loadcal(lastdaym(str$(qcalendar.m)+"-01-"+str$(qcalendar.y)))
        else
            qcalendar.loadcal(str$(qcalendar.m)+"-"+str$(qcalendar.d)+"-"+str$(qcalendar.y))
        end if
    END EVENT
'-- ************************************************************************************'
    EVENT bntdowny.onclick
        if qcalendar.y>1753 then
            qcalendar.y=qcalendar.y-1
        else 
            exit sub
        end if    
        if val(field$(lastdaym(str$(qcalendar.m)+"-01-"+str$(qcalendar.y)),"-",2))<qcalendar.d then
            qcalendar.loadcal(lastdaym(str$(qcalendar.m)+"-01-"+str$(qcalendar.y)))
            exit sub
        else
            qcalendar.loadcal(str$(qcalendar.m)+"-"+str$(qcalendar.d)+"-"+str$(qcalendar.y))
        end if        
    END EVENT          
'-- ************************************************************************************'
    EVENT btnprev.onclick(s as qcoolbtn)
        if qcalendar.m=1 then
            if qcalendar.y=1753 then exit sub
            qcalendar.m=12:qcalendar.y=qcalendar.y-1
        else
            qcalendar.m=qcalendar.m-1
        end if
        if val(field$(lastdaym(str$(qcalendar.m)+"-01-"+str$(qcalendar.y)),"-",2))<qcalendar.d then
            qcalendar.loadcal(lastdaym(str$(qcalendar.m)+"-01-"+str$(qcalendar.y)))
            exit sub
        else
            qcalendar.loadcal(str$(qcalendar.m)+"-"+str$(qcalendar.d)+"-"+str$(qcalendar.y))
        end if
    END EVENT
'-- ************************************************************************************'
    EVENT Today.onclick(s as qcoolbtn)
        qcalendar.loadcal(date$)
    END EVENT
'-- ************************************************************************************'
    EVENT grid.onDrawcell (Col% AS LONG, Row% AS LONG, State AS LONG, R AS QRECT, S AS QSTRINGGRID)
        w=((s.colwidths(col%)-s.textwidth(s.cell(col%,row%)))\2)-1
        s.fillrect(r.left,r.top,r.right,r.bottom,-2147483643)  
        if row%=1 then
            if col%<qcalendar.w1%-1 then
                s.textout(r.left+w,r.top+1,s.cell(col%,row%),-2147483631,-1)
                exit sub
            end if
        end if    
        if row%>4 then
            if val(s.cell(col%,row%))<22 then
                s.textout(r.left+w,r.top+1,s.cell(col%,row%),-2147483631,-1)
                exit sub
            end if
        end if   
        if state=1 then
            s.circle(r.left,r.top,r.right,r.bottom,9437183,9437183)
        end if
        if format$("%.2d-%.2d-%d",qcalendar.m,val(s.cell(col%,row%)),qcalendar.y)=date$ then
            s.circle(r.left,r.top,r.right,r.bottom,8716543,-1)
            s.circle(r.left+1,r.top+1,r.right-1,r.bottom-1,8716543,-1)        
        end if
        if col%=6 then 
            s.textout(r.left+w,r.top+1,s.cell(col%,row%),5732096,-1)
        else
            s.textout(r.left+w,r.top+1,s.cell(col%,row%),-2147483640,-1)
        end if
    END EVENT
'-- ************************************************************************************'
    FUNCTION QDate$ as string
       result=str$(qcalendar.m)+"-"+str$(qcalendar.d)+"-"+str$(qcalendar.y)
    END FUNCTION 
'-- ************************************************************************************'
    constRUCTOR
        Caption = "Calendar"
        Width = 179
        Height = 183
        BevelInner = 1
        'BevelOuter = 1
            panel2.parent=qcalendar
            panel2.Left = 0
            panel2.Top = 146
            panel2.Caption = "QCalendar by P.C.B."
            panel2.Width = 173
            panel2.Height = 25
            panel2.BevelInner = 1
            'BevelOuter = 1
            panel2.Align = 1
            panel2.TabOrder = 2    
                bntdowny.parent=qcalendar.panel1
                'BMP = "C:\RapidQ\cdx.bmp"
                bntdowny.caption="6"
                bntdowny.font.name="Webdings"            
                bntdowny.Left = 25
                bntdowny.Top = 1
                bntdowny.Width = 15
                bntdowny.Height = 21
                bntdowny.Flat = 1
                bntdowny.font.color=-2147483639  
                bntdowny.Align = 3
               'BMP = "C:\RapidQ\cdx.bmp"
                bntupy.parent=qcalendar.panel1
                bntupy.caption="5"
                bntupy.font.name="Webdings"            
                bntupy.Left = 100
                bntupy.Top = 1
                bntupy.Width = 15
                bntupy.Height = 13
                bntupy.Flat = 1
                bntupy.font.color=-2147483639  
                bntupy.Align = 4
                btnnext.parent=qcalendar.panel1
                'BMP = "C:\RapidQ\cdx.bmp"
                btnnext.caption="и"
                btnnext.font.name="Wingdings"            
                btnnext.Left = 148
                btnnext.Top = 1
                btnnext.Width = 23
                btnnext.Height = 21
                btnnext.Flat = 1
                btnnext.font.color=-2147483639  
                btnnext.Align = 4
                'btnnext.onclick=btnnextc            
                BTNprev.parent=qcalendar.panel1
                'BMP = "C:\RapidQ\csx.bmp"
                BTNprev.caption="з"
                BTNprev.font.name="Wingdings"
                BTNprev.Left = 2
                BTNprev.Top = 1
                BTNprev.Width = 23
                BTNprev.Height = 21
                BTNprev.Flat = 1
                btnprev.font.color=-2147483639  
                BTNprev.Align = 3
                'BTNprev.onclick=btnprevc
            Panel1.parent=qcalendar
            Panel1.Left = 0
            Panel1.Top = 0
            Panel1.Caption = "Panel1"
            Panel1.Width = 173
            Panel1.Height = 29
            Panel1.bevelinner=1
            Panel1.Align = 1
            Panel1.TabOrder = 1
            Panel1.font.addstyles 0
            Panel1.color=-2147483646
            Panel1.font.color=-2147483639            
            grid.parent=qcalendar
            grid.borderstyle=0
            grid.Left = 0
            grid.Top = 25
            grid.Height = 106
            grid.Width = 173
            grid.Align = 1
            grid.ScrollBars = 0
            grid.GridLineWidth = 0
            grid.ColCount = 8 '-- was 7 - and error occures
            grid.RowCount = 8 '-- was 7 - and error occures
            grid.Col = 0
            grid.DefaultColWidth = 25
            grid.DefaultRowHeight = 15
            grid.FixedCols = 0
            Today.parent=qcalendar
            Today.Caption = "Today"
            Today.Left = 0
            Today.Top = 110
            Today.flat=1
            Today.Width = 173
            Today.Align = 1
            Today.height=18
            Today.font.addstyles=0
    END constRUCTOR    
END TYPE  
$ENDIF   ' IncManager: __QCALENDAR_INC
