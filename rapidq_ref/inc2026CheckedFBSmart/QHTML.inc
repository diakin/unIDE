'************************************************************************
'* Class QHTML Version 1.0  © Pascal Delcombel-2003-2008                *
'************************************************************************
' Class to show (readonly) simplified HTML pages.                       *
' Principle: no API no DLL                                              * 
'       (in order to be switchable to Linux version)                    *
'************************************************************************
' LIMITS                                                                *
' > just a few of the tags supported (ie TABLE not included so far...)  *
' > no frame so far                                                     *
' > maximum of 200 000 elements (because no way to do dynamically redim *
'    arrays from within a QObj)                                         *
'    you may change that number to smaller or greater one (and smaller  *
'    or greater html pages) through constant htmlMaxElements, here below*                                  *
' > no formulaire (button, field, ...)                                  *
' > no download !!                                                      *
' > see OnLoadImage to use external routine in order to load pictures   *
'   like jpeg , GIF and other image files                               *
'************************************************************************
' Events                                                                *
' ******                                                                *
'    OnHover(TypeObject as String, URL as String, x as long, y as long _*
'         , shift as long)                                              *
'      --  TypeObject     HREF or Tag Type                              *
'      --  URL            URL/Filename (if HREF) or hovered text/tag    *
' ******                                                                *
'    OnTagClick(URL as String, x as long, y as long, shift as long)     *
'      --  URL            HREF (URL or FileName)                        *   
' ******                                                                *
'    OnLoadImage(Image as QImage, FileName as String)                   *
'      --  Image          QImage in which loading the FileName image    *   
'      --  FileName       FileName of the image to be loaded            *   
'************************************************************************
' Properties                                                            *
' **********                                                            *
'    HTMLTExt as String       RW    get/set HTMLText                    *
'    DefaultFontName          RW    get/set default font name           *
'    DefaultFontSize          RW    get/set default font size           * 
'    DocumentTitle            R     get html page title                 *
'    PopUpMenu                RW    get/set popupmenu (heritage)        *
'************************************************************************
' Methods                                                               *
' *******                                                               *
'    OpenFile(FileName as String)                                       * 
'      --  FileName (not URL so far)                                    * 
' *******                                                               *
'    Repaint                                                            *
' *******                                                               *
'    PrintPreview                                                       *
' *******                                                               *
'    SearchText(Text as String,Popupwindow as Integer)                  *
'      --  Text           Text to be searched                           *
'      --  Popupwindow    True to open popup window / false otherwise   *
'************************************************************************

'Constants
'=========
Const htmlDefaultHTML as String  = "<HTML><HEAD><TITLE>QWEBBROWSER Copyright</TITLE></HEAD><BODY BGCOLOR='aqua' TEXT=FF0000><center><h3>QHTML v0.1 &copy; 2002<P>Pascal Delcombel</H3></BODY></HTML>" 
Const htmlErrorFrame  as String  = "<HTML><HEAD><TITLE>QWEBBROWSER Error</TITLE></HEAD><BODY BGCOLOR=00FF00 TEXT=FF0000><center><h3>Frame not supported, sorry</H3></BODY></HTML>" 
Const htmlMaxElements as Integer = 200000

   
'************************************************************************
'Control                                                                *
'************************************************************************

'Events
'======
DECLARE SUB htmlOnHover_eventTemplate(TypeObject as String, URL as string)
DECLARE SUB htmlOnTagClick_eventTemplate(URL as string)
DECLARE SUB htmlOnLoadImage_eventTemplate(Image as QImage, FileName as String)

TYPE QHTML EXTENDS QPanel
    Private:
        Image                           as Qimage 
        Bar                             as QScrollbar 
        HoverText                       as QStatusBar
        HoveredTag                      as string
        HoveredObject                   as string
        FrameName                       as String
        FrameSource                     as String
        FrameURL                        as String
        FrameBGColor                    as long
        FrameBackGroundBmp              as String 
        FrameTextColor                  as long  
        FrameLinkColor                  as long
        FrameFoundTextColor             as long
        ExternalPicture                 as QImage

        PaintTimer                      as QTimer
        BarResize                       as Integer
        PrintMode                       as Integer
        ModePRE                         as Integer  
        FirstVisible                    as integer
        LastVisible                     as integer

        ZoomForm                        as QForm
        ZoomImage                       as QImage
        Zoom                            as QBitMap
        ZoomPage                        as integer
        ZoomPages                       as integer
        ZoomPF                          as QButton
        ZoomPP                          as QButton
        ZoomPN                          as QButton
        ZoomPL                          as QButton
        ZoomPrint                       as QButton
        ZoomPrintAll                    as QButton
        ZoomSAVE                        as QButton
        ZoomWithBG                      as QCheckBox
        ZoomPrinters                    as QComboBox 
        ZoomTimer                       as QTimer

        
        SearchForm                      as QForm
        SearchQEDL                      as QLabel
        SearchQED                       as QEdit
        SearchQEDN                      as QButton
        SearchQEDA                      as QButton
        SearchIndex1                    as Integer
        SearchIndex2                    as Integer
        
        HTMLColorsName(200)             as String
        HTMLColorsCode(200)             as String
        HTMLColors                      as Integer

    'Elements used for parsing
    '=========================
        'Attributes analysis
        AttributeNumber                 as integer        ' Attributes analysis
        AttributesName(50)              as string         ' name
        AttributesValue(50)             as string         ' value

    'Elements description (hierarchy)
    '====================
        Elements                                 as Integer 
        'Common fields
        ElementsLevel(htmlMaxElements)           as Integer
        ElementsText(htmlMaxElements)            as String         ' string  
        ElementsWidth(htmlMaxElements)           as Integer        ' Element width
        ElementsHeight(htmlMaxElements)          as Integer        ' Element height
        ElementsTop(htmlMaxElements)             as Integer        ' Element top
        ElementsType(htmlMaxElements)            as String         ' If MarkUP, type (else, blank)
        ElementsBorderWidth(htmlMaxElements)     as integer        ' border width (table, Image)
        ElementsName(htmlMaxElements)            as String         ' Name
        ElementsHighlightFrom(htmlMaxElements)   as Integer        ' for search
        ElementsHighlightTo(htmlMaxElements)     as Integer        ' for search
                
        'Anchors
        ElementsAnchorsHRef(htmlMaxElements)     as string         ' HyperLink reference
        ElementsAnchorsID(htmlMaxElements)       as string         ' ID/name
        ElementsAnchorsTitle(htmlMaxElements)    as string         ' Title
        ElementsAnchorsPosition(htmlMaxElements) as string         ' x1,y1,x2,y2,x3,y3,... 'depending on Shape)
        ElementsAnchorsShape(htmlMaxElements)    as String         ' Shape for reactive Map (default: rectangle)
        
        'Table
        ElementsTableWidth(htmlMaxElements)      as integer        ' table width
        ElementsCellWidth(htmlMaxElements)       as integer        ' cell width
        ElementsCellpadding(htmlMaxElements)     as integer        ' cell padding
        
        ElementsCellSpacing(htmlMaxElements)     as integer        ' cell spacing
        ElementsColSpan(htmlMaxElements)         as integer        ' column span
        ElementsCenter(htmlMaxElements)          as Integer        ' center aligned
        ElementsRight(htmlMaxElements)           as Integer        ' right aligned
        
        'Images 
        ElementsImgSource(htmlMaxElements)       as String         ' source
        ElementsImgAlt(htmlMaxElements)          as String         ' alt text (if impossible to show image)
        ElementsImgWidth(htmlMaxElements)        as Long           ' Width
        ElementsImgHeight(htmlMaxElements)       as Long           ' Height
        ElementsImgHSpace(htmlMaxElements)       as Long           ' Horizontal space
        ElementsImgVSpace(htmlMaxElements)       as Long           ' Vertical space
        ElementsImgUseMap(htmlMaxElements)       as Long           ' Map for reactive areas
        
        'Fonts 
        ElementsFontName(htmlMaxElements)        as String         ' Font Name
        ElementsFontSize(htmlMaxElements)        as Integer        ' Font Size
        ElementsFontColor(htmlMaxElements)       as Long           ' Font Color
        ElementsFontB(htmlMaxElements)           as Integer        ' Font Bold
        ElementsFontI(htmlMaxElements)           as Integer        ' Font Italic
        ElementsFontU(htmlMaxElements)           as Integer        ' Font Underline
        ElementsFontS(htmlMaxElements)           as Integer        ' Font Strike
           
    'Elements used for painting
    '==========================
        ElementsOnLine(1000)                     as integer        ' Elements on same line
        OnLine                                   as Integer        ' Elements number
        
    
Public:
        HTMLText                       as STRING PROPERTY SET SetHTMLText
        DocumentTitle                  as String  Property set Set_DocumentTitle
        DefaultFontName                as String  Property set Set_DefaultFontName
        DefaultFontSize                as Integer Property set Set_DefaultFontSize
        OnHover                        as EVENT(htmlOnHover_eventTemplate)
        OnTagClick                     as EVENT(htmlOnTagClick_eventTemplate)
        OnLoadImage                    as EVENT(htmlOnLoadImage_eventTemplate)


Private:
    
        'Check if given file exists and loadable through event OnPLoadImage
        Function IsDrawable(FileName as string) as Integer
            this.IsDrawable = false
            this.externalPicture.width = 0
            if this.OnLoadImage > 0 then CALLFUNC(this.OnLoadImage,this.externalPicture, FileName)
            if this.externalPicture.width > 0 then this.IsDrawable = true

        end function  
        
        
        'Extract attributes from a Markup
        Sub ExtractAttributes(HTMLTExt as string)
            Dim tBegin as integer, tEnd as integer,tLength as integer
            dim tValue as string, tDeLimiter as string

            this.AttributeNumber = 0
            tLength = len(HTMLText)
            HTMLText = ltrim$(rtrim$(mid$(HTMLText,2,tLength-2)))
            tLength = len(HTMLText)
            tBegin = instr(2,HTMLText," ")
            if tBegin<=0 then tBegin = tLength 
            while tBegin < tLength 
                tEnd = instr(tBegin,HTMLText,"=")
                if tEnd > 0 then
                    this.AttributeNumber++          
                    'Here is the name
                    this.AttributesName(this.AttributeNumber)  = ucase$(ltrim$(rtrim$(mid$(HTMLTExt,tBegin,tEnd-TBegin))))
 
                    'Now the value
                    tBegin = tEnd+1
                    while mid$(HTMLText,tBegin,1) = " "
                        tBegin--
                    wend
                    tDelimiter = " "
                    select case mid$(HTMLText,tBegin,1)
                        case "'" 
                            TDelimiter = "'" 
                            TBegin++
                        case chr$(34)
                            TDelimiter = chr$(34) 
                            TBegin++
                    end select
                    tEnd = instr(tBegin,HTMLText,tDelimiter)
                    if tEnd =0 then tEnd = tLength+1
                    this.AttributesValue(this.AttributeNumber) = mid$(HTMLText,tBegin,tEnd-TBegin)
                    tBegin = tEnd+1
                else
                    tEnd = tLength    
                end if        
 
                'prepare next loop
                tBegin = tEnd+1
                tEnd = instr(tBegin,HTMLText,"=")
            wend
        end sub
        
        'Extract word from a string
        function ExtractWord(Text as string, Number as integer, Separator as string) as string
            dim i1 as Integer, i2 as integer, j as integer, KO as integer
            
            KO = false
            if len(Text) <= 0                     then KO = true
            if len(separator) <= 0                then KO = true
            if Number = 0                         then KO = true
            if Number > tally(Text,Separator) + 1 then KO = true
            
            if KO = true then
                this.ExtractWord = chr$(1) 'end
            else
                i1 = 0
                i2 = 0
                j =  Number 
                while j > 0
                    i1 = i2+1
                    i2 = instr(i1,Text+Separator,Separator)
                    if i2 = 0 then j = 0
                    j--
                wend

                if i2 = 0 then
                    this.ExtractWord = chr$(1) '""
                else
                    this.ExtractWord = mid$(Text,i1,i2-i1)
                end if
            end if
        end function 
        
        'Transform Hexa to Long
        function HexaToLong(Hexa as string) as long
            dim i as Integer
            Dim j as long
            Dim HEx as string
            
            Hex = replacesubstr$(replacesubstr$(replacesubstr$(replacesubstr$(replacesubstr$(replacesubstr$(Hexa,"A",":"),"B",";"),"C","<"),"D","="),"E",">"),"F","?")
            j = 0            
            for i = 1 to len(hex) 
                j = 16 * j + (asc(mid$(Hex,i,1)) - asc("0"))
            next
            this.HexaToLong = j
        end function
        
        'Extract Color value from Hexa code: should be HExas but some controls in case of...

        function ColorValue(AttributeTExt as string) as long
            dim hCol as string
            
            hCol = ucase$(replacesubstr$(AttributeTExt,"#",""))
            if len(hCol) = 6 and _
               this.HexaToLong(left$(hCol,2))  >= 0  and this.HexaToLong(left$(hCol,2)) <= 255 _ 
               this.HexaToLong(mid$(hCol,3,2)) >= 0 and this.HexaToLong(mid$(hCol,3,2)) <= 255 _ 
               this.HexaToLong(right$(hCol,2)) >= 0 and this.HexaToLong(right$(hCol,2)) <= 255 then
                this.ColorValue = rgb(this.HexaToLong(left$(hCol,2)),this.HexaToLong(mid$(hCol,3,2)),this.HexaToLong(right$(hCol,2)))
            else
                showmessage(AttributeTExt)
                this.ColorValue = 0 'black
            end if
        end function
        
        'Extract HTML Color value from textual or assume Hexa if not in list
        'We may have to complete this list at bottom of the source...
        function HTMLColorValue(ColorText as string) as long
            dim i as integer
            for i = 1 to this.HTMLColors
                if ucase$(this.HTMLColorsName(i)) = ucase$(ColorText) then
                    this.HTMLColorValue = this.ColorValue(this.HTMLColorsCode(i))
                    exit for
                end if
            next
            if i > this.HTMLColors then this.HTMLColorValue = this.ColorValue(ColorText)
        end function
        
        ' Just delete redundant or unexepected or special character informations
        Function HTMLTExtCleaning(HTMLTExt as string, KeepRC as Integer) as string
            dim i as integer
            Dim WorkString as String
            
            WorkString = HTMLText
            for i = 1 to 31
                if KeepRC = false or i <> 13 then
                    WorkString = replacesubstr$(WorkString,chr$(i)," ")
                end if    
            next
            WorkString = replacesubstr$(WorkString,"&nbsp;"   ," ")
            WorkString = replacesubstr$(WorkString,"&emsp;"   ," ")
            WorkString = replacesubstr$(WorkString,"&ensp;"   ," ")
            WorkString = replacesubstr$(WorkString,"&iexcl;"  ,"¡")
            WorkString = replacesubstr$(WorkString,"&quot;"   ,"""") ' Quote "
            WorkString = replacesubstr$(WorkString,"&cent;"   ,"¢")
            WorkString = replacesubstr$(WorkString,"&pound;"  ,"£")
            WorkString = replacesubstr$(WorkString,"&amp;"    ,"&")
            WorkString = replacesubstr$(WorkString,"&lt;"     ,"<")
            WorkString = replacesubstr$(WorkString,"&gt;"     ,">")
            WorkString = replacesubstr$(WorkString,"&euro;"   ,"€")
            WorkString = replacesubstr$(WorkString,"&copy;"   ,"©")
            WorkString = replacesubstr$(WorkString,"&reg;"    ,"®")
            WorkString = replacesubstr$(WorkString,"&deg;"    ,"°")
            WorkString = replacesubstr$(WorkString,"&middot;" ,"·")
            WorkString = replacesubstr$(WorkString,"&curren;" ,"¤")
            WorkString = replacesubstr$(WorkString,"&yen;" ,"¥")
            WorkString = replacesubstr$(WorkString,"&brvbar;" ,"¦")
            WorkString = replacesubstr$(WorkString,"&sect;" ,"§")
            WorkString = replacesubstr$(WorkString,"&uml;" ,"¨")
            WorkString = replacesubstr$(WorkString,"&ordf;" ,"ª")
            WorkString = replacesubstr$(WorkString,"&laquo;" ,"«")
            WorkString = replacesubstr$(WorkString,"&not;" ,"¬")
            WorkString = replacesubstr$(WorkString,"&shy;" ,"-")
            WorkString = replacesubstr$(WorkString,"&reg;" ,"®")
            WorkString = replacesubstr$(WorkString,"&macr;" ,"¯")
            WorkString = replacesubstr$(WorkString,"&deg;" ,"°")
            WorkString = replacesubstr$(WorkString,"&plusmn;" ,"±")
            WorkString = replacesubstr$(WorkString,"&sup2;" ,"²")
            WorkString = replacesubstr$(WorkString,"&sup3;" ,"³")
            WorkString = replacesubstr$(WorkString,"&acute;" ,"´")
            WorkString = replacesubstr$(WorkString,"&micro;" ,"µ")
            WorkString = replacesubstr$(WorkString,"&para;" ,"¶")
            WorkString = replacesubstr$(WorkString,"&middot;" ,"·")
            WorkString = replacesubstr$(WorkString,"&cedil;" ,"¸")
            WorkString = replacesubstr$(WorkString,"&supl;" ,"¹")
            WorkString = replacesubstr$(WorkString,"&ordm;" ,"º")
            WorkString = replacesubstr$(WorkString,"&raquo;" ,"»")
            WorkString = replacesubstr$(WorkString,"&frac14;" ,"¼")
            WorkString = replacesubstr$(WorkString,"&frac12;" ,"½")
            WorkString = replacesubstr$(WorkString,"&frac34;" ,"¾")
            WorkString = replacesubstr$(WorkString,"&iquest;" ,"¿")
            WorkString = replacesubstr$(WorkString,"&Agrave;" ,"À")
            WorkString = replacesubstr$(WorkString,"&Aacute;" ,"Á")
            WorkString = replacesubstr$(WorkString,"&Acirc;" ,"Â")
            WorkString = replacesubstr$(WorkString,"&Atilde;" ,"Ã")
            WorkString = replacesubstr$(WorkString,"&Auml;" ,"Ä")
            WorkString = replacesubstr$(WorkString,"&Aring;" ,"Å")
            WorkString = replacesubstr$(WorkString,"&AElig;" ,"Æ")
            WorkString = replacesubstr$(WorkString,"&Ccedil;" ,"Ç")
            WorkString = replacesubstr$(WorkString,"&Egrave;" ,"È")
            WorkString = replacesubstr$(WorkString,"&Eacute;" ,"É")
            WorkString = replacesubstr$(WorkString,"&Ecirc;" ,"Ê")
            WorkString = replacesubstr$(WorkString,"&Euml;" ,"Ë")
            WorkString = replacesubstr$(WorkString,"&Igrave;" ,"Ì")
            WorkString = replacesubstr$(WorkString,"&Iacute;" ,"Í")
            WorkString = replacesubstr$(WorkString,"&Icirc;" ,"Î")
            WorkString = replacesubstr$(WorkString,"&Iuml;" ,"Ï")
            WorkString = replacesubstr$(WorkString,"&ETH;" ,"Ð")
            WorkString = replacesubstr$(WorkString,"&Ntilde;" ,"Ñ")
            WorkString = replacesubstr$(WorkString,"&Ograve;" ,"Ò")
            WorkString = replacesubstr$(WorkString,"&Oacute;" ,"Ó")
            WorkString = replacesubstr$(WorkString,"&Ocirc;" ,"Ô")
            WorkString = replacesubstr$(WorkString,"&Otilde;" ,"Õ")
            WorkString = replacesubstr$(WorkString,"&Ouml;" ,"Ö")
            WorkString = replacesubstr$(WorkString,"&times;" ,"×")
            WorkString = replacesubstr$(WorkString,"&Oslash;" ,"Ø")
            WorkString = replacesubstr$(WorkString,"&Ugrave;" ,"Ù")
            WorkString = replacesubstr$(WorkString,"&Uacute;" ,"Ú")
            WorkString = replacesubstr$(WorkString,"&Ucirc;" ,"Û")
            WorkString = replacesubstr$(WorkString,"&Uuml;" ,"Ü")
            WorkString = replacesubstr$(WorkString,"&Yacute;" ,"Ý")
            WorkString = replacesubstr$(WorkString,"&THORN;" ,"Þ")
            WorkString = replacesubstr$(WorkString,"&szlig;" ,"ß")
            WorkString = replacesubstr$(WorkString,"&agrave;" ,"à")
            WorkString = replacesubstr$(WorkString,"&aacute;" ,"á")
            WorkString = replacesubstr$(WorkString,"&acirc;" ,"â")
            WorkString = replacesubstr$(WorkString,"&atilde;" ,"ã")
            WorkString = replacesubstr$(WorkString,"&auml;" ,"ä")
            WorkString = replacesubstr$(WorkString,"&aring;" ,"å")
            WorkString = replacesubstr$(WorkString,"&aelig;" ,"æ")
            WorkString = replacesubstr$(WorkString,"&ccedil;" ,"ç")
            WorkString = replacesubstr$(WorkString,"&egrave;" ,"è")
            WorkString = replacesubstr$(WorkString,"&eacute;" ,"é")
            WorkString = replacesubstr$(WorkString,"&ecirc;" ,"ê")
            WorkString = replacesubstr$(WorkString,"&euml;" ,"ë")
            WorkString = replacesubstr$(WorkString,"&igrave;" ,"ì")
            WorkString = replacesubstr$(WorkString,"&iacute;" ,"í")
            WorkString = replacesubstr$(WorkString,"&icirc;" ,"î")
            WorkString = replacesubstr$(WorkString,"&iuml;" ,"ï")
            WorkString = replacesubstr$(WorkString,"&eth;" ,"ð")
            WorkString = replacesubstr$(WorkString,"&ntilde;" ,"ñ")
            WorkString = replacesubstr$(WorkString,"&ograve;" ,"ò")
            WorkString = replacesubstr$(WorkString,"&oacute;" ,"ó")
            WorkString = replacesubstr$(WorkString,"&ocirc;" ,"ô")
            WorkString = replacesubstr$(WorkString,"&otilde;" ,"õ")
            WorkString = replacesubstr$(WorkString,"&ouml;" ,"ö")
            WorkString = replacesubstr$(WorkString,"&ugrave;" ,"ù")
            WorkString = replacesubstr$(WorkString,"&uacute;" ,"ú")
            WorkString = replacesubstr$(WorkString,"&ucirc;" ,"û")
            WorkString = replacesubstr$(WorkString,"&uuml;" ,"ü")
            WorkString = replacesubstr$(WorkString,"&yacute;" ,"ý")
            WorkString = replacesubstr$(WorkString,"&thorn;" ,"þ")
            WorkString = replacesubstr$(WorkString,"&yuml;" ,"ÿ")
            WorkString = replacesubstr$(WorkString,"&#8364;" ,"€")
            WorkString = replacesubstr$(WorkString,"&#128;" ,"€")
            if KeepRC = false then
                while instr(1,Workstring, "  ") > 0
                    WorkString = replacesubstr$(WorkString,"  " ," ") ' single blanks
                wend    
            end if
            this.HTMLTExtCleaning = WorkString
        end function
        
        'Find complete path, if necessary
        function AdjustCompletePath(byval New as string, byval Old as string) as string
            dim i as integer
            
            if instr(New,":") > 0 then
                this.AdjustCompletePath = New
            else
                'we are treating just simple case: relative path
                Old = replacesubstr$(old,"\","/")
                i = 1
                while Instr(i,Old,"/")
                    i = Instr(i,Old,"/")+1
                wend
                this.AdjustCompletePath =left$(Old,i-2)+"/"+New
            end if    
        end function
        
        'new element
        function AddElement(t as integer) as integer
            t = t+1
            this.ElementsLevel(t)           = this.ElementsLevel(t-1) + 1
            this.ElementsText(t)            = ""
            this.ElementsType(t)            = ""
            this.ElementsName(t)            = ""
            this.ElementsImgSource(t)       = ""
            this.ElementsHighlightFrom(t)   = 0
            this.ElementsHighlightTo(t)     = 0
            this.ElementsFontName(t)        = this.ElementsFontName(t-1)
            this.ElementsFontSize(t)        = this.ElementsFontSize(t-1)
            this.ElementsFontColor(t)       = this.ElementsFontColor(t-1)
            this.ElementsFontB(t)           = this.ElementsFontB(t-1)
            this.ElementsFontI(t)           = this.ElementsFontI(t-1)
            this.ElementsFontU(t)           = this.ElementsFontU(t-1)
            this.ElementsFontS(t)           = this.ElementsFontS(t-1)
            this.ElementsAnchorsPosition(t) = ""
            this.ElementsAnchorsShape(t)    = this.ElementsAnchorsShape(t-1)
            this.ElementsAnchorsHref(t)     = this.ElementsAnchorsHref(t-1)
            this.ElementsAnchorsID(t)       = this.ElementsAnchorsID(t-1)
            this.ElementsAnchorsTitle(t)    = this.ElementsAnchorsTitle(t-1)
            this.AddElement = t
        end function

        'Parse HTMLTExt in our control
        Sub ParseText(NewDocument as String)
            dim i as integer, tStart as Long, tLength as long
            dim tEnd as long, tBegin as long
            dim OldWords as string, Words as String, tMarkup as string
            dim tElement as integer, NewtElement as integer ,tAnchor as integer, tAttribute as integer
            dim tLeft as integer, tTop as integer, MinWidth as integer, LineHeight as integer
            dim MaxWidth as integer, tWidth as integer
            dim MyFont as QFont
            Dim SubWordTreated as integer, WordTreated as integer
            Dim SubWord as string, Word as String
            Dim ParseWord as Integer
        
            this.cursor           = crHourGlass 
            this.image.cursor     = crHourGlass 
            this.bar.cursor       = crHourGlass 
            this.HoverText.cursor = crHourGlass 
            doevents
            
            'Take care first about frames
            this.FrameSource = NewDocument
            tStart = instr(1,ucase$(NewDocument),"<FRAMESET")
            if tStart > 0 then 
                this.FrameSource = htmlErrorFrame
                NewDocument   = htmlErrorFrame

            end if    
            this.FrameBGColor               = this.HTMLColorValue("WHITE")
            this.FrameBackGroundBmp         = ""
            this.FrameTextColor             = this.HTMLColorValue("BLACK")
            this.FrameLinkColor             = this.HTMLColorValue("BLUE")
            this.FrameFoundTExtColor        = this.HTMLColorValue("AQUA")

            this.SearchIndex1               = 0
            this.SearchIndex2               = 0
            this.ElementsLevel(1)           = 0
            this.ElementsText(1)            = ""
            this.ElementsType(1)            = "NOTHINNOTHINNOTHIN"
            this.ElementsName(1)            = ""
            this.ElementsImgSource(1)       = ""
            this.ElementsFontName(1)        = this.DefaultFontName      
            this.ElementsFontSize(1)        = this.DefaultFontSize
            this.ElementsFontColor(1)       = this.FrameTextColor
            this.ElementsFontB(1)           = false
            this.ElementsFontI(1)           = false
            this.ElementsFontU(1)           = false
            this.ElementsFontS(1)           = false
            this.ElementsAnchorsPosition(1) = ""
            this.ElementsAnchorsShape(1)    = ""
            this.ElementsAnchorsHref(1)     = ""
            this.ElementsAnchorsID(1)       = ""
            this.ElementsAnchorsTitle(1)    = ""
            tElement = 1
            'Let's go to parse html code
            tStart   = 1
            tLength  = len(NewDocument)
            tLeft    = 0
            tTop     = 0
            MaxWidth = this.image.Width - 5
            this.ModePRE = false
            ParseWord = true
            
            while tStart <= tLength
                tBegin = instr(tStart,NewDocument,"<")
                        
                'Special case: comments (we don't care)
                while tBegin = tStart and mid$(NewDocument,tBegin,2) = "<!"
                    tStart = instr(tBegin,NewDocument,">") + 1
                    tBegin = instr(tStart,NewDocument,"<")
                wend 
                        
                'Select the element
                if tBegin > tStart then
                    tEnd   = tBegin-1
                    tBegin = tStart
                    tStart = tEnd+1
                else
                    if tBegin <=0 then
                        tEnd   = tLength+1
                        tStart = tEnd
                    else    
                        'a Markup!
                        tEnd = instr(tBegin,NewDocument,">")
                        if tEnd <= 0 then tEnd  = tLength+1
                        tStart = tEnd+1
                    end if
                end if
                    
                'Analyse the element, now, if correct
                if tEnd <= tLength then 
                    'OldWords = Words
                    if this.ModePRE = true  then 
                        Words = this.htmltextcleaning(mid$(NewDocument,tBegin,tEnd-tBegin+1),true)
                    else
                        Words = this.htmltextcleaning(mid$(NewDocument,tBegin,tEnd-tBegin+1),false)
                    end if
                    tMarkUp  = ""
                    if left$(words,1) = "<" then 
                        tMarkup = ucase$(ltrim$(rtrim$(words)))
                        i       = instr(2,tMarkup," ")
                        if i <= 0 then i = len(tMarkup)
                        tMarkup = mid$(tMarkup,2,i-2)
                    end if
                                                       
                    tElement = this.AddElement(tElement)
                    this.ElementsText(tElement) = words
                    this.ElementsType(tElement) = tMarkup  

                    'It is a Markup
                    if len(tMarkup) > 0 then
                        select case tMarkUp
                            case "A"
                                this.ExtractAttributes((this.ElementsText(tElement)))
                                tAttribute = 1
                                while tAttribute <= this.AttributeNumber
                                    select case this.AttributesName(tAttribute)
                                        case "HREF"
                                            this.ElementsAnchorsHref(tElement) = this.AttributesValue(tAttribute)
                                        case "ID","NAME"
                                            this.ElementsAnchorsID(tElement)   = this.AttributesValue(tAttribute)
                                        case "TITLE"
                                            this.ElementsAnchorsTitle(tElement) = this.AttributesValue(tAttribute)
                                        case else
                                    end select        
                                    tAttribute++
                                wend
                                if this.ElementsAnchorsHref(tElement) <> "" then
                                    this.ElementsFontName(tElement)   = this.DefaultFontName
                                    this.ElementsFontSize(tElement)   = this.DefaultFontSize
                                    this.ElementsFontColor(tElement)  = this.FrameLinkColor
                                    this.ElementsFontB(tElement)      = false
                                    this.ElementsFontI(tElement)      = false
                                    this.ElementsFontS(tElement)      = false
                                    this.ElementsFontU(tElement)      = true
                                end if
                                this.ElementsAnchorsShape(tElement)    = "RECT"
                            case "ADDRESS"
                                this.ElementsFontI(tElement)     = true
                            case "AREA"
                                tAnchor = tAnchor + 1
                                this.ExtractAttributes((this.ElementsText(tElement)))
                                tAttribute = 1
                                while tAttribute <= this.AttributeNumber
                                    select case this.AttributesName(tAttribute)
                                        case "SHAPE"
                                            this.ElementsAnchorsShape(tAnchor)    = this.AttributesValue(tAttribute)
                                        case "COORD"
                                            this.ElementsAnchorsPosition(tAnchor) = this.AttributesValue(tAttribute)
                                        case "HREF"
                                            this.ElementsAnchorsHref(tAnchor)     = this.AttributesValue(tAttribute)
                                        case else
                                    end select        
                                    tAttribute++
                                wend
                            case "B"
                                this.ElementsFontB(tElement)     = true
                            case "BIG"
                                this.ElementsFontSize(tElement)  = int( this.ElementsFontSize(tElement-1) * 1.2 )
                                this.ElementsFontB(tElement)     = true
                            case "BR"
                            case "BLOCKQUOTE"
                            case "BODY"
                                this.ExtractAttributes((this.ElementsText(tElement)))
                                tAttribute = 1
                                while tAttribute <= this.AttributeNumber
                                    select case this.AttributesName(tAttribute)
                                        case "BGCOLOR"
                                            this.FrameBGColor       = this.HTMLColorValue(this.AttributesValue(tAttribute))
                                        case "TEXT"    
                                            this.FrameTextColor     = this.HTMLColorValue(this.AttributesValue(tAttribute))

                                            this.ElementsFontColor(tElement)= this.FrameTextColor
                                        case "LINK"
                                            this.FrameLinkColor     = this.HTMLColorValue(this.AttributesValue(tAttribute))
                                        case "BACKGROUND"
                                            this.FrameBackGroundBmp = this.AttributesValue(tAttribute)
                                        case else
                                    end select        
                                    tAttribute++
                                wend
                            case "BR"
                            case "CAPTION"
                            case "CENTER"
                            case "DT"
                            case "EM"
                                this.ElementsFontB(tElement)     = true
                            case "FONT"
                                this.ExtractAttributes((this.ElementsText(tElement)))
                                tAttribute = 1
                                while tAttribute <= this.AttributeNumber
                                    select case this.AttributesName(tAttribute)
                                        case "FACE"
                                            if instr(this.AttributesValue(tAttribute),",") > 1 then
                                                this.ElementsFontName(tElement) = left$(this.AttributesValue(tAttribute),instr(this.AttributesValue(tAttribute),",") - 1)
                                            else
                                                this.ElementsFontName(tElement) = this.AttributesValue(tAttribute)
                                            end if    
                                        case "COLOR"

                                            this.ElementsFontColor(tElement) = this.HTMLColorValue(this.AttributesValue(tAttribute))
                                    end select        
                                    tAttribute++
                                wend
                            case "HEAD"
                            case "H1"
                                this.ElementsFontSize(tElement)  = int(this.ElementsFontSize(1) * 1.8)
                                this.ElementsFontB(tElement)     = true
                                this.ElementsFontI(tElement)     = false
                                this.ElementsFontU(tElement)     = false
                            case "H2"
                                this.ElementsFontSize(tElement)  = this.ElementsFontSize(1) * 1.5
                                this.ElementsFontI(tElement)     = false
                                this.ElementsFontU(tElement)     = false
                                this.ElementsFontB(tElement)     = true
                            case "H3"
                                this.ElementsFontSize(tElement)  = this.ElementsFontSize(1) * 1.2
                                this.ElementsFontB(tElement)     = true
                                this.ElementsFontI(tElement)     = false
                                this.ElementsFontU(tElement)     = false
                            case "H4"
                                this.ElementsFontSize(tElement)  = this.ElementsFontSize(1)
                                this.ElementsFontB(tElement)     = true
                                this.ElementsFontI(tElement)     = false
                                this.ElementsFontU(tElement)     = false
                            case "H5"
                                this.ElementsFontSize(tElement)  = this.ElementsFontSize(1)
                                this.ElementsFontB(tElement)     = false
                                this.ElementsFontI(tElement)     = true
                                this.ElementsFontU(tElement)     = false
                            case "H6" 
                                this.ElementsFontSize(tElement)  = this.ElementsFontSize(1)
                                this.ElementsFontB(tElement)     = false
                                this.ElementsFontI(tElement)     = false
                                this.ElementsFontU(tElement)     = false
                            case "I"
                                this.ElementsFontI(tElement)     = true
                            case "IMG"
                                this.ElementsType(tElement)      = "IMG"
                                this.ElementsImgHSpace(tElement) = 1
                                this.ElementsImgVSpace(tElement) = 1
                                this.ExtractAttributes((this.ElementsText(tElement)))
                                tAttribute = 1
                                while tAttribute <= this.AttributeNumber
                                    select case this.AttributesName(tAttribute)
                                        case "SRC"
                                            this.ElementsImgSource(tElement)   = this.AttributesValue(tAttribute)
                                        case "ALT"
                                            this.ElementsImgAlt(tElement)      = this.AttributesValue(tAttribute)
                                        case "WIDTH"
                                            this.ElementsImgWidth(tElement)    = Val(this.AttributesValue(tAttribute))
                                        case "HEIGHT"
                                            this.ElementsImgHeight(tElement)   = Val(this.AttributesValue(tAttribute))
                                        case "HSPACE"
                                            this.ElementsImgHSpace(tElement)   = Val(this.AttributesValue(tAttribute))
                                        case "VSPACE"
                                            this.ElementsImgVSpace(tElement)   = Val(this.AttributesValue(tAttribute))
                                        case "BORDER"
                                            this.ElementsBorderWidth(tElement) = Val(this.AttributesValue(tAttribute))
                                        case "USEMAP"
                                            this.ElementsImgUseMap(tElement)   = this.AttributesValue(tAttribute)
                                        case else
                                    end select        
                                    tAttribute++
                                wend
                            case "MAP"
                                this.ElementsType(tElement) = "MAP"
                                this.ExtractAttributes((this.ElementsText(tElement)))
                                tAttribute = 1
                                while tAttribute <= this.AttributeNumber
                                    select case this.AttributesName(tAttribute)
                                        case "NAME"
                                             this.ElementsName(tElement) = this.AttributesValue(tAttribute)
                                        case else
                                    end select        
                                    tAttribute++
                                wend
                            case "P"
                                this.ElementsType(tElement) = "P"
                                this.ExtractAttributes((this.ElementsText(tElement)))
                                tAttribute = 1
                                while tAttribute <= this.AttributeNumber
                                    select case this.AttributesName(tAttribute)
                                        case "ALIGN"
                                             this.ElementsName(tElement) = this.AttributesValue(tAttribute)
                                        case else
                                    end select        
                                    tAttribute++
                                wend
                            case "PRE","KBD"
                                this.ElementsFontName(tElement)   = "Courier New"
                                this.ElementsFontSize(tElement)   = this.DefaultFontSize
                                this.ElementsFontB(tElement)      = false
                                this.ElementsFontI(tElement)      = false
                                this.ElementsFontS(tElement)      = false
                                this.ElementsFontU(tElement)      = false
                                this.ModePRE                      = true
                            case "SMALL"
                                this.ElementsFontSize(tElement)  = int ( this.ElementsFontSize(1) * 0.8)
                            case "S","STRIKE"
                                this.ElementsFontS(tElement)     = true
                            case "STRONG"
                                this.ElementsFontSize(tElement)  = int ( this.ElementsFontSize(1) * 1.1 )
                                this.ElementsFontB(tElement)     = true
                            case "TABLE"
                                this.ElementsCellpadding(tElement) = 1
                                this.ElementsCellSpacing(tElement) = 2
                                this.ElementsTableWidth(tElement)  = 1'MaxWidth
                                this.ExtractAttributes((this.ElementsText(tElement)))
                                tAttribute = 1
                                while tAttribute <= this.AttributeNumber
                                    select case this.AttributesName(tAttribute)
                                        case "WIDTH"
                                            if instr(this.AttributesValue(tAttribute),"%") > 0 then
                                               this.ElementsTableWidth(tElement) = MaxWidth * val(replace$(this.AttributesValue(tAttribute),"%","")) / 100
                                            else
                                                this.ElementsTableWidth(tElement) = val(this.AttributesValue(tAttribute))
                                                if this.ElementsTableWidth(tElement) > tWidth then tWidth = this.ElementsTableWidth(tElement)
                                            end if    
                                        case "BORDER"
                                            this.ElementsBorderWidth(tElement) = val(this.AttributesValue(tAttribute))
                                        case "CELLPADDING"
                                            this.ElementsCellpadding(tElement) = val(this.AttributesValue(tAttribute))
                                        case "CELLSPACING"
                                            this.ElementsCellSpacing(tElement) = val(this.AttributesValue(tAttribute))
                                        case "ALIGN"
                                            if ucase$(this.AttributesValue(tAttribute)) = "CENTER" then 
                                                this.ElementsCenter(tElement) = true
                                            end if
                                        case else
                                    end select        
                                    tAttribute++
                                wend
                            case "TD","TH"
                                this.ElementsType(tElement)        = "TD"
                                this.ElementsColSpan(tElement)     = 1
                                this.ElementsCellWidth(tElement)   = 1
                                this.ExtractAttributes((this.ElementsText(tElement)))
                                tAttribute = 1
                                while tAttribute <= this.AttributeNumber
                                    select case this.AttributesName(tAttribute)
                                        case "WIDTH"
                                            if instr(this.AttributesValue(tAttribute),"%") > 0 then
                                                this.ElementsCellWidth(tElement) = val(replace$(this.AttributesValue(tAttribute),"%","")) / 100
                                            else
                                                this.ElementsCellWidth(tElement) = val(this.AttributesValue(tAttribute))
                                            end if    
                                        case "COLSPAN"
                                            this.ElementsBorderWidth(tElement) = val(this.AttributesValue(tAttribute))
                                        case "ALIGN"
                                            if ucase$(this.AttributesValue(tAttribute)) = "CENTER" then 
                                                this.ElementsCenter(tElement) = true
                                            end if
                                            if ucase$(this.AttributesValue(tAttribute)) = "RIGHT" then 
                                                this.ElementsRight(tElement) = true
                                            end if
                                        case else
                                    end select        
                                    tAttribute++
                                wend
                            case "TITLE"
                                ParseWord = false
                            case "U"
                                this.ElementsFontU(tElement)     = true
                            case else
                                if left$(tMarkUp,1) = "/" then 
                                    'may need some specific treatment 
                                    tMarkup = mid$(tMarkUp,2,len(tMarkup)-1)
                                    select case tMarkup
                                        case "A"
                                            this.ElementsAnchorsPosition(tElement) = ""
                                            this.ElementsAnchorsShape(tElement)    = "rect"
                                            this.ElementsAnchorsHref(tElement)     = ""
                                            this.ElementsAnchorsID(tElement)       = ""

                                            this.ElementsAnchorsTitle(tElement)    = ""
                                        case "TITLE"
                                            this.DocumentTitle = this.htmltextcleaning(this.ElementsText(tElement-1),false)
                                            ParseWord = true
                                        case "PRE","KBD"
                                            this.ModePRE = false    
                                        case else
                                    end select
                                    'Terminate specifc markuptag by retrieving previous open one
                                    tAttribute = tElement
                                    while tAttribute > 0 and this.ElementsType(tAttribute) <> tmarkup
                                        tAttribute--        
                                    wend
                                    if tAttribute > 1 then
                                        tAttribute--
                                        this.ElementsFontName(tElement)       = this.ElementsFontName(tAttribute)
                                        this.ElementsFontSize(tElement)       = this.ElementsFontSize(tAttribute)
                                        this.ElementsFontColor(tElement)      = this.ElementsFontColor(tAttribute)
                                        this.ElementsFontB(tElement)          = this.ElementsFontB(tAttribute)
                                        this.ElementsFontI(tElement)          = this.ElementsFontI(tAttribute)
                                        this.ElementsFontU(tElement)          = this.ElementsFontU(tAttribute)
                                        this.ElementsFontS(tElement)          = this.ElementsFontS(tAttribute)
                                    end if    
                                end if    
                        end select
                    else
                        'Well, it is NOT a Markup, should be text: parse word by word
                        if ParseWord = true then
                            SubWordTreated = 1
                            SubWord        = this.ExtractWord(Words,1,chr$(13))
                            tElement--
                            while SubWord <> chr$(1) 'end
                                if SubWordTreated > 1 then
                                    tElement = this.AddElement(tElement)
                                    this.ElementsType(tElement) = "BR"
                                end if
                                'Whithin Subwords, Words treatment
                                WordTreated = 1
                                Word        = this.ExtractWord(SubWord,1," ")
                                while Word <> chr$(1) 'end
                                    if wordtreated > 1 then this.ElementsText(tElement) = this.ElementsText(tElement) + " "
                                    tElement = this.AddElement(tElement)
                                    this.ElementsText(tElement) = word
                                    WordTreated++
                                    word = this.ExtractWord(SubWord,WordTreated," ")
                                wend
                                SubWordTreated++
                                Subword = this.ExtractWord(Words,SubWordTreated,chr$(13))
                            wend
                        else
                            'We don't parse words (should be TITLE or other similar stuff
                            this.ElementsType(tElement) = "NOTHINNOTHINNOTHIN" 
                        end if
                    end if 
                end if
            wend              
            this.Elements = tElement
            this.bar.min      = 0 
            this.bar.position = 0
            this.bar.max      = 0 
            this.bar.enabled  = false
            this.cursor           = crDefault 
            this.image.cursor     = crDefault 
            this.bar.cursor       = crDefault 
            this.HoverText.cursor = crDefault 
            doevents
        end sub
        
    'PaintLine: paint one "line" of elements
        Function PaintLine(Mode as String, Top as Integer, Left as Integer, Right as Integer) as integer
            Dim i as integer
            Dim tLeft as Integer, tTop as Integer, LineHeight as integer
            Dim word as String
            Dim word1 as String, word2 as String, word3 as String
            Dim tElement as integer
            Dim rect as QRect
            Dim dest as QRect
                        Dim Total as Integer
            Dim Gap as Integer
            
            LineHeight = 10  'At a minimum
            total      = 0
            gap        = 0
            
            'Calculation of left and top positions
            for i = 1 to this.OnLine
                tElement = this.ElementsOnLine(i)
                if this.ElementsHeight(tElement) > LineHeight then LineHeight = this.ElementsHeight(tElement)
                total = total + this.ElementsWidth(tElement)
            next
            select case Mode
                case "Center"
                    tLeft      = int ( (right - total) / 2)
                case "Justify"
                    tLeft      = Left
                    if this.Online > 1 then Gap = int ( (right - left - total) / (this.OnLine - 1) )
                case "Right"
                    tLeft      = Left
                case else 'including "Left"
                    tLeft      = Left
            end select    
            
            'Let's go
            if this.PrintMode = true then
                if (Top > this.zoompage * this.zoom.Height ) or _ 
                    (Top + LineHeight) <= (this.zoompage - 1)* this.zoom.Height then  this.OnLine = 0
            else
                if (Top - this.bar.position) > this.image.Height or _ 
                    (Top - this.bar.position + LineHeight) <= 0 then  this.OnLine = 0
            end if
            i = 1
            while i <= this.OnLine
                tElement = this.ElementsOnLine(i)
                tTop = top + LineHeight - this.ElementsHeight(tElement)
                this.ElementsTop(tElement) = tTop
                this.ElementsWidth(tElement) = this.ElementsWidth(tElement) + gap
                word =  this.ElementsText(tElement)
                if len(this.ElementsType(tElement)) > 0 then 
                    ' Image
                    rect.left = 0
                    rect.top  = 0 
                    if this.IsDrawable(this.ElementsImgSource(tElement)) = true then
                        rect.right = this.ExternalPicture.width
                        rect.bottom = this.ExternalPicture.height
                    else    
                        rect.right  = this.image.textwidth(this.ElementsImgSource(tElement))
                        rect.bottom = this.image.textheight(this.ElementsImgSource(tElement))
                        this.ExternalPicture.width  = rect.right
                        this.ExternalPicture.height = rect.bottom 
                        this.ExternalPicture.textout(0,0,this.ElementsImgSource(tElement),0,rgb(255,255,255))
                    end if
                    if this.PrintMode = true then
                        dest.left = tLeft
                        dest.top  = tTop- (this.ZoomPage-1)*this.Zoom.Height
                        dest.right = tLeft+this.ExternalPicture.width
                        dest.bottom = dest.Top+this.ExternalPicture.height
                        this.zoom.copyrect(dest,this.ExternalPicture,rect)
                    else
                        dest.left = tLeft
                        dest.top  = tTop - this.bar.position
                        dest.right = tLeft+this.ExternalPicture.width
                        dest.bottom = dest.Top+this.ExternalPicture.height
                        this.image.copyrect(dest,this.ExternalPicture,rect)
                        this.ElementsAnchorsPosition(tElement) = _
                            str$(dest.left  )+","+ _
                            str$(dest.Top   )+","+ _
                            str$(dest.right )+","+ _
                            str$(dest.bottom)+","
                        this.ElementsAnchorsShape(tElement)    = "RECT"
                    end if
                else
                    'Well, some text: prepare font and draw
                    if this.PrintMode = true then
                        this.zoom.Font.name  = this.ElementsFontName(tElement)
                        this.zoom.Font.size  = this.ElementsFontSize(tElement)
                        this.zoom.Font.delstyles(fsBold,fsItalic,fsUnderline,fsStrikeOut)
                        if this.ElementsFontB(tElement) = true then this.zoom.Font.addstyles(fsBold) 
                        if this.ElementsFontU(tElement) = true then this.zoom.Font.addstyles(fsUnderline)
                        if this.ElementsFontI(tElement) = true then this.zoom.Font.addstyles(fsItalic) 
                        if this.ElementsFontS(tElement) = true then this.zoom.Font.addstyles(fsStrikeOut)
                        this.zoom.textout(tLeft,tTop - (this.ZoomPage-1)*this.Zoom.Height,word,this.ElementsFontColor(tElement),-1) ' -1 to be transparent
                    else
                        this.image.Font.name  = this.ElementsFontName(tElement)
                        this.image.Font.size  = this.ElementsFontSize(tElement)
                        this.image.Font.delstyles(fsBold,fsItalic,fsUnderline,fsStrikeOut)
                        if this.ElementsFontB(tElement) = true then this.image.Font.addstyles(fsBold) 
                        if this.ElementsFontU(tElement) = true then this.image.Font.addstyles(fsUnderline)
                        if this.ElementsFontI(tElement) = true then this.image.Font.addstyles(fsItalic) 
                        if this.ElementsFontS(tElement) = true then this.image.Font.addstyles(fsStrikeOut)
                        if this.ElementsHighLightFrom(tElement) > 0 then
                            word1 = ""
                            word2 = mid$(word,this.ElementsHighLightFrom(tElement), 1 + this.ElementsHighLightTo(tElement) - this.ElementsHighLightFrom(tElement))
                            word3 = "" 
                            if this.ElementsHighLightFrom(tElement) > 1 then 
                                word1 =left$(word,this.ElementsHighLightFrom(tElement)-1)
                                this.image.textout(tLeft,tTop - this.bar.position,word1,this.ElementsFontColor(tElement),-1) ' -1 to be transparent
                            end if    
                            this.image.textout(tLeft+this.image.textwidth(word1),tTop - this.bar.position,word2,this.FrameFoundTextColor,0) 
                            if this.ElementsHighLightTo(tElement) < len(word) then
                                word3 =right$(word,len(word) - this.ElementsHighLightTo(tElement))
                                this.image.textout(tLeft+this.image.textwidth(word1+word2),tTop - this.bar.position,word3,this.ElementsFontColor(tElement),-1) ' -1 to be transparent
                            end if    

                        else
                            this.image.textout(tLeft,tTop - this.bar.position,word,this.ElementsFontColor(tElement),-1) ' -1 to be transparent
                        end if
                    end if
                    'Hyperlink somewhere ? Anyway, we calculate a potential anchor rect because
                    'our tool is able to "event" any portion (HREF or Texte or Image)
                        this.ElementsAnchorsPosition(tElement) = _
                            str$(tLeft)+","+ _
                            str$(tTop - this.bar.position)+","+ _
                            str$(tLeft+this.ElementsWidth(tElement))+","+ _
                            str$(tTop - this.bar.position+this.ElementsHeight(tElement))+","
                        this.ElementsAnchorsShape(tElement)    = "RECT"
                end if

                tLeft = tLeft + this.ElementsWidth(tElement) + gap
                total = total
                if tElement < this.FirstVisible then this.FirstVisible = tElement
                if tElement > this.LastVisible  then this.LastVisible  = tElement
                this.ElementsOnLine(i) = 0
                i++
            wend
            this.OnLine    = 0
            this.PaintLine = top + LineHeight 
        end Function

    'Paint: we paint only visible part of the HTML page
        sub paint()
            dim rect as QRect
            dim dest as QRect
            dim tElement as integer
            dim lig as integer, ligMax as integer
            dim col as integer, colMax as integer
            dim tLeft as Integer, tTop as integer, MinWidth as integer
            dim MaxWidth as integer, tWidth as integer, VeryMaxWidth as integer
            dim MyFont as QFont
            Dim SubWordTreated as integer, WordTreated as integer
            Dim SubWord as string, Word as String, Words as string
            dim tMarkup as string, OldWords as string
            dim Mode as string
                    
            'Just prepare correct sizing
            if this.PrintMode = true then
                if Printer.Orientation = poPortrait then
                    this.zoom.width    = 800 
                    this.zoom.height   = this.zoom.width * (printer.pageheight - 40) / (printer.pagewidth  - 40)
                else
                    this.zoom.height   = 800 
                    this.zoom.width    = this.zoom.height * (printer.pagewidth - 40) / (printer.pageheight  - 40)
                end if
                if this.ZoomWithBG.checked = true then
                    this.zoom.fillrect(0,0,this.zoom.width ,this.zoom.height,this.FrameBGColor)
                else
                    this.zoom.fillrect(0,0,this.zoom.width ,this.zoom.height,rgb(255,255,255))
                end if    
                veryMaxWidth = this.zoom.Width
            else
                this.cursor           = crHourGlass 
                this.image.cursor     = crHourGlass 
                this.bar.cursor       = crHourGlass 
                this.HoverText.cursor = crHourGlass 
                this.Hovertext.top    = this.Height - this.Hovertext.Height - 4
                this.HoverText.width  = this.width - 4
                this.image.width      = this.HoverText.width - this.bar.width
                this.image.height     = this.HoverText.top
                this.zoom.width       = this.image.width
                this.zoom.height      = this.image.height
                veryMaxWidth = this.image.width
                this.zoom.fillrect(0,0,this.zoom.width,this.zoom.height,this.FrameBGColor)
                doevents
            end if 

            'Background image of the page, if any 
            if len(this.FrameBackGroundBmp) > 0 and _ 
                (this.ZoomWithBG.checked = true or this.PrintMode = false) then
                if this.IsDrawable(this.FrameBackGroundBmp) = true then
                    ligMax = int(this.zoom.height / this.ExternalPicture.height)
                    colMax = int(this.zoom.width  / this.ExternalPicture.width)
                    rect.left   = 0
                    rect.top    = 0
                    rect.right  = this.ExternalPicture.width
                    rect.bottom = this.ExternalPicture.height
                    lig = 0
                    while lig <= ligMax
                        col = 0
                        while col <= colMax
                            dest.left   = int( col * this.ExternalPicture.width )
                            dest.top    = int( lig * this.ExternalPicture.height )
                            dest.right  = int( (col + 1) * this.ExternalPicture.width )
                            dest.bottom = int( (lig + 1) * this.ExternalPicture.height )
                            this.zoom.copyrect(dest,this.ExternalPicture,rect)
                            col++
                        wend
                        lig++
                    wend
                end if
            end if
            if this.PrintMode = false then this.image.bmp = this.zoom.bmp  
            MinWidth = 0
            MaxWidth = veryMaxWidth
            
            'Somecleaning before starting big loop
            tLeft                  = MinWidth
            tTop                   = 0
            Mode                   = "Left"
            this.FirstVisible      = 64000
            this.LastVisible       = 0  
            this.ElementsOnLine(1) = 0
            this.OnLine            = 0

            for tElement = 1 to this.Elements
                this.ElementsWidth(tElement)  = 0
                this.ElementsHeight(tElement) = 0
                this.ElementsTop(tElement) = 0
                tMarkup = this.ElementsType(tElement)
                if len(tMarkup) > 0 then
                    select case tMarkup
                        case "BLOCKQUOTE", "CITE"
                            tTop     = this.PaintLine(Mode,tTop, MinWidth,MaxWidth)
                            MinWidth = 30
                            MaxWidth = veryMaxWidth - 35
                            tLeft    = MinWidth
                        case "BR"
                            tTop     = this.PaintLine(Mode,tTop, MinWidth,MaxWidth)
                            tLeft    = MinWidth
                            MaxWidth = veryMaxWidth
                        case "CENTER"
                            tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth)
                            Mode     = "Center"
                            tLeft    = MinWidth
                            MaxWidth = veryMaxWidth
                        case "DL"
                            tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth)
                            MinWidth   = 0
                            tLeft      = MinWidth
                            MaxWidth   = veryMaxWidth
                        case "DD"
                            tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth)
                            MinWidth   = 10
                            tLeft      = MinWidth
                            MaxWidth   = veryMaxWidth
                        case "DT"
                            tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth)
                            MinWidth   = 0
                            tLeft      = MinWidth
                            MaxWidth   = veryMaxWidth
                        case "H1"
                            tTop       = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) + 10
                            tLeft      = MinWidth
                            MaxWidth   = veryMaxWidth

                        case "H2"
                            tTop       = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) 
                            tLeft      = MinWidth
                            MaxWidth   = veryMaxWidth
                        case "H3"
                            tTop       = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) 
                            tLeft      = MinWidth
                            MaxWidth   = veryMaxWidth
                        case "H4"
                            tTop       = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) 
                            tLeft      = MinWidth
                            MaxWidth   = veryMaxWidth
                        case "H5"
                            tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) 
                            tLeft    = MinWidth
                            MaxWidth = veryMaxWidth
                        case "H6" 
                            tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) 
                            tLeft    = MinWidth
                            MaxWidth = veryMaxWidth
                        case "IMG"
                            if this.IsDrawable(this.ElementsImgSource(tElement)) = true then
                                this.ElementsWidth(tElement)  = this.ExternalPicture.width

                                this.ElementsHeight(tElement) = this.ExternalPicture.height
                            else
                                this.ElementsWidth(tElement) = this.image.textwidth(this.ElementsImgSource(tElement))
                                this.ElementsHeight(tElement)= this.image.textheight(this.ElementsImgSource(tElement))
                            end if
                            if tLeft+this.ElementsWidth(tElement) > MaxWidth then 
                                tTop  = this.PaintLine(Mode,tTop, MinWidth,MaxWidth)
                                tLeft = MinWidth
                            end if    
                            this.OnLine = this.OnLine + 1
                            this.ElementsOnLine(this.OnLine)= tElement
                            tLeft = tLeft+this.ElementsWidth(tElement)
                            this.ElementsTop(tElement) = tTop
                        case "P"
                            tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) 
                            tLeft      = MinWidth
                        case "PRE","KBD"
                            tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) 
                            tLeft    = MinWidth
                            MaxWidth = veryMaxWidth
                        case "TABLE"
                        case "TD","TH"
                        case "TITLE"
                            tElement++
                        case "U"
                        case else
                          if left$(tMarkUp,1) = "/" then 
                                select case mid$(tMarkUp,2,len(tMarkup)-1)
                                    case "BLOCKQUOTE", "CITE"
                                        tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) 
                                        MinWidth = 0
                                        MaxWidth = veryMaxWidth
                                        tLeft    = MinWidth
                                    case "CENTER"
                                        tTop     = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) 
                                        Mode     = "Left"
                                        tLeft    = MinWidth
                                    case "DL"
                                        tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) 
                                        MinWidth = 0
                                        tLeft    = MinWidth
                                    case "PRE"
                                        tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) 
                                        tLeft    = MinWidth
                                        MaxWidth = veryMaxWidth
                                    case else    
                                       'Nothing
                                end select        
                            end if    
                    end select
                else
                    'Well, it is NOT a Markup, should be text !
                    'Change font for sizing is necessary, even if not yet drawn
                    this.image.Font.name  = this.ElementsFontName(tElement)
                    this.image.Font.size  = this.ElementsFontSize(tElement)
                    this.image.Font.delstyles(fsBold,fsItalic,fsUnderline,fsStrikeOut)
                    if this.ElementsFontB(tElement) = true then this.image.Font.addstyles(fsBold) 
                    if this.ElementsFontI(tElement) = true then this.image.Font.addstyles(fsItalic) 
                    if this.ElementsFontU(tElement) = true then this.image.Font.addstyles(fsUnderline)
                    if this.ElementsFontS(tElement) = true then this.image.Font.addstyles(fsStrikeOut)
                    word =  this.ElementsText(tElement)
                    this.ElementsWidth(tElement)  = this.image.textwidth(word)
                    this.ElementsHeight(tElement) = this.image.textheight(word) 
                    if tLeft+this.ElementsWidth(tElement) >= MaxWidth then 
                        tTop  = this.PaintLine(Mode,tTop, MinWidth,MaxWidth)
                        tLeft = MinWidth
                    end if    
                    this.OnLine = this.OnLine + 1
                    this.ElementsOnLine(this.OnLine)= tElement
                    tLeft = tLeft+this.ElementsWidth(tElement) 
                    this.ElementsTop(tElement) = tTop
                end if 
            next 
            tTop = this.PaintLine(Mode,tTop, MinWidth,MaxWidth) + 100 'last "line"
            
            if this.BarResize = true and this.PrintMode = false then
                this.bar.parent   = this 'just need to be done once, BUT AFTER constructor performed
                this.bar.left     = this.width - this.bar.width - 2
                this.bar.height   = this.image.height
            
                if (tTop - this.Height + 4) > 0 then
                    this.bar.max      = tTop - this.Height + 4 
                    this.bar.LargeChange = this.Image.height
                    this.bar.SmallChange = 20
                    this.bar.enabled  = true
                    this.bar.PageSize = int ( (this.image.Height) * (this.image.Height) / this.bar.max ) - 50
                else
                    this.bar.enabled     = false
                    this.bar.position    = 0
                    this.bar.max         = 0
                    this.bar.LargeChange = 1
                    this.bar.SmallChange = 1
                    this.bar.pagesize    = 0 'this.height - 50
                end if
            end if
            if this.PrintMode = true then this.ZoomPages = int ( tTop / this.zoom.Height) + 1
            
            this.cursor           = crDefault
            this.image.cursor     = crDefault
            this.bar.cursor       = crDefault
            this.HoverText.cursor = crDefault
        end sub

    'Timer to launch new paint
        Sub PaintTimer_ToDo
            this.PaintTimer.Enabled = false
            if len(this.FrameSource) <= 0 then this.parseText(htmlDefaultHTML)
            this.paint
        end sub

    'events
    '======
        'Bar click
        '=========
        Event bar.OnChange
            this.BarResize          = false
            this.PrintMode          = false
            this.PaintTimer.Enabled = true
        end event
        
        'Raise Event URL hovered
        '=======================
        Event Image.OnMouseMove(x as long, y as long , shift as long)
            Dim i as integer
            Dim x1 as integer
            Dim y1 as integer
            Dim x2 as integer
            Dim y2 as integer
            
            this.HoveredTag    = ""
            this.HoveredObject = ""
            this.Hovertext.panel(0).caption = ""
            for i = this.FirstVisible to this.LastVisible
                if len(this.ElementsAnchorsPosition(i)) > 0 then
                    select case this.ElementsAnchorsShape(i)    
                        case "RECT" 
                            x1 = val( this.ExtractWord(this.ElementsAnchorsPosition(i),1,",") )
                            y1 = val( this.ExtractWord(this.ElementsAnchorsPosition(i),2,",") )
                            x2 = val( this.ExtractWord(this.ElementsAnchorsPosition(i),3,",") )
                            y2 = val( this.ExtractWord(this.ElementsAnchorsPosition(i),4,",") )
                            if x >= x1 and x <= x2 and y >= y1 and y <= y2 then
                                if len(this.ElementsAnchorsHRef(i)) > 0 then
                                    this.HoveredObject = "HREF"
                                    this.HoveredTag    = this.ElementsAnchorsHRef(i)
                                    exit for
                                else
                                    this.HoveredObject = this.ElementsType(i)
                                    this.HoveredTag    = this.ElementsText(i)
                                    exit for
                                end if
                            end if
                        case else
                    end select
                end if         
            next
            if len(this.HoveredObject) = 0 or this.HoveredObject <> "HREF" then
                screen.cursor = crDefault

            else    
                screen.cursor = crHandPoint
            end if
            if this.OnHover > 0 then CALLFUNC(this.OnHover,this.HoveredObject,this.HoveredTag)
            if this.HoveredObject = "HREF" then this.Hovertext.panel(0).caption = this.HoveredTag
        end event

        'Raise Event URL clicked
        '=======================
        Event Image.OnMouseUp(Button as long, x as long, y as long , shift as long, Cancel as integer)
            Cancel = 1 'true
            if ( len(this.HoveredTag) * this.OnTagClick ) > 0 then CALLFUNC(this.OnTagClick,this.HoveredTag)
        end event

        
Public:

    'Properties
    '==========
        'html text
        '=========
        PROPERTY SET SetHTMLText(HTMLText AS STRING)
            this.BarResize          = true
            this.PrintMode          = false
            this.parseText(HTMLTExt)
            this.PaintTimer.Enabled = true
        END PROPERTY

       'DocumentTitle
       '=============
        Property Set Set_DocumentTitle(NewDocumentTitle As String)
            'Nothing !
        End Property Set
       
        'DefaultFontName
        '===============
        Property Set Set_DefaultFontName(NewDefaultFontName As String)
            this.DefaultFontName = NewDefaultFontName
        End Property Set

        'DefaultFontSize
        '===============
        Property Set Set_DefaultFontSize(NewDefaultFontSize As Integer)
            this.DefaultFontSize = NewDefaultFontSize
        End Property Set


    'Methods and functions
    '=====================

        'Open a file
        SUB OpenFile(FileName as String)
            dim File as QFileStream
            File.open(FileName,fmOpenRead)
            this.parseText(File.ReadStr(File.Size))
            File.close
            this.BarResize          = true
            this.PrintMode          = false
            this.PaintTimer.Enabled = true
        END SUB
        
        'Repaint 
        SUB Repaint
            this.BarResize          = true

            this.PrintMode          = false
            this.PaintTimer.Enabled = true
        end sub
        
        'Print preview
        '-------------
Private:
        Sub ZoomTimer_ToDo
            this.ZoomTimer.Enabled = false
            this.BarResize          = false
            this.PrintMode          = true
            this.PaintTimer.Enabled = true
            while this.PaintTimer.Enabled = true
                doevents
            wend
            this.ZoomImage.bmp = this.zoom.bmp
            if this.zoomPage = 1 then 
                this.ZoomPF.enabled = false
                this.ZoomPP.enabled = false
            else
                this.ZoomPF.enabled = true
                this.ZoomPP.enabled = true
            end if
            if this.zoomPage = this.ZoomPages then 
                this.ZoomPN.enabled = false
                this.ZoomPL.enabled = false
            else
                this.ZoomPN.enabled = true
                this.ZoomPL.enabled = true
            end if
        end sub
  
        SUB QPrint_Click
            Dim Rect as Qrect
            
            Rect.Left   = 20
            Rect.Top    = 20
            Rect.Right  = Printer.PageWidth  - 20 
            Rect.Bottom = Printer.PageHeight - 20 
            
            Printer.Begindoc
            Printer.title = this.DocumentTitle
            Printer.StretchDraw(rect,this.zoom)
            Printer.textout(Rect.left,Rect.bottom-30, "Page "+str$(this.ZoomPage)+"/"+str$(this.ZoomPages),0,-1)
            printer.Enddoc
        end sub        

        SUB QPrintAll_Click
            Dim i as Integer, JS as integer
            Dim Rect as Qrect
            

            Rect.Left   = 20
            Rect.Top    = 20
            Rect.Right  = Printer.PageWidth  - 20 
            Rect.Bottom = Printer.PageHeight - 20 
            Printer.title = this.DocumentTitle 
            Printer.Begindoc
            jS = this.ZoomPage 
            for i = 1 to this.ZoomPages
                this.ZoomPage = i
                this.ZoomTimer.Enabled = true
                while  this.ZoomTimer.Enabled = true
                    doevents
                wend
                if i > 1 then Printer.Newpage
                Printer.StretchDraw(rect,this.zoom)
                Printer.textout(rect.left,Rect.bottom-30,  "Page "+str$(this.ZoomPage)+"/"+str$(this.ZoomPages),0,-1)
            next
            printer.Enddoc
            this.ZoomPage = jS
            this.ZoomTimer.Enabled = true
        end sub        

        sub QWithBG_Click
            this.ZoomTimer.Enabled  = true
        end sub

        sub QPF_Click
            this.zoomPage  = 1
            this.ZoomTimer.Enabled = true
        end sub

        sub QPP_Click
            this.zoomPage  = this.zoomPage - 1
            this.ZoomTimer.Enabled = true
        end sub

        sub QPN_Click
            this.zoomPage  = this.zoompage + 1
            this.ZoomTimer.Enabled = true
        end sub
        
        sub QPL_Click
            this.zoomPage  = this.zoompages
            this.ZoomTimer.Enabled = true 
        end sub

        SUB QSAVE_Click
            Dim SaveDialog as QSaveDialog

            SaveDialog.Caption = "BitMap record"
            SaveDialog.Filter = "BitMap Files|*.bmp|All Files|*.*"
            SaveDialog.FilterIndex = 1             
            if SaveDialog.execute then this.zoom.SaveToFile(SaveDialog.FileName)
        end sub
        
        Sub ZoomPrinters_Click
            printer.PrinterIndex = this.zoomPrinters.Itemindex  
            this.ZoomTimer.Enabled = true
        end sub

Public:       
        SUB PrintPreview
            Dim ratio as double
            Dim bmp as QBitMap
            Dim i as Integer
            Dim BackGround as Qpanel
            
            'Zoom window
            this.zoomPage  = 1
            this.zoompages = 1
            this.ZoomForm.caption     = this.DocumentTitle+" - Preview"
            this.zoomForm.WindowState = wsMaximized
            
            'Page
            BackGround.parent         = this.ZoomForm
            BackGround.Top            = 45
            BackGround.Color          = clWhite
            if Printer.Orientation = poPortrait then
                BackGround.height = this.ZoomForm.ClientHeight - 50
                BackGround.Width  = int ( BackGround.height * Printer.PageWidth / Printer.PageHeight ) 
                BackGround.Left   = int ( (this.ZoomForm.ClientWidth - BackGround.Width) / 2 )
            else
                BackGround.width  = this.ZoomForm.ClientWidth - 20
                BackGround.Height = int ( BackGround.Width * Printer.PageHeight / Printer.PageWidth ) 
                BackGround.Left   = 10
            end if    
            this.ZoomImage.parent        = BackGround
            this.ZoomImage.Top           = 10
            this.ZoomImage.Left          = 10
            this.ZoomImage.width         = BackGround.Width  - 20
            this.ZoomImage.height        = BackGround.Height - 20
            
            'Print buttons
            this.ZoomPrint.Parent        = this.ZoomForm
            this.ZoomPrint.Left          = 2
            this.ZoomPrint.Top           = 2
            this.Zoomprint.Font.Name     = "Wingdings" 
            this.ZoomPrint.Caption       = "3"
            this.ZoomPrint.Font.Size     = 20
            this.ZoomPrint.hint          = "Print current page"
            this.ZoomPrint.Showhint      = true
            this.ZoomPrint.width         = 35
            this.ZoomPrint.Height        = 35
            this.ZoomPrint.OnClick       = this.QPrint_Click
            this.ZoomPrintAll.Parent     = this.ZoomForm
            this.ZoomPrintAll.Left       = 40
            this.ZoomPrintAll.Top        = 2
            this.ZoomprintAll.Font.Name  = "Wingdings" 
            this.ZoomPrintAll.Caption    = "4"
            this.ZoomPrintAll.Font.Size  = 20
            this.ZoomPrintAll.hint       = "Print all pages"
            this.ZoomPrintAll.Showhint   = true
            this.ZoomPrintAll.width      = 35
            this.ZoomPrintAll.Height     = 35
            this.ZoomPrintAll.OnClick    = this.QPrintAll_Click
            
            'Move within Pages
            this.ZoomPF.Parent           = this.ZoomForm
            this.ZoomPF.Left             = 90
            this.ZoomPF.Top              = 2
            this.ZoomPF.Font.Name        = "Wingdings" 
            this.ZoomPF.Caption          = "Û"
            this.ZoomPF.Font.Size        = 20
            this.ZoomPF.hint             = "First page"
            this.ZoomPF.Showhint         = true
            this.ZoomPF.width            = 35
            this.ZoomPF.Height           = 35
            this.ZoomPF.OnClick          = this.QPF_Click
            this.ZoomPP.Parent           = this.ZoomForm
            this.ZoomPP.Left             = 125
            this.ZoomPP.Top              = 2
            this.ZoomPP.Font.Name        = "Wingdings" 
            this.ZoomPP.Caption          = "ß"
            this.ZoomPP.Font.Size        = 20
            this.ZoomPP.hint             = "Previous page"
            this.ZoomPP.Showhint         = true
            this.ZoomPP.width            = 35
            this.ZoomPP.Height           = 35
            this.ZoomPP.OnClick          = this.QPP_Click
            this.ZoomPN.Parent           = this.ZoomForm
            this.ZoomPN.Left             = 160
            this.ZoomPN.Top              = 2
            this.ZoomPN.Font.Name        = "Wingdings" 
            this.ZoomPN.Caption          = "à"
            this.ZoomPN.Font.Size        = 20
            this.ZoomPN.hint             = "Next page"
            this.ZoomPN.Showhint         = true
            this.ZoomPN.width            = 35
            this.ZoomPN.Height           = 35
            this.ZoomPN.OnClick          = this.QPN_Click
            this.ZoomPL.Parent           = this.ZoomForm
            this.ZoomPL.Left             = 195
            this.ZoomPL.Top              = 2
            this.ZoomPL.Font.Name        = "Wingdings" 
            this.ZoomPL.Caption          = "Ü"
            this.ZoomPL.Font.Size        = 20
            this.ZoomPL.hint             = "Last page"
            this.ZoomPL.Showhint         = true
            this.ZoomPL.width            = 35
            this.ZoomPL.Height           = 35
            this.ZoomPL.OnClick          = this.QPL_Click
            this.ZoomSave.Parent         = this.ZoomForm
            this.ZoomSave.Left           = 260
            this.ZoomSave.Top            = 2
            this.ZoomSave.Font.Name      = "Wingdings" 
            this.ZoomSave.Caption        = "<"
            this.ZoomSave.Font.Size      = 20
            this.ZoomSave.hint           = "Save current page as BitMap"
            this.ZoomSave.Showhint       = true
            this.ZoomSave.width          = 35
            this.ZoomSave.Height         = 35
            this.ZoomSave.OnClick        = this.QSAVE_CLICk
            
            'HTML pages Background
            this.ZoomWithBG.parent       = this.ZoomForm
            this.ZoomWithBG.left         = 350
            this.ZoomWithBG.caption      = "With background"
            this.ZoomWithBG.top          = 12
            this.ZoomWithBG.hint         = "Print Text with background"
            this.ZoomWithBG.Showhint     = true
            this.ZoomWithBG.OnClick      = this.QWithBG_Click
            this.ZoomWithBG.width        = 150
            
            'Printers list
            this.ZoomPrinters.parent     = this.ZoomForm
            this.ZoomPrinters.left       = 500
            this.ZoomPrinters.top        = 10
            this.ZoomPrinters.hint       = "Printer selection"
            this.ZoomPrinters.Showhint   = true
            this.ZoomPrinters.OnChange   = this.ZoomPrinters_Click
            this.ZoomPrinters.width      = 200
            this.zoomPrinters.style      = csDropDownList
            for i = 0 to Printer.PrintersCount-1
                this.ZoomPrinters.Additems(Printer.Printers(i))
            next
            this.zoomPrinters.Itemindex  = Printer.PrinterIndex
                          
            'Let's go now                        
            this.ZoomImage.stretch = true
            this.ZoomTimer.Enabled = true 'do the real taff
            this.ZoomForm.showmodal
        end sub


        'Search 
        '------
Private:
        Sub SearchReset
            dim i as integer
            i = this.searchIndex1
            while i <= this.SearchIndex2
                if this.ElementsHighlightFrom(i) > 0 then 
                    this.ElementsHighlightFrom(i) = 0
                    this.ElementsHighlightTo(i)   = 0
                end if
                i++
            wend
            this.searchIndex1 = 0
            this.searchIndex2 = 0
        end Sub
        sub QED_Change      
            if len(this.SearchQED.text) > 0 then
                this.SearchQEDN.enabled = true
            else
                this.SearchQEDN.enabled = false
            end if
            this.SearchReset
        end sub    
        sub QEDN_Click
            Dim i as integer, iM as integer
            Dim Search as String, SearchLength as Integer
            Dim j as integer, k as integer, word as string, words as string
            Dim Fd as integer, Posit as integer
            Dim PosIni as Integer, IndexIni as Integer

            if this.SearchForm.cursor = crHourGlass then exit sub
            this.SearchForm.cursor = crHourGlass
            this.SearchQED.enabled   = false
            this.SearchQEDA.enabled   = false
            this.SearchQEDN.enabled   = false

            'Start the big loop...
            if this.SearchIndex1 > 0 then
                PosIni   = this.ElementsHighlightFrom(this.searchIndex1) + 1
                Posit    = PosIni
                IndexIni = this.searchIndex1 
                if PosIt > len(this.ElementsText(this.searchIndex1)) then
                    PosIt    = 1
                    IndexIni++
                end if
                this.SearchReset 
            else
                PosIni   = 1
                Posit    = 1  
                IndexIni = 1
            end if    
            
            Search = ucase$(this.SearchQED.text)
            SearchLength = len(Search)
            i = IndexIni
            do 
                if len(this.ElementsType(i)) <= 0 then 
                    word =  ucase$(this.ElementsText(i))
                    k = i
                    words = word
                    while len(words) < (2*SearchLength) and k < this.elements
                        k++
                        if len(this.ElementsType(k)) <= 0 then Words = words + ucase$(this.ElementsText(k))
                    wend 
                    Fd = instr(posit,words,Search) 
                    if Fd > 0 and Fd <= len(word) then 
                        this.ElementsHighlightFrom(i) = Fd
                        Fd = SearchLength
                        k = i
                        this.searchIndex1 = i
                        this.searchIndex2 = i
                        while Fd > 0
                            if len(this.ElementsType(k)) <= 0 then
                                if Fd < SearchLength then 
                                    this.ElementsHighlightFrom(k) = 1
                                    this.searchIndex2 = k
                                end if
                                if this.ElementsHighlightFrom(k) + Fd - 1 > len(this.ElementsText(k)) then
                                    this.ElementsHighlightTo(k) = len(this.ElementsText(k))
                                    Fd = Fd - 1  + this.ElementsHighlightFrom(k) - this.ElementsHighlightTo(k) 
                                else
                                    this.ElementsHighlightTo(k) = this.ElementsHighlightFrom(k) + Fd - 1
                                    Fd = 0
                                end if    
                            end if
                            k++
                        wend
                        exit do
                    end if
                end if    
                i++
                if i > this.elements then i = 1
                Posit = 1
                if i = IndexIni and Posit >= PosIni then exit do
            loop
            this.SearchForm.cursor = crDefault
            this.SearchQED.enabled   = true
            this.SearchQEDA.enabled  = true
            this.SearchQEDN.enabled  = false
            if len(this.SearchQED.text) > 0 then
                this.SearchQEDN.enabled = true
            else
                this.SearchQEDN.enabled = false
            end if
            if this.searchIndex1 > 0 then
                if this.elementsTop(this.searchIndex2) - this.bar.position > this.image.height then _
                    this.bar.position = this.ElementsTop(this.SearchIndex2) - this.ElementsHeight(this.SearchIndex2)
                if this.elementsTop(this.searchIndex1) - this.bar.position < 0 then _
                    this.bar.position = this.ElementsTop(this.SearchIndex1)
            end if 
            this.BarResize = false
            this.PrintMode = false
            this.PaintTimer.enabled = true
        end sub
        sub QEDA_Click
            this.SearchForm.close
        end sub
Public:        
        Function SearchText(Text as String, Popupwindow as integer) as Integer
        
            this.SearchQED.text     = text
            if len(text) = 0 then popupwindow = true 
            if Popupwindow = true then
                this.SearchForm.caption = "Search"
                this.SearchForm.height  = 100
                this.SearchForm.caption = "Search"
                this.SearchQEDL.parent  = this.SearchForm
                this.SearchQEDL.top     = 4
                this.SearchQEDL.left    = 5
                this.SearchQEDL.caption = "Search:"
                this.SearchQED.parent   = this.SearchForm
                this.SearchQED.top      = 4
                this.SearchQED.left     = 50
                this.SearchQED.OnChange = this.QED_Change
                this.SearchQEDN.parent  = this.SearchForm
                this.SearchQEDN.top     = 4
                this.SearchQEDN.default = true
                this.SearchQEDN.left    = this.SearchForm.ClientWidth - this.SearchQEDN.width - 5
                this.SearchQEDN.Caption = "Next"
                this.SearchQEDN.OnClick = this.QEDN_Click
                this.SearchQEDN.enabled = false
                this.SearchQEDA.parent  = this.SearchForm
                this.SearchQEDA.top     = this.SearchQEDN.top + this.SearchQEDN.height+5
                this.SearchQEDA.left    = this.SearchQEDN.left
                this.SearchQEDA.Caption = "Cancel"
                this.SearchQEDA.cancel  = true
                this.SearchQEDA.OnClick = this.QEDA_Click
                this.SearchForm.Center
                this.SearchForm.showmodal
            else
                this.QEDN_Click
            end if
            
            this.SearchText = false
            if this.searchIndex1 > 0 then this.SearchText = true
        end function        

    'Constructor defaults
    '====================
    CONSTRUCTOR
        'Defaults
        defaultFontSize = 12
        defaultFontName = "Arial"
        bevelInner = bvlowered
        bevelouter = bvlowered
        
        'Visible elemnts of our object
        image.parent = this
        image.left   = 2
        image.top    = 2 
        HoverText.left  = 2
        HoverText.parent  = this
        HoverText.addpanels " "
        HoverText.sizegrip = false
        bar.kind     = sbVertical
        bar.width    = 17
        PaintTimer.enabled = false
        PaintTimer.Interval = 1
        PaintTimer.OnTimer  = this.PaintTimer_ToDo 
        ExternalPicture.parent = this
        ExternalPicture.AutoSize = true 'this one invisible
        ExternalPicture.visible = false

        'Zoom (preview window)
        ZoomWithBG.checked = true
        ZoomTimer.enabled = false
        ZoomTimer.Interval = 1
        ZoomTimer.OnTimer  = this.ZoomTimer_ToDo 

        'HTML main colors. Well, not ideal, but it works...
        HTMLColorsName(001)   = "aliceblue":             HTMLColorsCode(001) = "F0F8FF"
        HTMLColorsName(002)   = "antiquewhite":          HTMLColorsCode(002) = "FAEBD7"
        HTMLColorsName(003)   = "aqua":                  HTMLColorsCode(003) = "00FFFF"
        HTMLColorsName(004)   = "aquamarine":            HTMLColorsCode(004) = "7FFFD4"
        HTMLColorsName(005)   = "azure":                 HTMLColorsCode(005) = "F0FFFF"
        HTMLColorsName(006)   = "beige":                 HTMLColorsCode(006) = "F5F5DC"
        HTMLColorsName(007)   = "bisque":                HTMLColorsCode(007) = "FFE4C4"
        HTMLColorsName(008)   = "black":                 HTMLColorsCode(008) = "000000"
        HTMLColorsName(009)   = "blanchedalmond":        HTMLColorsCode(009) = "FFEBCD"
        HTMLColorsName(010)   = "blue":                  HTMLColorsCode(010) = "0000FF"
        HTMLColorsName(011)   = "blueviolet":            HTMLColorsCode(011) = "8A2BE2"
        HTMLColorsName(012)   = "brown":                 HTMLColorsCode(012) = "A52A2A"
        HTMLColorsName(013)   = "burlywood":             HTMLColorsCode(013) = "DEB887"
        HTMLColorsName(014)   = "cadetblue":             HTMLColorsCode(014) = "5F9EA0"
        HTMLColorsName(015)   = "chartreuse":            HTMLColorsCode(015) = "7FFF00"
        HTMLColorsName(016)   = "chocolate":             HTMLColorsCode(016) = "D2691E"
        HTMLColorsName(017)   = "coral":                 HTMLColorsCode(017) = "FF7F50"
        HTMLColorsName(018)   = "cornflowerblue":        HTMLColorsCode(018) = "6495ED"
        HTMLColorsName(019)   = "cornsilk":              HTMLColorsCode(019) = "FFF8DC"
        HTMLColorsName(020)   = "crimson":               HTMLColorsCode(020) = "DC143C"
        HTMLColorsName(021)   = "cyan":                  HTMLColorsCode(021) = "00FFFF"
        HTMLColorsName(022)   = "darkblue":              HTMLColorsCode(022) = "00008B"
        HTMLColorsName(023)   = "darkcyan":              HTMLColorsCode(023) = "008B8B"
        HTMLColorsName(024)   = "darkgoldenrod":         HTMLColorsCode(024) = "B8860B"
        HTMLColorsName(025)   = "darkgray":              HTMLColorsCode(025) = "A9A9A9"
        HTMLColorsName(026)   = "darkgreen":             HTMLColorsCode(026) = "006400"
        HTMLColorsName(027)   = "darkkhaki":             HTMLColorsCode(027) = "BDB76B"
        HTMLColorsName(028)   = "darkmagenta":           HTMLColorsCode(028) = "8B008B"
        HTMLColorsName(029)   = "darkolivegreen":        HTMLColorsCode(029) = "556B2F"
        HTMLColorsName(030)   = "darkorange":            HTMLColorsCode(030) = "FF8C00"
        HTMLColorsName(031)   = "darkorchid":            HTMLColorsCode(031) = "9932CC"
        HTMLColorsName(032)   = "darkred":               HTMLColorsCode(032) = "8B0000"
        HTMLColorsName(033)   = "darksalmon":            HTMLColorsCode(033) = "E9967A"
        HTMLColorsName(034)   = "darkseagreen":          HTMLColorsCode(034) = "8FBC8F"
        HTMLColorsName(035)   = "darkslateblue":         HTMLColorsCode(035) = "483D8B"
        HTMLColorsName(036)   = "darkslategray":         HTMLColorsCode(036) = "2F4F4F"
        HTMLColorsName(037)   = "darkturquoise":         HTMLColorsCode(037) = "00CED1"
        HTMLColorsName(038)   = "darkviolet":            HTMLColorsCode(038) = "9400D3"
        HTMLColorsName(039)   = "deeppink":              HTMLColorsCode(039) = "FF1493"
        HTMLColorsName(030)   = "deepskyblue":           HTMLColorsCode(040) = "00BFFF"
        HTMLColorsName(041)   = "dimgray":               HTMLColorsCode(041) = "696969"
        HTMLColorsName(042)   = "dodgerblue":            HTMLColorsCode(042) = "1E90FF"
        HTMLColorsName(043)   = "feldspar":              HTMLColorsCode(043) = "D19275"
        HTMLColorsName(044)   = "firebrick":             HTMLColorsCode(044) = "B22222"
        HTMLColorsName(045)   = "floralwhite":           HTMLColorsCode(045) = "FFFAF0"
        HTMLColorsName(046)   = "forestgreen":           HTMLColorsCode(046) = "228B22"
        HTMLColorsName(047)   = "fuchsia":               HTMLColorsCode(047) = "FF00FF"
        HTMLColorsName(048)   = "gainsboro":             HTMLColorsCode(048) = "DCDCDC"
        HTMLColorsName(049)   = "ghostwhite":            HTMLColorsCode(049) = "F8F8FF"
        HTMLColorsName(050)   = "gold":                  HTMLColorsCode(050) = "FFD700"
        HTMLColorsName(051)   = "goldenrod":             HTMLColorsCode(051) = "DAA520"
        HTMLColorsName(052)   = "gray":                  HTMLColorsCode(052) = "808080"
        HTMLColorsName(053)   = "green":                 HTMLColorsCode(053) = "008000"
        HTMLColorsName(054)   = "greenyellow":           HTMLColorsCode(054) = "ADFF2F"
        HTMLColorsName(055)   = "honeydew":              HTMLColorsCode(055) = "F0FFF0"
        HTMLColorsName(056)   = "hotpink":               HTMLColorsCode(056) = "FF69B4"
        HTMLColorsName(057)   = "indianred":             HTMLColorsCode(057) = "CD5C5C"
        HTMLColorsName(058)   = "indigo":                HTMLColorsCode(058) = "4B0082"
        HTMLColorsName(059)   = "ivory":                 HTMLColorsCode(059) = "FFFFF0"
        HTMLColorsName(060)   = "khaki":                 HTMLColorsCode(060) = "F0E68C"
        HTMLColorsName(061)   = "lavender":              HTMLColorsCode(061) = "E6E6FA"
        HTMLColorsName(062)   = "lavenderblush":         HTMLColorsCode(062) = "FFF0F5"
        HTMLColorsName(063)   = "lawngreen":             HTMLColorsCode(063) = "7CFC00"
        HTMLColorsName(064)   = "lemonchiffon":          HTMLColorsCode(064) = "FFFACD"
        HTMLColorsName(065)   = "lightblue":             HTMLColorsCode(065) = "ADD8E6"
        HTMLColorsName(066)   = "lightcoral":            HTMLColorsCode(066) = "F08080"
        HTMLColorsName(067)   = "lightcyan":             HTMLColorsCode(067) = "E0FFFF"
        HTMLColorsName(068)   = "lightgoldenrodyellow":  HTMLColorsCode(068) = "FAFAD2"
        HTMLColorsName(069)   = "lightgrey":             HTMLColorsCode(069) = "D3D3D3"
        HTMLColorsName(070)   = "lightgreen":            HTMLColorsCode(070) = "90EE90"
        HTMLColorsName(071)   = "lightpink":             HTMLColorsCode(071) = "FFB6C1"
        HTMLColorsName(072)   = "lightsalmon":           HTMLColorsCode(072) = "FFA07A"
        HTMLColorsName(073)   = "lightseagreen":         HTMLColorsCode(073) = "20B2AA"
        HTMLColorsName(074)   = "lightskyblue":          HTMLColorsCode(074) = "87CEFA"
        HTMLColorsName(075)   = "lightslateblue":        HTMLColorsCode(075) = "8470FF"
        HTMLColorsName(076)   = "lightslategray":        HTMLColorsCode(076) = "778899"
        HTMLColorsName(077)   = "lightsteelblue":        HTMLColorsCode(077) = "B0C4DE"
        HTMLColorsName(078)   = "lightyellow":           HTMLColorsCode(078) = "FFFFE0"
        HTMLColorsName(079)   = "lime":                  HTMLColorsCode(079) = "00FF00"
        HTMLColorsName(080)   = "limegreen":             HTMLColorsCode(080) = "32CD32"
        HTMLColorsName(081)   = "linen":                 HTMLColorsCode(081) = "FAF0E6"
        HTMLColorsName(082)   = "magenta":               HTMLColorsCode(082) = "FF00FF"
        HTMLColorsName(083)   = "maroon":                HTMLColorsCode(083) = "800000"
        HTMLColorsName(084)   = "mediumaquamarine":      HTMLColorsCode(084) = "66CDAA"
        HTMLColorsName(085)   = "mediumblue":            HTMLColorsCode(085) = "0000CD"
        HTMLColorsName(086)   = "mediumorchid":          HTMLColorsCode(086) = "BA55D3"
        HTMLColorsName(087)   = "mediumpurple":          HTMLColorsCode(087) = "9370D8"
        HTMLColorsName(088)   = "mediumseagreen":        HTMLColorsCode(088) = "3CB371"
        HTMLColorsName(089)   = "mediumslateblue":       HTMLColorsCode(089) = "7B68EE"
        HTMLColorsName(090)   = "mediumspringgreen":     HTMLColorsCode(090) = "00FA9A"
        HTMLColorsName(091)   = "mediumturquoise":       HTMLColorsCode(091) = "48D1CC"
        HTMLColorsName(092)   = "mediumvioletred":       HTMLColorsCode(092) = "C71585"
        HTMLColorsName(093)   = "midnightblue":          HTMLColorsCode(093) = "191970"
        HTMLColorsName(094)   = "mintcream":             HTMLColorsCode(094) = "F5FFFA"
        HTMLColorsName(095)   = "mistyrose":             HTMLColorsCode(095) = "FFE4E1"
        HTMLColorsName(096)   = "moccasin":              HTMLColorsCode(096) = "FFE4B5"
        HTMLColorsName(097)   = "navajowhite":           HTMLColorsCode(097) = "FFDEAD"
        HTMLColorsName(098)   = "navy":                  HTMLColorsCode(098) = "000080"
        HTMLColorsName(099)   = "oldlace":               HTMLColorsCode(099) = "FDF5E6"
        HTMLColorsName(100)   = "olive":                 HTMLColorsCode(100) = "808000"
        HTMLColorsName(101)   = "olivedrab":             HTMLColorsCode(101) = "6B8E23"
        HTMLColorsName(102)   = "orange":                HTMLColorsCode(102) = "FFA500"
        HTMLColorsName(103)   = "orangered":             HTMLColorsCode(103) = "FF4500"
        HTMLColorsName(104)   = "orchid":                HTMLColorsCode(104) = "DA70D6"
        HTMLColorsName(105)   = "palegoldenrod":         HTMLColorsCode(105) = "EEE8AA"
        HTMLColorsName(106)   = "palegreen":             HTMLColorsCode(106) = "98FB98"
        HTMLColorsName(107)   = "paleturquoise":         HTMLColorsCode(107) = "AFEEEE"
        HTMLColorsName(108)   = "palevioletred":         HTMLColorsCode(108) = "D87093"
        HTMLColorsName(109)   = "papayawhip":            HTMLColorsCode(109) = "FFEFD5"
        HTMLColorsName(100)   = "peachpuff":             HTMLColorsCode(100) = "FFDAB9"
        HTMLColorsName(111)   = "peru":                  HTMLColorsCode(111) = "CD853F"
        HTMLColorsName(112)   = "pink":                  HTMLColorsCode(112) = "FFC0CB"
        HTMLColorsName(113)   = "plum":                  HTMLColorsCode(113) = "DDA0DD"
        HTMLColorsName(114)   = "powderblue":            HTMLColorsCode(114) = "B0E0E6"
        HTMLColorsName(115)   = "purple":                HTMLColorsCode(115) = "800080"
        HTMLColorsName(116)   = "red":                   HTMLColorsCode(116) = "FF0000"
        HTMLColorsName(117)   = "rosybrown":             HTMLColorsCode(117) = "BC8F8F"
        HTMLColorsName(118)   = "royalblue":             HTMLColorsCode(118) = "4169E1"
        HTMLColorsName(119)   = "saddlebrown":           HTMLColorsCode(119) = "8B4513"
        HTMLColorsName(120)   = "salmon":                HTMLColorsCode(120) = "FA8072"
        HTMLColorsName(121)   = "sandybrown":            HTMLColorsCode(121) = "F4A460"
        HTMLColorsName(122)   = "seagreen":              HTMLColorsCode(122) = "2E8B57"
        HTMLColorsName(123)   = "seashell":              HTMLColorsCode(123) = "FFF5EE"
        HTMLColorsName(124)   = "sienna":                HTMLColorsCode(124) = "A0522D"
        HTMLColorsName(125)   = "silver":                HTMLColorsCode(125) = "C0C0C0"
        HTMLColorsName(126)   = "skyblue":               HTMLColorsCode(126) = "87CEEB"
        HTMLColorsName(127)   = "slateblue":             HTMLColorsCode(127) = "6A5ACD"
        HTMLColorsName(128)   = "slategray":             HTMLColorsCode(128) = "708090"
        HTMLColorsName(129)   = "snow":                  HTMLColorsCode(129) = "FFFAFA"
        HTMLColorsName(130)   = "springgreen":           HTMLColorsCode(130) = "00FF7F"
        HTMLColorsName(131)   = "steelblue":             HTMLColorsCode(131) = "4682B4"
        HTMLColorsName(132)   = "tan":                   HTMLColorsCode(132) = "D2B48C"
        HTMLColorsName(133)   = "teal":                  HTMLColorsCode(133) = "008080"
        HTMLColorsName(134)   = "thistle":               HTMLColorsCode(134) = "D8BFD8"
        HTMLColorsName(135)   = "tomato":                HTMLColorsCode(135) = "FF6347"
        HTMLColorsName(136)   = "turquoise":             HTMLColorsCode(136) = "40E0D0"
        HTMLColorsName(137)   = "violet":                HTMLColorsCode(137) = "EE82EE"
        HTMLColorsName(138)   = "violetred":             HTMLColorsCode(138) = "D02090"
        HTMLColorsName(139)   = "wheat":                 HTMLColorsCode(139) = "F5DEB3"
        HTMLColorsName(140)   = "white":                 HTMLColorsCode(140) = "FFFFFF"
        HTMLColorsName(141)   = "whitesmoke":            HTMLColorsCode(141) = "F5F5F5"
        HTMLColorsName(142)   = "yellow":                HTMLColorsCode(142) = "FFFF00"
        HTMLColorsName(143)   = "yellowgreen":           HTMLColorsCode(143) = "9ACD32"
        HTMLColors            = 143
        'Default page
        BarResize          = true
        PrintMode          = false
        PaintTimer.enabled = true
    eND CONSTRUCTOR
END TYPE

