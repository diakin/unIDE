'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' QLineGraph '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Copyright (c) Jonathan Boles 2002 '''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' PROPERTIES ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Height      AS Integer    - self explanatory                          '
' Width       AS Integer    -                                           '
' Top         AS Integer    -                                           '
' Left        AS Integer    -                                           '
' ExtrapolateToZero AS Boolean - whether the graph should start at 0,0  '
' AxisColour  AS Integer    - Colour for axes                           '
' TextColour  AS Integer    - Colour for text                           '
' BackColour  AS Integer    - Colour for background                     '
' LineColour  AS Integer    - Colour for plotted line                   ' 
' XTitle      AS String     - X axis title                              '
' YTitle      AS String     - Y axis title                              '
' Title       AS String     - Title for graph                           '
' Data        AS QStringGrid - Graph data, stored in form               '
'                           - x=Data.Cell(0,i) y=Data.Cell(1,i) where   '
'                           - i is an integer                           '
' TextFont    AS QFont      - Font for graph text                       '
' Visible     AS Boolean    -                                           '
' Hint        AS String     -                                           '
' ShowHint    AS Boolean    -                                           '
' Cursor      AS Integer    - Cursor for the graph                      ' 
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' METHODS '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' SUB Initialise            - Initialise graphsystem                    '
' SUB SaveToFile            - save graph to .bmp (can't get this 2 work '
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''






Type QLineGraph extends qobject
    Height as integer
    Width as integer
    Top as integer
    Left as integer
    ExtrapolateToZero as integer
    AxisColour as integer
    TextColour as integer
    BackColour as integer
    XTitle as string*50
    YTitle as string*50
    Title as string*100
    XScale as single
    YScale as single
    LineColour as integer
    Data as qstringgrid
    Visible as integer
    Hint as string*100
    TextFont as qfont
    Cursor as integer
    ShowHint as integer

    image as qcanvas
    maxX as single
    maxY as single
    powerX as integer
    powerY as integer
    roundedupX as long
    roundedupY as long
    
    Constructor
        Left=0
        Width=400
        Top=0
        Height=300
        AxisColour=0
        TextColour=0
        LineColour=&HFF
        BackColour=&HFFFFFF
        XTitle="X Axis"
        YTitle="Y Axis"
        Title="X Axis vs. Y Axis"
        ExtrapolateToZero=1
        Visible=1
    End Constructor

    Sub Paint
        with QLineGraph
        .image.visible=.visible
        .image.hint=.hint
        .image.font=.textfont
        .image.cursor=.cursor
        .image.showhint=.showhint
        ''''''''''' set size''''''''''''''''
        .image.height=.Height
        .image.width=.Width
        .image.left=.Left
        .image.top=.Top
        '''''''''' Clear the canvas '''''''''
        .image.fillrect(0,0, .image.width, .image.height, clWhite)
        '''''''''' write title ''''''''''''''
        .image.textout(int(0.5*.image.width)-int(.image.textwidth(rtrim$(.Title))/2),int(0.02*.image.height), rtrim$(.Title),.TextColour,.BackColour)
        '''''''''' write axis titles ''''''''
        .image.textout(int(0.52*.image.width)-int(.image.textwidth(rtrim$(.YTitle))/2),int(0.93*.image.height),rtrim$(.XTitle),.TextColour,.BackColour)
        .image.textout(int(0.02*.image.width),int(0.45*.image.height),rtrim$(.YTitle),.TextColour,.BackColour)
        '''''''''' draw the axes ''''''''''''
        .image.line(int(0.15*.image.width), int(0.85*.image.height), int(0.9*.image.width), int(0.85*.image.height),AxisColour)
        .image.line(int(0.15*.image.width), int(0.1*.image.height), int(0.15*.image.width), int(0.85*.image.height),AxisColour)
        '''''''''' calculate scale ''''''''''
        for i=0 to .Data.RowCount
            if val(.Data.Cell(0,i))>.maxX then .maxX=int(val(.Data.Cell(0,i)))+1
        next
        for i=0 to .Data.RowCount
            if val(.Data.Cell(1,i))>.maxY then .maxY=int(val(.Data.Cell(1,i)))+1
        next

        'if int(log(.maxX)/log(10))+1=1 then
        .powerX=int(log(.maxX)/log(10))+1
        for i=10^(.powerX-1) to 10^.powerX step 10^(.powerX-1)
            if i>.maxX then exit for
        next
        .roundedupX=i
        'end if

        'if int(log(.maxY)/log(10))+1=1 then
        .powerY=int(log(.maxY)/log(10))+1
        for i=10^(.powerY-1) to 10^.powerY step 10^(.powerY-1)
            if i>.maxY then exit for
        next
        .roundedupY=i
        'end if
        
        ''''''''' Draw scale ''''''''''''''
        for i=0 to .roundedupX step 10^(.powerX-1)   ''''''''''' X
            .image.pset(int(0.15*.image.width)+(i/.roundedupX*int(0.74*.image.width)),int(0.85*.image.height)+2,AxisColour)
            .image.pset(int(0.15*.image.width)+(i/.roundedupX*int(0.74*.image.width)),int(0.85*.image.height)+1,AxisColour)
            .image.textout(int(0.15*.image.width)+(i/.roundedupX*int(0.74*.image.width))-.image.textwidth(str$(i))/2,int(0.85*.image.height)+5,str$(i),.TextColour,.BackColour)
        next
        for i=0 to .roundedupY step 10^(.powerY-1)   ''''''''''' Y
            .image.pset(int(0.15*.image.width)-1,int(0.85*.image.height)-(i/.roundedupY*int(0.74*.image.height)),AxisColour)
            .image.pset(int(0.15*.image.width)-2,int(0.85*.image.height)-(i/.roundedupY*int(0.74*.image.height)),AxisColour)
            .image.textout(int(0.15*.image.width)-5-.image.textwidth(str$(i)),int(0.85*.image.height)-(i/.roundedupY*int(0.74*.image.height))-int(.image.textheight(str$(i))/2),str$(i),.TextColour,.BackColour)
        next
        '''''''''' plot points ''''''''''''
        if ExtrapolateToZero then
            .image.line(int(0.15*.image.width),int(0.85*.image.height), _
             int(0.15*.image.width)+(val(.Data.Cell(0,i))/.roundedupX*int(0.74*.image.width)),int(0.85*.image.height)-(val(.Data.Cell(1,i))/.roundedupY*int(0.74*.image.height)),.LineColour)
        end if
        for i=1 to .Data.RowCount-1
            .image.line(int(0.15*.image.width)+(val(.Data.Cell(0,i-1))/.roundedupX*int(0.74*.image.width)),int(0.85*.image.height)-(val(.Data.Cell(1,i-1))/.roundedupY*int(0.74*.image.height)), _
                   int(0.15*.image.width)+(val(.Data.Cell(0,i))/.roundedupX*int(0.74*.image.width)),int(0.85*.image.height)-(val(.Data.Cell(1,i))/.roundedupY*int(0.74*.image.height)),.LineColour)
        next
        end with
    End Sub         

    Sub Initialise
        with QLineGraph
        QLineGraph.image.height=QLineGraph.Height
        QLineGraph.image.width=QLineGraph.Width
        QLineGraph.image.left=QLineGraph.Left
        QLineGraph.image.top=QLineGraph.Top
        QLineGraph.image.onpaint=QLineGraph.Paint
        .image.visible=.visible
        end with
    End Sub
  
    Sub SaveToFile(file as string)
        with QLineGraph
        dim d as QRect, bmp as qbitmap
        bmp.height=.image.height
        bmp.width=.image.width
        d.top=0
        d.left=0
        d.right=.image.width
        d.bottom=.image.height
        .image.copyrect(d, bmp, d)
        bmp.savetofile(file)
        end with
    end sub

End Type  