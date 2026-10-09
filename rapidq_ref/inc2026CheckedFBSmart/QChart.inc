'==============================================================================================
'                           QChart:  A Charting Class for Rapid-Q
'                          Copyright (c) 2003-2004  Michael J. Zito
'                              Released under the LPGL License
'                                      Build 3.6.04
'==============================================================================================
'
'QChart provides a rich set of 2-D charting routines for Rapid-Q programmers.
'It generates histograms, bar charts, XY-scatter plots, line graphs, pie charts
'and box plots.  Each charting routine will calculate an appropriate scale and plot
'the data contained in the .Data or .XYData property of the object.  The user may optionally
'specify the scaling as well as fonts, grids or other properties (see code and HTML
'documentation). Once the data is formatted graphs can be called with a few lines
'of simple code. (See QChartEx.rqb for examples of setting up and calling each chart type.)
'
'   ----> To create an instance and call QChart:
'
'                  $INCLUDE "QChart.inc"
'                  CREATE YourInstanceName AS QChart
'                    Parent = QForm, QTabControl or QPanel
'                    Set any other desired properties of a QCanvas
'                  END CREATE
'                  WITH YourInstanceName
'                     .Initialize
'                     .ChartType = ctXXXX
'                     .ChartStyle = csXXXX
'                ---->Change Any Desired Properties (See code or HTML Documentation)
'                ---->REDIM .Data array property (See below)
'                ---->Load Data Into .LabelList, .LegendList and .Data Array
'                     .DrawChart (Overlay T or F)
'                  END WITH
'
'   NOTE: There is little error checking in this class.  It is up to the user
'         to insure that the data is formatted properly before calling each routine.
'
'   LegendList and LabelList are implemented as QStringLists.
'       *Use the .AddItems Method of each property to add text to the lists.
'       *LegendList contains legend text and usually refers to the Cols (i.e. Series)
'       *LabelList contains text used to label the X Axis and usually refers to Rows
'           (i.e. Categories).  LabelList items are NOT USED by XY Charts
'
'   The .Data property is a 2 dimensional array of DOUBLE which must be REDIMd by the user
'       prior to filling the grid with data.  The first dim is Cols and the second is Rows.
'       Each Col represents a series to be plotted.  The Rows represent the data values
'       within each series. Use the .Data property for all charts EXCEPT XY Charts.
'
'   XY Charts have their own data array.
'       The .XYData property is a 3 dimensional array of DOUBLE. The first dim is Cols and the
'       second is Rows. The third dim is ALWAYS 2. Each Col represents a series to be plotted.
'       The Rows represent the number of XY data pairs within each series.  The third dimension
'       refers to the X and Y data values for each point to be plotted: 1 = X and 2 = Y values
'
'   ----> To REDIM the .Data or .XYData array property:
'
'   You MUST set the .Cols and .Rows properties before calling QChart.  These values are used
'   throughout the QChart class as loop counters. Set .Cols to number of series to be plotted
'   and set .Rows to number of values in each series. REDIM the array using .Cols and .Rows.
'
'   NOTE:  To REDIM you MUST EXPLICITLY REFERENCE your QChart instance by name (even inside a
'          WITH block) or RapidQ will not find and REDIM the array.  (A RapidQuirk?!?)
'
'             WITH YourInstanceName
'               .Cols = 2                                       <-- Num series
'               .Rows = 2                                       <-- Num values in each series
'               REDIM YourInstanceName.Data(.Cols, .Rows)       <-- for all EXCEPT XY Charts
'               REDIM YourInstanceName.XYData(.Cols, .Rows, 2)  <-- for XY Charts
'             END WITH
'
'   ----> Sample Data Formats (given the DIMs above):
'
'              XY Charts                                All Other Charts
'         =====================                         ================
'         Series  NumPts Values                          Series  Values
'         (Col)   (Row)  (dim 3)                         (Col)   (Row)
'           1       1       1 <-- X                        1     val 11
'           1       1       2 <-- Y                        1     val 12
'           1       2       1                              2     val 21
'           1       2       2                              2     val 22
'           2       1       1
'           2       1       2
'           2       2       1
'           2       2       2
'
'   Box Plots             HiLo Plots           Pie Charts       BarLine Plots
'  (5 rows only)         (3 rows only)        (1 Col only)      (2 Cols only)
'==================   ====================  ================  ==================
' Row  1 = Max          Row   1 = Hi          Col     Row       Col 1    Col 2
'      2 = Q3                 2 = Close     =======  =======   =======  =======
'      3 = Median             3 = Lo           1       1         Bar      Line
'      4 = Q1                                  1       2         Data     Data
'      5 = Min                                 1       n
'==============================================================================================

'----- Compiler Directives
$IFNDEF TRUE
  $DEFINE TRUE 1
$ENDIF
$IFNDEF FALSE
  $DEFINE FALSE 0
$ENDIF

'----- Win API Functions
DECLARE FUNCTION qcCreatePen LIB "gdi32" ALIAS "CreatePen" (nPenStyle AS LONG, nWidth AS LONG, crColor AS LONG)_
                                                            AS LONG
DECLARE FUNCTION qcCreateSolidBrush LIB "gdi32" ALIAS "CreateSolidBrush" (BYVAL crColor AS LONG) AS LONG
DECLARE FUNCTION qcCreateHatchBrush LIB "gdi32" ALIAS "CreateHatchBrush" (nIndex AS LONG, crColor AS LONG)_
                                                                          AS LONG
DECLARE FUNCTION qcSelectObject LIB "gdi32" ALIAS "SelectObject" (hdc AS LONG,hObject AS LONG) AS LONG
DECLARE FUNCTION qcDeleteObject LIB "gdi32" ALIAS "DeleteObject" (hObject AS LONG) AS LONG
DECLARE FUNCTION qcSetBkColor LIB "gdi32" ALIAS "SetBkColor" (hdc AS LONG, crColor AS LONG) AS LONG
DECLARE FUNCTION qcMoveToEx LIB "gdi32" ALIAS "MoveToEx" (hdc AS LONG,x AS LONG,y AS LONG, lpPoint AS LONG)_
                                                          AS LONG
DECLARE FUNCTION qcLineTo LIB "gdi32" ALIAS "LineTo" (hdc AS LONG,x AS LONG,y AS LONG) AS LONG
DECLARE FUNCTION qcRectangle LIB "gdi32" ALIAS "Rectangle" (hdc AS LONG, X1 AS LONG, Y1 AS LONG, _
                                                            X2 AS LONG, Y2 AS LONG) AS LONG
DECLARE FUNCTION qcPie LIB "gdi32" ALIAS "Pie" (BYVAL hdc AS LONG, BYVAL X1 AS LONG, BYVAL Y1 AS LONG,_
                                                BYVAL X2 AS LONG, BYVAL Y2 AS LONG, BYVAL X3 AS LONG,_
                                                BYVAL Y3 AS LONG, BYVAL X4 AS LONG, BYVAL Y4 AS LONG)_
                                                AS LONG
DECLARE FUNCTION qcGetCurrentObjectBmp LIB "gdi32" ALIAS "GetCurrentObject" (hdc AS LONG,uObjectType AS LONG)_
                                                                             AS LONG

'----- PRIVATE QChart FUNCTIONs
DECLARE FUNCTION qcLog10 (Value AS DOUBLE) AS DOUBLE
DECLARE FUNCTION RowTotal (Row AS INTEGER) AS DOUBLE
DECLARE FUNCTION ColTotal (Col AS INTEGER) AS DOUBLE

'----- PRIVATE QChart SUBs
DECLARE SUB ClearBuffer
DECLARE SUB SetSize
DECLARE SUB ScaleAxis (Mn AS DOUBLE, Mx AS DOUBLE, Axis AS INTEGER)
DECLARE SUB SetScale (Start AS INTEGER, Finish AS INTEGER)
DECLARE SUB SetSeries
DECLARE SUB DrawAxes
DECLARE SUB DrawTitles
DECLARE SUB DrawLabels
DECLARE SUB DrawMarker (x1 AS SINGLE,y1 AS SINGLE,MrkrStyle AS INTEGER,COLOR AS LONG,Lgd AS BYTE)
DECLARE SUB DrawLegend
DECLARE SUB DrawBar (Overlay AS INTEGER, ColNum AS INTEGER)
DECLARE SUB DrawXY (Overlay AS INTEGER)
DECLARE SUB DrawLine (Overlay AS INTEGER, ColNum AS INTEGER)
DECLARE SUB DrawBox (Overlay AS INTEGER)
DECLARE SUB DrawPie (Overlay AS INTEGER)
DECLARE SUB DrawHiLo (Overlay AS INTEGER)
DECLARE SUB DrawReal (Overlay AS INTEGER)

'----- PUBLIC QChart Methods
DECLARE SUB Initialize
DECLARE SUB PaintChart
DECLARE SUB ClearAll
DECLARE SUB DrawChart (Overlay AS INTEGER)
DECLARE SUB RedrawChart
DECLARE SUB CopyToClipboard (Wid AS INTEGER, Hgt AS INTEGER)
DECLARE SUB SaveChart (SaveAs AS BYTE)
DECLARE SUB SaveToFile (FileName AS String)

DECLARE SUB PrintChart (Prn AS INTEGER, Orient AS INTEGER, Margin AS INTEGER,_
                        Copies AS INTEGER, Colr AS BYTE)

'----- UDTs
TYPE AxisType
  LEN           AS SINGLE               'Axis length in pixels
  Ori           AS SINGLE               'Logical Origin in pixels
  Min           AS DOUBLE               'Minimum scale value
  Max           AS DOUBLE               'Maximum scale value
  Div           AS INTEGER              'Number of divisions on axis
  ScaleFactor   AS DOUBLE               'Factor for scaling values on axis
  AutoScale     AS BYTE                 'TRUE = QChart scales, FALSE = User supplies Min/Max
  COLOR         AS LONG                 'Color of axis
  Grid          AS BYTE                 'TRUE = Draw Grid, FALSE = No Grid
  Labeled       AS BYTE                 'TRUE = Label the Axis, FALSE = No Axis Labels
  Zero          AS SINGLE               'Location of zero in Pixels
  DrawZero      AS BYTE                 'TRUE = Draw Zero Line, FALSE = No Zero Line
  ZeroColor     AS LONG                 'Color of Zero Line
  Tics          AS BYTE                 'TRUE = Draw Tic Marks, FALSE = No Tic Marks
  MnrTics       AS BYTE                 'TRUE = Draw Minor Tic Marks, FALSE = No Tic Marks
  STEP          AS DOUBLE               'Step increment value of each tic
  TicIntvl      AS DOUBLE               'Distance between tics in world coordinates
  TicLen        AS SINGLE               'Size of tic mark in Pixels
  LogScale      AS BYTE                 'TRUE = Log Scalin, FALSE = Linear Scaling
END TYPE

TYPE TitleType
  Top           AS INTEGER
  Left          AS INTEGER
  Text          AS STRING * 75
END TYPE

TYPE SeriesType
  AutoColor     AS BYTE                 'Cycle available colors (T/F)
  COLOR         AS LONG                 'Color to use
  AutoMark      AS BYTE                 'Cycle available markers (T/F)
  Marker        AS BYTE                 'Marker style to use
  HatchStyle    AS LONG                 'Hatch Pattern to Use for Bars and Boxes
  LineStyle     AS LONG                 'Line Style to use
  LineWidth     AS LONG                 'Line Width to use
END TYPE

'----- Win API Constants
CONST lsSolid=0                         'line styles
CONST lsDash=1
CONST lsDot=2
CONST lsDashDot=3
CONST lsDashDotDot=4
                                        'hatch styles
CONST hsHoriz = 0                       '  -----
CONST hsVert = 1                        '  |||||
CONST hsFDiag = 2                       '  \\\\\
CONST hsBDiag = 3                       '  /////
CONST hsCross = 4                       '  +++++
CONST hsXDiag = 5                       '  xxxxx
CONST hsSolid = -1

'----- QChart Constants
CONST ctBar = 0                         'Chart Type Flags
CONST ctLine = 1
CONST ctBarLine = 2
CONST ctBox = 3
CONST ctPie = 4
CONST ctHiLo = 5
CONST ctXY = 6
CONST ctReal = 7


CONST csHisto = 0                       'Bar Chart Style Flags
CONST csBar = 1
CONST csStacked = 2
CONST csPctStacked = 3

CONST csPoints = 4                      'XY and Line Chart Style Flags
CONST csLines = 5
CONST csBoth =6

CONST csAntenna = 7                     'Hi Lo Style flag
CONST csHiLoBox = 8

CONST csPiePct = 9                      'Pie Chart Style Flags
CONST csPieVal = 10

CONST msFillCircle = 1                  'Marker Style Flags
CONST msFillSquare = 2
CONST msFillTriangleUp = 3
CONST msFillTriangleDown = 4
CONST msCircle = 5
CONST msSquare = 6
CONST msTriangleUp = 7
CONST msTriangleDown = 8

CONST MaxSeries = 26                    'Maximum Number of Series that can be plotted

'----- Begin Object Definition ***********************************************************
TYPE QCHART EXTENDS QCANVAS

'---- Properties
  PRIVATE:
    Success             AS BYTE                 'TRUE or FALSE; set in log routines
    Printing            AS BYTE                 'TRUE or FALSE; Update w/o screen redraw
    hPen                AS LONG                 'Handle to current pen
    OldPen              AS LONG                 'Handle to last used pen
    hBrush              AS LONG                 'Handle to current brush
    OldBrush            AS LONG                 'Handle to last used brush
    Buffer              AS QBITMAP              'Offscreen drawing buffer
    CurrFile            AS STRING               'FileName of Current Chart

  PUBLIC:
    Data(1,1)           AS DOUBLE               'Data array Dims: 1=grp(cols), 2=values(rows)
    XYData(1,1,2)       AS DOUBLE               'XYData array Dims:1=grp, 2=values,3: 1=x,2=y
    Cols                AS INTEGER              'Num series (used to set array dim 1)
    Rows                AS INTEGER              'Num values in each series (used to set array dim 2)
    LegendList          AS QSTRINGLIST          'Holds Legend text
    LabelList           AS QSTRINGLIST          'Holds X Axis Label text
    XAxis               AS AxisType             'X-axis options
    YAxis               AS AxisType             'Y-axis options
    Series(MaxSeries)   AS SeriesType           'Series style info
    bgColor             AS LONG                 '!!! background color
    fgColor             AS LONG                 '!!! foreground color
    ChartType           AS BYTE                 'ctBar, ctXY, ctBox etc...
    ChartStyle          AS BYTE                 'csHisto, csLines, csPoints, csBoth etc...
    MainTitle           AS TitleType            'MainTitle Text and Location
    MainFont            AS QFONT
    SubTitle            AS TitleType            'SubTitle Text and Location
    SubFont             AS QFONT
    XTitle              AS TitleType            'X Axis Title Text and Location
    YTitle              AS TitleType            'Y Axis Title Text and Location
    AxisLbl             AS TitleType            'Axis Label Text and Location
    AxisFont            AS QFONT
    DoLegend            AS BYTE                 'TRUE = Draw Legend, FALSE = No Legend
    Legend              AS TitleType            'Legend Text and Location
    LegendFont          AS QFONT
    ChartBorder         AS BYTE                 'TRUE = Draw Frame around entire chart, FALSE = No Frame
    AxisBorder          AS BYTE                 'TRUE = Draw Frame around Plot Area, FALSE = No Frame
    Colors(30)          AS LONG                 'Array of colors; QChart chooses colors from this array
    PlotAreaColor       AS LONG                 '!!! Color of plot area background
    GridColor           AS LONG                 '!!! Color of grid lines
    dlgSaveQC           AS QSAVEDIALOG
    MarkerSize          AS SINGLE               'Sets size of drawn markers
    BW                  AS BYTE                 'TRUE = Use BW only, FALSE = Cycles Colors() array
    GreyScale           AS BYTE                 'TRUE = Use GreyScale, FALSE = Cycles Colors() array
    ChartExists         AS BYTE                 'TRUE or FALSE
    Viewport            AS INTEGER              'Viewport width for Real Time graphs
    Missing             AS DOUBLE               'Value used to test for missing data


'------------------------------------------------------------------------------------------
'------------------------- Private Functions ----------------------------------------------
'------------------------------------------------------------------------------------------
PRIVATE:
  FUNCTION RowTotal (Row AS INTEGER) AS DOUBLE

    DIM i AS INTEGER
    DIM Sum AS SINGLE

    WITH QCHART
      Sum = 0
      FOR i = 1 TO .Cols
        IF .Data(i,Row) <> .Missing THEN
          Sum = Sum + ABS(.Data(i,Row))
        END IF
      NEXT
    END WITH
    RowTotal = Sum

  END FUNCTION
'------------------------------------------------------------------------------------------
PRIVATE:
  FUNCTION ColTotal (Col AS INTEGER) AS DOUBLE

    DIM i AS INTEGER
    DIM Sum AS SINGLE

    WITH QCHART
      Sum = 0
      FOR i = 1 TO .Rows
        IF .Data(Col,i) <> .Missing THEN
          Sum = Sum + ABS(.Data(Col,i))
        END IF
      NEXT
    END WITH
    ColTotal = Sum

  END FUNCTION
'------------------------------------------------------------------------------------------
PRIVATE:
  FUNCTION qcLog10 (Value AS DOUBLE) AS DOUBLE

    IF Value > 0 THEN
      qcLog10 = LOG(Value) / LOG(10)
    ELSE
      MESSAGEDLG("qcLog10: Log of Value <= 0 Undefined", 1, 4, 0)
      QCHART.Success = FALSE
      EXIT FUNCTION
    END IF

  END FUNCTION
'------------------------------------------------------------------------------------------
PRIVATE:
  SUB ClearBuffer                       'Erase off screen drawing buffer

    WITH QCHART.Buffer
      .FillRect(0, 0, .Width, .Height, QCHART.bgColor) 'QCHART.bgColor
    END WITH
    QCHART.ChartExists = FALSE          'Set flag

  END SUB
'------------------------------------------------------------------------------------------
'------------------------- Public Methods -------------------------------------------------
'------------------------------------------------------------------------------------------
PUBLIC:
  SUB Initialize                        'Sets default values, make global changes here

    DIM i AS INTEGER                    'Loop Counters
    DIM j AS INTEGER

    WITH QCHART

      .Buffer.Width =     .ClientWidth
      .Buffer.Height =    .ClientHeight

      '.bgColor =   .bgColor '       .Colors(30)   'Bright White
      '.fgColor =   QCHART.fgColor '        .Colors(0)    'Black
      '.PlotAreaColor = QCHART.PlotAreaColor'   .Colors(29)   'Light Grey
      '.GridColor =  QCHART.GridColor'      .Colors(27)   'Dark Grey

      .ChartExists =      FALSE
      .Success =          TRUE
      .ChartBorder =      TRUE
      .AxisBorder =       TRUE
      .MarkerSize =       3
      .BW =               FALSE
      .GreyScale =        FALSE
      .DoLegend =         TRUE
      .Printing =         FALSE

      .XAxis.Div =        10
      .XAxis.AutoScale =  TRUE
      .XAxis.Labeled =    TRUE
      .XAxis.Tics =       TRUE
      .XAxis.MnrTics =    TRUE
      .XAxis.Grid =       TRUE
      .XAxis.DrawZero =   TRUE
      .XAxis.LogScale =   FALSE
      .XAxis.COLOR =      0
      .XAxis.ZeroColor =  QCHART.Colors(20)'Red

      .YAxis.Div =        10
      .YAxis.AutoScale =  TRUE
      .YAxis.Labeled =    TRUE
      .YAxis.Tics =       TRUE
      .YAxis.MnrTics =    TRUE
      .YAxis.Grid =       TRUE
      .YAxis.DrawZero =   TRUE
      .YAxis.LogScale =   FALSE
      .YAxis.COLOR =      0
      .YAxis.ZeroColor =  QCHART.Colors(20)'Red

      .MainFont.Name =    "Times New Roman"
      .MainFont.Size =    18
      .MainFont.COLOR =   QCHART.Colors(0)
      .MainFont.AddStyles(0)            'Bold

      .SubFont.Name =     "Times New Roman"
      .SubFont.Size =     12
      .SubFont.COLOR =    QCHART.Colors(0)
      .SubFont.AddStyles(0)            'Bold

      .AxisFont.Name =    "Times New Roman"
      .AxisFont.Size =    10
      .AxisFont.COLOR =   QCHART.Colors(0)

      .LegendFont.Name =  "Times New Roman"
      .LegendFont.Size =  9
      .LegendFont.COLOR = QCHART.Colors(0)

      FOR i = 1 TO MaxSeries            'Set Series Defaults
        .Series(i).AutoColor =  TRUE
        .Series(i).COLOR =      .fgColor
        .Series(i).AutoMark =   TRUE
        .Series(i).Marker =     msFillCircle
        .Series(i).HatchStyle = hsSolid
        .Series(i).LineStyle =  lsSolid
        .Series(i).LineWidth =  1
      NEXT

      .MainTitle.Text =   ""            'Clear preexisting data
      .SubTitle.Text =    ""
      .XTitle.Text =      ""
      .YTitle.Text =      ""

      .LegendList.Clear
      .LabelList.Clear

      SELECT CASE .ChartType            'Only clear 1st data point for speed
        CASE ctXY                       'assumes caller will overwrite the rest
          .XYData(1,1,1) = .Missing
          .XYData(1,1,2) = .Missing
        CASE ELSE
          .Data(1,1) = .Missing
      END SELECT
      .Cols = 1                         'Set to minimum size
      .Rows = 1

      .ChartType = ctXY                 'Set default chart type and style
      .ChartStyle = csPoints

      .CurrFile = "NewChart.bmp"

    END WITH

  END SUB
'------------------------------------------------------------------------------------------
PUBLIC:
  SUB PaintChart                        'Assign this to the QChart.OnPaint Event
                                        'Draws Buffer.BMP to Canvas
    WITH QCHART
      .Draw(0, 0, .Buffer.BMP)
    END WITH

  END SUB
'------------------------------------------------------------------------------------------
PUBLIC:
  SUB ClearAll

    WITH QCHART
      .Initialize
      .ClearBuffer
      .PaintChart
    END WITH

  END SUB
'------------------------------------------------------------------------------------------
'------------------------- Private Methods ------------------------------------------------
'------------------------------------------------------------------------------------------
PRIVATE:
  SUB SetSize

    DIM i AS INTEGER
    DIM LegendLen AS INTEGER

    WITH QCHART                         'Set Origin and Axis Lengths
                                        'relative to window and font sizes
      .Buffer.Font = .AxisFont
      .XAxis.Ori = .Buffer.TextWidth("8") * 16
      IF .ChartType = ctPie THEN        'Leave room for right wedge labels
        .Xaxis.Ori = .XAxis.Ori / 2
      END IF
      IF RTRIM$(.YTitle.Text) = "" THEN 'Y Axis is not labeld
        .Xaxis.Ori = .XAxis.Ori / 1.5   'X Axis can start farther left
      END IF

      IF .DoLegend = FALSE THEN         'Make X Axis larger
        .XAxis.LEN = .Buffer.Width - .XAxis.Ori * 1.5
      ELSE                              'Leave room for Legend
        .Buffer.Font = .LegendFont
        LegendLen = 0
        FOR i = 0 TO .LegendList.ItemCount-1     'Get the longest legend text
          IF .Buffer.TextWidth(.LegendList.Item(i)) > LegendLen THEN
            LegendLen = .Buffer.TextWidth(.LegendList.Item(i))
          END IF
        NEXT i
        LegendLen = LegendLen + .Buffer.TextWidth("WWWWI")'Pad for marker space
        .XAxis.LEN = .Buffer.Width - (.XAxis.Ori + LegendLen)
      END IF

      .Buffer.Font = .AxisFont
      .YAxis.Ori = .Buffer.Height - .Buffer.TextHeight(.XTitle.Text) * 5
      IF .ChartType = ctPie OR RTRIM$(.XTitle.Text) = "" THEN 'X Axis not labeled
        .YAxis.Ori = .Buffer.Height - .Buffer.TextHeight(.XTitle.Text) * 3
      END IF

      .YAxis.LEN = .YAxis.Ori - 20          'Minimum border
      IF RTRIM$(.MainTitle.Text) <> "" THEN 'Make room for Main Title
        .Buffer.Font = .MainFont
        .YAxis.LEN = .YAxis.LEN  - .Buffer.TextHeight(.MainTitle.Text)
      END IF
      IF RTRIM$(.SubTitle.Text) <> "" THEN  'Make room for Sub Title
        .Buffer.Font = .SubFont
        .YAxis.LEN = .YAxis.LEN  - .Buffer.TextHeight(.SubTitle.Text)
      END IF

    END WITH

  END SUB
'------------------------------------------------------------------------------------------
PRIVATE:
  SUB ScaleAxis (Mn AS DOUBLE, Mx AS DOUBLE, Axis AS INTEGER)

    DIM prec AS DOUBLE
    DIM Incr AS DOUBLE
    DIM Div AS INTEGER
    DIM Range AS DOUBLE
    DIM i AS INTEGER
    DIM j AS DOUBLE
    DIM Test AS DOUBLE
    DIM pwr AS INTEGER
    DIM LMn1 AS DOUBLE
    DIM LMn2 AS DOUBLE
    DIM LMx1 AS DOUBLE
    DIM LMx2 AS DOUBLE
    DIM SclMn AS DOUBLE
    DIM SclMx AS DOUBLE

    WITH QCHART

      IF Axis = 0 THEN Div = .XAxis.Div ELSE Div = .YAxis.Div 'Set values for desired axis

      IF Mx <= Mn THEN Mx = Mn + 1
      Range = Mx - Mn
      IF Mn >= 0 THEN
        Mn = 0
      ELSE
        Mn = Mn - Range * .01               'Prevent plotting points on chart border
      END IF
      IF Mx <= 0 THEN
        Mx = 0
      ELSE
        Mx = Mx + Range * .01               'Prevent plotting points on chart border
      END IF

      prec = .00002
      Range = (Mx - Mn) / Div
      pwr = FIX(.qcLog10(Range))
      IF Range < 1 THEN pwr = pwr - 1

      Incr = Range / (10^pwr)               'Calculate an even increment
      FOR j = 1 TO 5
        IF Incr < j + prec THEN EXIT FOR
      NEXT j

      FOR i  = j TO 20
        Test = i * 10^pwr

        LMn1 = Mn / Test
        LMn2 = FIX(LMn1)
        IF LMn1 < 0 THEN LMn2 = LMn2 - 1
        IF ABS(LMn2 + 1 - LMn1) < prec THEN LMn2 = LMn2 + 1
        SclMn = Lmn2 * Test

        LMx1 = Mx / Test
        LMx2 = FIX(LMx1 + 1)
        IF LMx1 < -1 THEN LMx2 = LMx2 - 1
        IF ABS(LMx1 + 1 - LMx2) < Prec THEN LMx2 = LMx2 - 1
        SclMx = LMx2 * Test

        Range = LMx2 - LMn2
        IF Range <= Div THEN EXIT FOR
      NEXT i

      Range = (Div - Range) / 2             'Set Scale min and max
      SclMn = SclMn - Range * Test
      SclMx = SclMn + Div * Test

      IF SclMn > Mn THEN SclMn = Mn         'Prevent errors
      IF SclMx < Mx THEN SclMx = Mx

      IF Mn >= 0 AND SclMn < 0 THEN         'Remove divisions where no data plotted
        SclMx = SclMx - SclMn               'so data takes up most of chart
        IF SclMx > Mx THEN
          Range = SclMx / Div
          WHILE SclMx > Mx + Range * 1.01
            SclMx = SclMx - Range
            Div = Div - 1
          WEND
        END IF
        SclMn = 0
      END IF

      IF Mx <= 0 AND SclMx > 0 THEN
        SclMn = SclMn - SclMx
        IF SclMn < Mn THEN
          Range = SclMn / Div
          WHILE SclMn < Mn + Range * 1.01
            SclMn = SclMn - Range
            Div = Div - 1
          WEND
        END IF
        SclMx = 0
      END IF

      IF sclMn * sclMx < 0 THEN
        Range = (SclMx - SclMn) / Div
        IF SclMn < Mn THEN
          WHILE SclMn < Mn - Range * 1.01
            SclMn = SclMn + Range
            Div = Div - 1
          WEND
        END IF
        IF SclMx > Mx THEN
          WHILE SclMx > Mx + Range * 1.01
            SclMx = SclMx - Range
            Div = Div - 1
          WEND
        END IF
      END IF

      SELECT CASE Axis
        CASE 0                              'Assign values to the X Axis
          .XAxis.Min = SclMn
          .XAxis.Max = SclMx
          .XAxis.Div = Div
          .XAxis.STEP = (SclMx - SclMn) / Div
        CASE ELSE                           'Assign values to the Y Axis
          .YAxis.Min = SclMn
          .YAxis.Max = SclMx
          .YAxis.Div = Div
          .YAxis.STEP = (SclMx - SclMn) / Div
      END SELECT

    END WITH

  END SUB
'------------------------------------------------------------------------------------------
PRIVATE:
  SUB SetScale (Start AS INTEGER, Finish AS INTEGER)

    DIM i    AS INTEGER                               'Loop counters...
    DIM j    AS INTEGER
    DIM XMax AS DOUBLE
    DIM XMin AS DOUBLE
    DIM YMax AS DOUBLE
    DIM YMin AS DOUBLE
    DIM Test AS DOUBLE
    XMax = -1e40                                      'Start Small
    XMin = 1e40                                       'Start Big
    YMax = -1e40                                      'Ditto
    YMin = 1e40

    WITH QCHART

      SELECT CASE .ChartType
        CASE ctXY
          IF .XAxis.AutoScale = TRUE THEN             'Find  X Data Min and Max
            FOR i = 1 TO .Cols
              FOR j = Start TO Finish'1 TO .Rows
                IF .XYData(i,j,1) <> .Missing THEN
                  Test = .XYData(i,j,1)
                  IF Test < XMin THEN XMin = Test
                  IF Test > XMax THEN XMax = Test
                END IF
              NEXT j
            NEXT i
          END IF

          IF .YAxis.AutoScale = TRUE THEN             'Find Y Data Min and Max
            FOR i = 1 TO .Cols
              FOR j = Start TO Finish'1 TO .Rows
                IF .XYData(i,j,2) <> .Missing THEN
                  Test = .XYData(i,j,2)
                  IF Test < YMin THEN YMin = Test
                  IF Test > YMax THEN YMax = Test
                END IF
              NEXT j
            NEXT i
          END IF

        CASE ELSE                                     'ctBar, ctLine, ctBox, ctHiLo
          IF .YAxis.AutoScale = TRUE THEN             'Find Data Min and Max
            SELECT CASE .ChartStyle

              CASE csPctStacked
                .YAxis.Min = 0
                .YAxis.Max = 100
                .YAxis.STEP = 10
                .YAxis.ScaleFactor = .YAxis.LEN / 100
                EXIT SUB

              CASE csStacked
                FOR i = Start TO Finish'1 TO .Rows
                  Test = .RowTotal(i)
                  IF Test < YMin THEN YMin = Test
                  IF Test > YMax THEN YMax = Test
                NEXT i

              CASE ELSE
                FOR i = 1 TO .Cols
                  FOR j = Start TO Finish'1 TO .Rows
                    IF .Data(i,j) <> .Missing THEN
                      Test = .Data(i,j)
                      IF Test < YMin THEN YMin = Test
                      IF Test > YMax THEN YMax = Test
                    END IF
                  NEXT j
                NEXT i

            END SELECT
          END IF

      END SELECT

      SELECT CASE .YAxis.LogScale
        CASE FALSE
          IF .YAxis.AutoScale = TRUE THEN
            .ScaleAxis (YMin, YMax, 1)
          ELSE                                    'Set step with user supplied min and max
            IF .YAxis.Div < 1 THEN .YAxis.Div = 1
            .YAxis.STEP = (.YAxis.Max - .YAxis.Min) / .YAxis.Div
          END IF
          .YAxis.ScaleFactor = .YAxis.LEN / (.YAxis.Max - .YAxis.Min)
          .YAxis.Zero = .YAxis.Ori + .YAxis.Min * .YAxis.ScaleFactor
        CASE TRUE                                 'See below for explanantion
          .YAxis.Min = FLOOR(.qcLog10(YMin))
          .YAxis.Max = CEIL(.qcLog10(YMax))
          .YAxis.Div = (.YAxis.Max - .YAxis.Min)
          .YAxis.ScaleFactor = .YAxis.LEN / .YAxis.Div
          .YAxis.TicIntvl = .YAxis.ScaleFactor
      END SELECT

      IF .ChartType <> ctXY THEN EXIT SUB         'If not XY no Values on X Axis so Bail!

      SELECT CASE .XAxis.LogScale
        CASE FALSE
          IF .XAxis.AutoScale = TRUE THEN
            .ScaleAxis (XMin, XMax, 0)
          ELSE                                    'Set step with user supplied min and max
            IF .XAxis.Div < 1 THEN .XAxis.Div = 1
            .XAxis.STEP = (.XAxis.Max - .XAxis.Min) / .XAxis.Div
          END IF
          .XAxis.ScaleFactor = .XAxis.LEN / (.XAxis.Max - .XAxis.Min)
          .XAxis.Zero = .XAxis.Ori - .XAxis.Min * .XAxis.ScaleFactor
        CASE TRUE                                 'Log Scale
          .XAxis.Min = FLOOR(.qcLog10(XMin))      'Set Min to Lower power of ten
          .XAxis.Max = CEIL(.qcLog10(XMax))       'Set Max to Greater power of ten
          .XAxis.Div = (.XAxis.Max - .XAxis.Min)  'Div = # of Log Cycles
          .XAxis.ScaleFactor = .XAxis.LEN / .XAxis.Div
          .XAxis.TicIntvl = .XAxis.ScaleFactor
      END SELECT

    END WITH

  END SUB
'------------------------------------------------------------------------------------------
PRIVATE:
  SUB SetSeries                              'Set up series colors and marker types

    DIM i AS INTEGER
    DIM Grey AS INTEGER
    DIM NumShades AS INTEGER
    DIM White AS INTEGER

    WITH QCHART

      SELECT CASE .ChartType
        CASE ctBar, ctBox, ctPie, ctHiLo
          NumShades = 5
          White = 1
        CASE ELSE
          NumShades = 4
          White = -1
      END SELECT

      FOR i = 1 TO .Cols
        IF .Series(i).AutoMark=TRUE THEN .Series(i).Marker = (i-1) MOD 8 + 1
        IF .Series(i).AutoColor=TRUE THEN
          .Series(i).COLOR = .Colors((i) MOD (UBOUND(QCHART.Colors) + White))
        END IF
        IF .GreyScale = TRUE THEN
          Grey = ((i-1) MOD NumShades) * 63
          .Series(i).COLOR = RGB(Grey,Grey,Grey)
        END IF
        IF .BW = TRUE THEN .Series(i).COLOR = i
        IF .BW = TRUE OR .GreyScale = TRUE THEN
          .YAxis.ZeroColor = .Colors(0)
          .XAxis.ZeroColor = .Colors(0)
        END IF
      NEXT
    END WITH
  END SUB
'---------------------------------------------------------------------------------------
PRIVATE:
  SUB DrawAxes

    DIM i  AS INTEGER                               'Loop counters...
    DIM j  AS INTEGER
    DIM x1 AS SINGLE                                'for readability
    DIM y1 AS SINGLE
    DIM x2 AS SINGLE
    DIM y2 AS SINGLE

    WITH QCHART

      x1 = 2                                        'Draw a frame around entire chart
      y1 = 2
      x2 = .Buffer.Width - 2
      y2 = .Buffer.Height - 2
      IF .ChartBorder = TRUE THEN .Buffer.Rectangle (x1, y1, x2, y2, .fgColor)

      IF .ChartType = ctPie THEN EXIT SUB           'No Axes for Pie Charts

      x1 = .XAxis.Ori                               'Draw a box around Plot Area
      y1 = .YAxis.Ori
      x2 = .XAxis.Ori + .XAxis.LEN
      y2 = .YAxis.Ori - .YAxis.LEN
      IF .AxisBorder = TRUE THEN
        .Buffer.Rectangle (x1, y1, x2 + 1, y2, .GridColor)
        .Buffer.FillRect (x1 + 1, y1 + 1, x2, y2 + 1, .PlotAreaColor)
      END IF

      IF .XAxis.Tics = TRUE THEN                    'Set Tic Size
         .XAxis.TicLen = .YAxis.LEN * .01
      ELSE
         .XAxis.TicLen = 0
      END IF

      IF .XAxis.Grid = TRUE THEN                    'Draw a grid and tics
         y1 = .YAxis.Ori + .XAxis.TicLen
         y2 = .YAxis.Ori - .YAxis.LEN
      ELSE                                          'Draw Tics only
         y1 = .YAxis.Ori + .XAxis.TicLen
         y2 = .YAxis.Ori - .Xaxis.TicLen
      END IF

      IF .XAxis.LogScale = FALSE THEN               'draw linear grid lines
        IF .XAxis.Div < 1 THEN .XAxis.Div = 1       'Avoid division by zero
        .XAxis.TicIntvl = .XAxis.LEN / .XAxis.Div
        FOR i = 0 TO .XAxis.Div
          x1 = .XAxis.Ori + .XAxis.TicIntvl * i
          x2 = x1
          .Buffer.Line (x1,y1,x2,y2,.GridColor)
        NEXT
        IF .ChartType = ctXY AND .XAxis.MnrTics = TRUE THEN
          y1 = .YAxis.Ori - .XAxis.TicLen / 2
          y2 = .YAxis.Ori + .XAxis.TicLen / 2
          FOR i = 0 TO .XAxis.Div - 1
            FOR j = 1 TO 4
              x1 = .XAxis.Ori + .XAxis.TicIntvl * i + .XAxis.TicIntvl/5 * j
              x2 = x1
              .Buffer.Line (x1,y1,x2,y2,.GridColor)
            NEXT
          NEXT
        END IF
      ELSE                                          'draw log grid lines
        FOR i = .XAxis.Min TO .XAxis.Max - 1
          FOR j  = 1 TO 9
            x1 = .XAxis.Ori + (.qcLog10(10 ^ i * j) - .XAxis.Min) * .XAxis.ScaleFactor
            x2 = x1
            .Buffer.Line (x1,y1,x2,y2,.GridColor)
          NEXT j
        NEXT i
        .Buffer.Line (.XAxis.Ori+.XAxis.LEN,y1,.XAxis.Ori+.XAxis.LEN,y2,.GridColor)
      END IF

      IF .YAxis.Tics = TRUE THEN                    'Set Tic Size
        .YAxis.TicLen = .XAxis.LEN * .01
      ELSE
        .YAxis.TicLen = 0
      END IF

      IF .YAxis.Grid = TRUE THEN                    'Draw a grid and tics
        x1 = .XAxis.Ori - .YAxis.TicLen
        x2 = .XAxis.Ori + .XAxis.LEN
      ELSE                                          'Draw Tics only
        x1 = .XAxis.Ori - .YAxis.TicLen
        x2 = .XAxis.Ori + .YAxis.TicLen
      END IF

      IF .YAxis.LogScale = FALSE THEN               'draw linear grid lines
        IF .YAxis.Div < 1 THEN .YAxis.Div = 1       'Avoid division by zero
        .YAxis.TicIntvl = .YAxis.LEN / .YAxis.Div
        FOR i = 0 TO .YAxis.Div
          y1 = .YAxis.Ori - .YAxis.TicIntvl * i
          y2 = y1
          .Buffer.Line (x1,y1,x2,y2,.GridColor)
        NEXT
        IF .YAxis.MnrTics = TRUE THEN
          x1 = .XAxis.Ori - .YAxis.TicLen / 2
          x2 = .XAxis.Ori + .YAxis.TicLen / 2
          FOR i = 0 TO .YAxis.Div - 1
            FOR j = 1 TO 4
              y1 = .YAxis.Ori - .YAxis.TicIntvl * i - .YAxis.TicIntvl/5 * j
              y2 = y1
              .Buffer.Line (x1,y1,x2,y2,.GridColor)
            NEXT
          NEXT
        END IF
      ELSE                                          'draw log grid lines
        FOR i = .YAxis.Min TO .YAxis.Max - 1
          FOR j  = 1 TO 9
            y1 = .YAxis.Ori - (.qcLog10(10 ^ i * j) - .YAxis.Min) * .YAxis.ScaleFactor
            y2 = y1
            .Buffer.Line (x1,y1,x2,y2,.GridColor)
          NEXT j
        NEXT i
       .Buffer.Line (x1,.YAxis.Ori-.YAxis.LEN,x2,.YAxis.Ori-.YAxis.LEN,.GridColor)
      END IF

      IF .XAxis.DrawZero = TRUE AND .XAxis.LogScale = FALSE THEN 'Draw the X Zero Line
        IF .XAxis.Min * .XAxis.Max < 0 THEN         'Data Spans zero
          x1 = .XAxis.Zero
          y1 = .YAxis.Ori
          x2 = .XAxis.Zero
          y2 = .YAxis.Ori - .YAxis.LEN + 1
          .Buffer.Line (x1,y1,x2,y2,.XAxis.ZeroColor)
        END IF
      END IF

      IF .YAxis.DrawZero = TRUE AND .YAxis.LogScale = FALSE THEN 'Draw the Y Zero Line
        IF .YAxis.Min * .YAxis.Max < 0 THEN         'Data Spans zero
          x1 = .XAxis.Ori
          y1 = .YAxis.Zero
          x2 = .XAxis.Ori + .XAxis.LEN - 1
          y2 = .YAxis.Zero
          .Buffer.Line (x1,y1,x2,y2,.YAxis.ZeroColor)
        END IF
      END IF

      x1 = .XAxis.Ori                               'Overwrite XAxis in its color
      y1 = .YAxis.Ori
      x2 = .XAxis.Ori + .XAxis.LEN
      y2 = .YAxis.Ori
      .Buffer.Line (x1, y1, x2, y2, .XAxis.COLOR)

      x2 = .XAxis.Ori
      y2 = .YAxis.Ori - .YAxis.LEN                  'Overwrite YAxis in its color
      .Buffer.Line (x1, y1, x2, y2, .YAxis.COLOR)

    END WITH

  END SUB
'---------------------------------------------------------------------------------------
PRIVATE:
  SUB DrawTitles

    DIM i    AS INTEGER                             'Loop counters...
    DIM j    AS INTEGER
    DIM Spacer AS INTEGER

    WITH QCHART
      '--- Main Title
      .Buffer.Font = .MainFont
      .MainTitle.Left = .XAxis.Ori + (.XAxis.LEN - .Buffer.TextWidth(RTRIM$(.MainTitle.Text))) / 2
      .MainTitle.Top = 10
      .Buffer.TextOut (.MainTitle.Left, .MainTitle.Top, RTRIM$(.MainTitle.Text),_
                       .MainFont.COLOR, .bgColor)

      '--- Sub Title
      Spacer = .Buffer.TextHeight(.MainTitle.Text)  'Calc this before Font is Changed
      .Buffer.Font = .SubFont
      .SubTitle.Left = .XAxis.Ori + (.XAxis.LEN  - .Buffer.TextWidth(RTRIM$(.SubTitle.Text))) / 2
      IF RTRIM$(.MainTitle.Text) = "" THEN          'No Main Title
        .SubTitle.Top = .MainTitle.Top              'Put Subtitle in Main title spot
      ELSE
        .SubTitle.Top = .MainTitle.Top + Spacer
      END IF
      .Buffer.TextOut (.SubTitle.Left, .SubTitle.Top, RTRIM$(.SubTitle.Text),_
                       .SubFont.COLOR, .bgColor)

      '--- X Axis Title
      .Buffer.Font = .AxisFont                      'both x and y axis
      .XTitle.Left = .XAxis.Ori + (.XAxis.LEN - .Buffer.TextWidth(RTRIM$(.XTitle.Text))) / 2
      .XTitle.Top =.YAxis.Ori + .Buffer.TextHeight(.XTitle.Text) * 2.75
      .Buffer.TextOut (.XTitle.Left, .XTitle.Top, RTRIM$(.XTitle.Text),_
                       .AxisFont.COLOR, .bgColor)

      '--- Y Axis Title
      j = LEN(RTRIM$ (.YTitle.Text))
      .YTitle.Left = .XAxis.Ori / 3.5
      .YTitle.Top = (.Buffer.Height - .Buffer.TextHeight(.YTitle.Text)*j) / 2
      FOR i = 1 TO j                                '--- Draw Y label vertically
        .Buffer.TextOut (.YTitle.Left, .YTitle.Top, MID$(.YTitle.Text, i ,1),_
                         .AxisFont.COLOR, .bgColor)
        .YTitle.Top = .YTitle.Top + .Buffer.TextHeight(.YTitle.Text)
      NEXT i

    END WITH

  END SUB
'---------------------------------------------------------------------------------------
PRIVATE:
  SUB DrawLabels

    DIM i AS INTEGER
    DIM TicVal AS DOUBLE                             'Value of tic label
    DIM LabelLen AS SINGLE                           'Total length of Labels

    WITH QCHART

      IF .XAxis.Labeled = FALSE AND .YAxis.Labeled = FALSE THEN EXIT SUB

      .Buffer.Font = .AxisFont                       'Assign Axis font to buffer
      IF .XAxis.Div < 1 THEN .XAXis.Div = 1          'Avoid division by zero
      IF .YAxis.Div < 1 THEN .YAxis.Div = 1

      SELECT CASE .ChartType
        CASE ctXY
          IF .XAxis.Labeled = TRUE THEN

            LabelLen = 0                             'Get the total length of all labels
            FOR i = 0 TO .XAxis.Div
              TicVal = .XAxis.Min + .XAxis.STEP * i
              LabelLen = LabelLen + .Buffer.TextWidth(FORMAT$("%-4.4g", TicVal))
            NEXT

            FOR i = 0 TO .XAxis.Div
              IF .XAxis.LogScale = FALSE THEN
                TicVal = .XAxis.Min + .XAxis.STEP * i 'below avoids precision artifact at 0
                IF ABS((.XAxis.Ori + .XAxis.TicIntvl * i) - .XAxis.Zero) < 1 THEN TicVal = 0
              ELSE                                    'Log Scale
                TicVal = 10^(i + .XAxis.Min)
              END IF
              .AxisLbl.Text = FORMAT$("%-4.4g", TicVal)
              .AxisLbl.Top = .YAxis.Ori + .Buffer.TextHeight(.AxisLbl.Text) / 2
              .AxisLbl.Left = .XAxis.Ori + .XAxis.TicIntvl * i -_
                             .Buffer.TextWidth(RTRIM$(.AxisLbl.Text)) / 2
              IF LabelLen * 1.1 <= .XAxis.LEN THEN    'Label all tics
                .Buffer.TextOut (.AxisLbl.Left, .AxisLbl.Top, RTRIM$(.AxisLbl.Text),_
                                 .Buffer.Font.COLOR, .bgColor)
              ELSE                                    'Label every other tic
                IF i MOD 2 = 0 THEN .Buffer.TextOut (.AxisLbl.Left, .AxisLbl.Top,_
                                    RTRIM$(.AxisLbl.Text), .Buffer.Font.COLOR, .bgColor)
              END IF
            NEXT
          END IF

        CASE ELSE
          IF .XAxis.Labeled = TRUE THEN
            SELECT CASE .ChartType
              CASE ctBox, ctHiLo
                .XAxis.TicIntvl = .XAxis.LEN / .Cols
              CASE ELSE
                .XAxis.TicIntvl = .XAxis.LEN / .Rows
            END SELECT

            LabelLen = 0                             'Get the total length of all labels
            FOR i = 0 TO .LabelList.ItemCount-1
              LabelLen = LabelLen + .Buffer.TextWidth(.LabelList.Item(i))
            NEXT i

            FOR i = 0 TO .LabelList.ItemCount-1

              .AxisLbl.Text = .LabelList.Item(i)

              IF .ChartStyle = csHisto THEN  'start at Y Axis
                .AxisLbl.Left = .XAxis.Ori + (i) * .Xaxis.TicIntvl  - _
                                .Buffer.TextWidth(RTRIM$(.AxisLbl.Text)) / 2
              ELSE ' Center between tics
                .AxisLbl.Left = .XAxis.Ori + (i) * .Xaxis.TicIntvl + (.Xaxis.TicIntvl -_
                                .Buffer.TextWidth(RTRIM$(.AxisLbl.Text))) / 2
              END IF

              IF LabelLen * 1.1 <= .XAxis.LEN THEN
                .AxisLbl.Top = .YAxis.Ori + .Buffer.TextHeight(.AxisLbl.Text) / 2
              ELSE ' alternate up and down for room
                .AxisLbl.Top = .YAxis.Ori + .Buffer.TextHeight(.AxisLbl.Text) *_
                               ((i MOD 2) + .5)
              END IF
              .Buffer.TextOut (.AxisLbl.Left, .AxisLbl.Top,RTRIM$(.AxisLbl.Text),_
                               .Buffer.Font.COLOR, .bgColor)
            NEXT i
          END IF
        END SELECT

      IF .YAxis.Labeled = TRUE THEN               'ALL Charts have values on the Y Axis
        FOR i = 0 TO .YAxis.Div
          IF .YAXIS.LogScale = FALSE THEN
            TicVal = .YAxis.Min + .YAxis.STEP * i 'below avoids precision artifact at 0
            IF ABS((.YAxis.Ori - .YAxis.TicIntvl * i) - .YAxis.Zero) < 1 THEN TicVal = 0
          ELSE                                    'Log Scaling
            TicVal = 10^(i + .YAxis.Min)
          END IF
          .AxisLbl.Text =  FORMAT$("%-4.4g",TicVal)
          .AxisLbl.Top = .YAxis.Ori - .YAxis.TicIntvl * i_
                         - .Buffer.TextHeight(.AxisLbl.Text) / 2
          .AxisLbl.Left = .XAxis.Ori - .Buffer.TextWidth(RTRIM$(.AxisLbl.Text))-_
                          .Buffer.TextWidth("8")
          .Buffer.TextOut (.AxisLbl.Left, .AxisLbl.Top,RTRIM$(.AxisLbl.Text),_
                           .Buffer.Font.COLOR, .bgColor)
        NEXT
      END IF

    END WITH

  END SUB
'---------------------------------------------------------------------------------------
PRIVATE:
  SUB DrawMarker (x1 AS SINGLE, y1 AS SINGLE, MrkrStyle AS INTEGER, COLOR AS LONG, Lgd AS BYTE)

    DIM x2 AS SINGLE
    DIM y2 AS SINGLE
    DIM FillColor AS LONG

    WITH QCHART

      IF Lgd = FALSE THEN
        FillColor = .PlotAreaColor
      ELSE
        FillColor = .bgColor
      END IF

      x1 = x1 - .MarkerSize                   'MarkerSize is set in .Intitalize or
      y1 = y1 - .MarkerSize                   'changed by user
      x2 = x1 + .MarkerSize * 2
      y2 = y1 + .MarkerSize * 2

      SELECT CASE MrkrStyle                   'Sent by calling routine

        CASE msFillCircle
          .Buffer.Circle (x1 , y1 , x2 , y2 , COLOR, COLOR)

        CASE msFillSquare
          .Buffer.FillRect (x1 , y1 , x2 , y2 , COLOR)

        CASE msFillTriangleUp
          .Buffer.Line (x1, y2, x2, y2, COLOR)
          .Buffer.Line (x1, y2 , x1 + .MarkerSize, y1, COLOR)
          .Buffer.Line (x2, y2 , x1 + .MarkerSize, y1, COLOR)
          .Buffer.Paint (x1 + .MarkerSize, y1 + .MarkerSize, COLOR, COLOR)

        CASE msFillTriangleDown
          y2 = y2 - .MarkerSize * 2
          .Buffer.Line (x1, y2, x2, y2, COLOR)
          .Buffer.Line (x1, y2 , x1 + .MarkerSize, y1 + .MarkerSize * 2, COLOR)
          .Buffer.Line (x2, y2 , x1 + .MarkerSize, y1 + .MarkerSize * 2, COLOR)
          .Buffer.Paint (x1 + .MarkerSize, y1 + .MarkerSize, COLOR, COLOR)

        CASE msCircle
          .Buffer.Circle (x1 , y1 , x2 , y2 , COLOR, FillColor)

        CASE msSquare
          .Buffer.Rectangle (x1 , y1 , x2 , y2 , COLOR)
          .Buffer.Paint (x1 + .MarkerSize, y1 + .MarkerSize, FillColor, COLOR)

        CASE msTriangleUp
          .Buffer.Line (x1, y2, x2, y2, COLOR)
          .Buffer.Line (x1, y2 , x1 + .MarkerSize, y1, COLOR)
          .Buffer.Line (x2, y2 , x1 + .MarkerSize, y1, COLOR)
          .Buffer.Paint (x1 + .MarkerSize, y1 + .MarkerSize, FillColor, COLOR)

        CASE msTriangleDown
          y2 = y2 - .MarkerSize * 2
          .Buffer.Line (x1, y2, x2, y2, COLOR)
          .Buffer.Line (x1, y2 , x1 + .MarkerSize, y1 + .MarkerSize * 2, COLOR)
          .Buffer.Line (x2, y2 , x1 + .MarkerSize, y1 + .MarkerSize * 2, COLOR)
          .Buffer.Paint (x1 + .MarkerSize, y1 + .MarkerSize, FillColor, COLOR)

      END SELECT

    END WITH

  END SUB
'---------------------------------------------------------------------------------------
PRIVATE:
  SUB DrawLegend

    DIM i  AS INTEGER                                              'Loop counter...
    DIM x1 AS SINGLE                                               'for readability
    DIM y1 AS SINGLE
    DIM x2 AS SINGLE
    DIM y2 AS SINGLE
    DIM BorderHgt AS INTEGER
    DIM LineLen AS INTEGER
    DIM LMark AS INTEGER

    WITH QCHART
      IF .DoLegend = FALSE THEN EXIT SUB                           'Don't perform task

      .Buffer.Font = .LegendFont

      x1 = (.XAxis.Ori + .XAxis.LEN) + .Buffer.TextWidth("W")      'Draw a box for the legend
      x2 = .Buffer.Width - .Buffer.TextWidth("W")
      LineLen = x2 -  x1 - .Buffer.TextWidth("W") * 2.5
      IF .ChartType = ctPie THEN
        BorderHgt = .Buffer.TextHeight("W") * (.Rows) + 5
      ELSE
        BorderHgt = .Buffer.TextHeight("W") * (.Cols) + 5
      END IF

      IF .ChartStyle = csLines THEN BorderHgt = BorderHgt * 1.5    'Leave room for line styles
      y1 = .YAxis.Ori - (.YAxis.LEN + BorderHgt) / 2
      y2 = y1 + BorderHgt
      .Buffer.Rectangle (x1,y1,x2,y2,.fgColor)

      qcSetBkColor (.Buffer.Handle, .bgColor)
      .Buffer.Line (0,0,0,0,0)                                      'Reset Buffer's pen to Black
      FOR i = 0 TO .LegendList.ItemCount - 1                        'For each item in the legend
        .Legend.Text = .LegendList.Item(i)
        .Legend.Top = y1 + .Buffer.TextHeight(.Legend.Text) * i + 2
        .Legend.Left = x1 + .Buffer.TextWidth("I")
        x2 = .Legend.Left + .Buffer.TextHeight(.Legend.Text)
        y2 = .Legend.Top + .Buffer.TextHeight(.Legend.Text)
        IF .ChartType = ctLine OR .ChartType = ctXY OR .ChartType = ctReal THEN
          IF .ChartStyle <> csLines THEN
            LMark = .MarkerSize
            .MarkerSize = .Buffer.TextHeight(.Legend.Text) / 3
            .DrawMarker (.Legend.Left + .Buffer.TextHeight(.Legend.Text) / 3,_
                         .Legend.Top + .Buffer.TextHeight(.Legend.Text) / 2,_
                         .Series(i+1).Marker, .Series(i+1).COLOR,1)
            .Buffer.TextOut (x2 + 2, .Legend.Top, RTRIM$(.Legend.Text),_
                             .LegendFont.COLOR, .bgColor)
            .MarkerSize = LMark
          ELSE
            .Legend.Top = .Legend.Top + .Buffer.TextHeight(.Legend.Text)/2 * i
            .hPen = qcCreatePen(.Series(i+1).LineStyle, .Series(i+1).LineWidth, .Series(i+1).COLOR)
            .OldPen = qcSelectObject(.Buffer.Handle, .hPen)
            qcMoveToEx(.Buffer.Handle,.Legend.Left + 2, y2 + .Series(i+1).LineWidth +_
                       .Buffer.TextHeight(.Legend.Text)/2 * i , 0)
            qcLineTo(.Buffer.Handle,x2 + LineLen, y2 + .Series(i+1).LineWidth +_
                     .Buffer.TextHeight(.Legend.Text)/2 * i)
            qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldPen))
            .Buffer.TextOut (x2 - .Buffer.TextWidth("T") , .Legend.Top, RTRIM$(.Legend.Text),_
                             .LegendFont.COLOR, .bgColor)
          END IF
        ELSE
          IF .Series(i+1).HatchStyle = hsSolid THEN
            .hBrush = qcCreateSolidBrush(.Series(i+1).COLOR)
          ELSE
            .hBrush = qcCreateHatchBrush(.Series(i+1).HatchStyle, .Series(i+1).COLOR)
          END IF
          .OldBrush = qcSelectObject(.Buffer.Handle, .hBrush)
          qcRectangle (.Buffer.Handle, .Legend.Left, .Legend.Top + 2, x2, y2)
          qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldBrush))
          .Buffer.TextOut (x2 + 2, .Legend.Top, RTRIM$(.Legend.Text),_
                           .LegendFont.COLOR, .bgColor)
        END IF
      NEXT

    END WITH

  END SUB
'---------------------------------------------------------------------------------------
PRIVATE:
  SUB DrawBar (Overlay AS INTEGER, ColNum AS INTEGER)
  'X Points are (OriX + VAL * XScaleFactor - XMin) (ScaleFactor = Axis.Len / Axis.Max)
  'Y Points are (OriY - VAL * YScaleFactor - YMin) (i.e. ^^  = Pixels per Unit)

    DIM i  AS INTEGER                               'Loop counters...
    DIM j  AS INTEGER
    DIM x1 AS SINGLE                                'for readability
    DIM y1 AS SINGLE
    DIM x2 AS SINGLE
    DIM y2 AS SINGLE
    DIM GrpWidth AS SINGLE
    DIM BoxWidth AS SINGLE                          'Width of bars in bar and box plots
    DIM Incr AS SINGLE                              'Space between bars
    DIM Total AS SINGLE                             'Row Total for % Stacked calcs
    DIM Start AS INTEGER
    DIM Finish AS INTEGER

    IF ColNum = 0 THEN                              'Normal, plot all cols
      Start = 1
      Finish = QCHART.Cols
    ELSE                                            'BarLine chart, plot specified
      Start = ColNum                                'ColNum only
      Finish = ColNum
    END IF

    IF Overlay = FALSE THEN
      WITH QCHART                                   'Set up the chart window
        .ClearBuffer                                'erase the current bitmap
        .SetSize
        .SetScale (1,.Rows)
        IF .Success = FALSE THEN                    'Log Scaling failed
          .ClearAll
          EXIT SUB
        END IF
        .SetSeries
        .XAxis.Div = .Rows                          'Forces a grid line for each X Label
        .XAxis.DrawZero = FALSE                     'No Values on the X
        .DrawAxes
        .DrawTitles
        .DrawLabels
        .DrawLegend
      END WITH
    END IF

    SELECT CASE QCHART.ChartStyle

      CASE csHisto                                  'Histogram (no spaces between bars)
        WITH QCHART                                 'Plot the data
          BoxWidth = (.XAxis.LEN + .01) / .Rows     'Leave some space at axis
          FOR i = Start TO Finish                   'Col 1 if BarLine else all .Cols
            IF .Series(i).HatchStyle = hsSolid THEN
              .hBrush = qcCreateSolidBrush(.Series(i).COLOR)
            ELSE
              .hBrush = qcCreateHatchBrush(.Series(i).HatchStyle, .Series(i).COLOR)
            END IF
            .OldBrush = qcSelectObject(.Buffer.Handle, .hBrush)
            Incr = BoxWidth  *  (i-1) / (.Cols + 1)
            GrpWidth = BoxWidth - Incr
            FOR j = 1 TO .Rows
              IF .Data(i,j) = .Missing THEN GOTO NoPlotHisto
              x1 = .XAxis.Ori + BoxWidth * (j-1) + Incr/2
              x2 = x1 + GrpWidth + 1
              IF .YAxis.LogScale = TRUE THEN
                y1 = .YAxis.Ori
                y2 = .YAxis.Ori - (.qcLog10(.Data(i,j)) - .YAxis.Min) * .YAxis.ScaleFactor
              ELSEIF .YAxis.Min >= 0 AND .YAxis.Max >= 0 THEN 'No Negative data
                y1 = .YAxis.Ori
                y2 = .YAxis.Ori - (.Data(i,j) - .YAxis.Min) * .YAxis.ScaleFactor
              ELSE                                            'Have Negative values
                y1 = .YAxis.Zero
                y2 = .YAxis.Zero - (.Data(i,j) * .YAxis.ScaleFactor)
              END IF
              qcRectangle (.Buffer.Handle,x1,y1,x2,y2)
NoPlotHisto:
            NEXT j
            qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldBrush))
          NEXT i
        END WITH

      CASE csBar                                          'Grouped Bar Chart (spaces between bars)
        WITH QCHART
          GrpWidth = (.XAxis.LEN + .01) / .Rows
          IF ColNum = 0 THEN                              'Normal, use all cols
            BoxWidth = GrpWidth / (.Cols + .5)
          ELSE                                            'BarLine chart, only 1 series
            BoxWidth = GrpWidth / 1.5
          END IF
          FOR i = Start TO Finish                         'Col 1 if BarLine else all .Cols

            IF .Series(i).HatchStyle = hsSolid THEN
              .hBrush = qcCreateSolidBrush(.Series(i).COLOR)
            ELSE
              .hBrush = qcCreateHatchBrush(.Series(i).HatchStyle, .Series(i).COLOR)
            END IF
            .OldBrush = qcSelectObject(.Buffer.Handle, .hBrush)
            FOR j = 1 TO .Rows
              IF .Data(i,j) = .Missing THEN GOTO NoPlotBar

              x1 = (.XAxis.Ori + BoxWidth / 4) + GrpWidth * (j - 1) + BoxWidth * (i - 1)
              x2 = x1 + BoxWidth + 1
              IF .YAxis.LogScale = TRUE THEN
                y1 = .YAxis.Ori
                y2 = .YAxis.Ori - (.qcLog10(.Data(i,j))-.YAxis.Min) * .YAxis.ScaleFactor
              ELSEIF .YAxis.Min >= 0 AND .YAxis.Max >= 0 THEN  'No Negative data
                y1 = .YAxis.Ori
                y2 = .YAxis.Ori - (.Data(i,j) -.YAxis.Min) * .YAxis.ScaleFactor
              ELSE                                             'Have Negative values
                y1 = .YAxis.Zero
                y2 = .YAxis.Zero - (.Data(i,j) * .YAxis.ScaleFactor)
              END IF
              qcRectangle (.Buffer.Handle,x1,y1,x2,y2)
NoPlotBar:
            NEXT j
            qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldBrush))
          NEXT i
        END WITH

      CASE csStacked
        WITH QCHART
          BoxWidth = (.XAxis.LEN + .01) / (.Rows + 1)
          Incr = BoxWidth / .Rows
          FOR i = 1 TO .Rows
            FOR j = 1 TO .Cols
              IF .Series(j).HatchStyle = hsSolid THEN
                .hBrush = qcCreateSolidBrush(.Series(j).COLOR)
              ELSE
                .hBrush = qcCreateHatchBrush(.Series(j).HatchStyle, .Series(j).COLOR)
              END IF
              .OldBrush = qcSelectObject(.Buffer.Handle, .hBrush)
              x1 = (.XAxis.Ori + Incr/2) + (BoxWidth + Incr) * (i-1)
              x2 = x1 + BoxWidth
              IF j = 1 THEN y1 = .YAxis.Ori ELSE y1 = y2
              y2 = y1 - (ABS(.Data(j,i))- .YAxis.Min) * .YAxis.ScaleFactor
              qcRectangle (.Buffer.Handle,x1,y1+1,x2+1,y2)
            NEXT j
            qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldBrush))
          NEXT i
        END WITH

      CASE csPctStacked
        WITH QCHART
          BoxWidth = (.XAxis.LEN + .01) / (.Rows +1)
          Incr = BoxWidth / .Rows
          FOR i = 1 TO .Rows
            Total = .RowTotal(i)
            IF Total = 0 THEN
              MESSAGEDLG("Division by Zero!", 1, 4, 0)
              .ClearAll
              EXIT SUB
            END IF
            FOR j = 1 TO .Cols
              IF .Series(j).HatchStyle = hsSolid THEN
                .hBrush = qcCreateSolidBrush(.Series(j).COLOR)
              ELSE
                .hBrush = qcCreateHatchBrush(.Series(j).HatchStyle, .Series(j).COLOR)
              END IF
              .OldBrush = qcSelectObject(.Buffer.Handle, .hBrush)
              x1 = (.XAxis.Ori + Incr/2) + (BoxWidth + Incr) * (i-1)
              x2 = x1 + BoxWidth
              IF j = 1 THEN y1 = .YAxis.Ori ELSE y1 = y2
              y2 = y1 - (100 * (ABS(.Data(j,i))/Total) * .YAxis.ScaleFactor)
              qcRectangle (.Buffer.Handle,x1,y1+1,x2+1,y2)
            NEXT j
            qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldBrush))
          NEXT i
        END WITH

    END SELECT
    QCHART.ChartExists = TRUE

  END SUB
'---------------------------------------------------------------------------------------
PRIVATE:
  SUB DrawXY (Overlay AS INTEGER)
  'X Points are (OriX + VAL * XScaleFactor - XMin) (ScaleFactor = Axis.Len / Axis.Max)
  'Y Points are (OriY - VAL * YScaleFactor - YMin) (i.e. ^^  = Pixels per Unit)

    DIM i  AS INTEGER                               'Loop counters...
    DIM j  AS INTEGER
    DIM x1 AS SINGLE                                'for readability
    DIM y1 AS SINGLE
    DIM x2 AS SINGLE
    DIM y2 AS SINGLE

    IF Overlay = FALSE THEN
      WITH QCHART                                   'Set up the chart window
        .ClearBuffer                                'erase the current bitmap
        .SetSize
        .SetScale (1,.Rows)
        IF .Success = FALSE THEN                    'Log Scaling failed
          .ClearAll
          EXIT SUB
        END IF
        .SetSeries
        .DrawAxes
        .DrawTitles
        .DrawLabels
        .DrawLegend
      END WITH
    END IF

    SELECT CASE QCHART.ChartStyle

      CASE csPoints
        WITH QCHART
          FOR i = 1 TO .Cols
            FOR j = 1 TO .Rows

              IF .XYData(i,j,1)=.Missing THEN GOTO NoPlotXYPt   'If data missing
              IF .XYData(i,j,2)=.Missing THEN GOTO NoPlotXYPt

              IF .XAxis.LogScale = FALSE THEN
                x1 = .XAxis.Ori + (.XYData(i,j,1)-.XAxis.Min) * .XAxis.ScaleFactor
              ELSE
                x1 = .XAxis.Ori + (.qcLog10(.XYData(i,j,1))-.XAxis.Min) * .XAxis.ScaleFactor
              END IF

              IF .YAxis.LogScale = FALSE THEN
                y1 = .YAxis.Ori - (.XYData(i,j,2)-.YAxis.Min) * .YAxis.ScaleFactor
              ELSE
                y1 = .YAxis.Ori - (.qcLog10(.XYData(i,j,2))-.YAxis.Min) * .YAxis.ScaleFactor
              END IF
              .DrawMarker (x1, y1, .Series(i).Marker, .Series(i).COLOR,0)
NoPlotXYPt:
            NEXT j
          NEXT i
        END WITH

      CASE csLines
        WITH QCHART
          qcSetBkColor (.Buffer.Handle, .PlotAreaColor)
          FOR i = 1 TO .Cols
            .hPen = qcCreatePen(.Series(i).LineStyle, .Series(i).LineWidth, .Series(i).COLOR)
            .OldPen = qcSelectObject(.Buffer.Handle, .hPen)
            FOR j = 1 TO .Rows - 1

              IF .XYData(i,j,1)=.Missing OR .XYData(i,j+1,1)=.Missing THEN GOTO NoPlotXYLn
              IF .XYData(i,j,2)=.Missing OR .XYData(i,j+1,2)=.Missing THEN GOTO NoPlotXYLn

              IF .XAxis.LogScale = FALSE THEN
                x1 = (.XYData(i,j,1)-.XAxis.Min) * .XAxis.ScaleFactor
                x2 = (.XYData(i,j+1,1)-.XAxis.Min) * .XAxis.ScaleFactor
              ELSE
                x1 = (.qcLog10(.XYData(i,j,1))-.XAxis.Min) * .XAxis.ScaleFactor
                x2 = (.qcLog10(.XYData(i,j+1,1))-.XAxis.Min) * .XAxis.ScaleFactor
              END IF

              IF .YAxis.LogScale = FALSE THEN
                y1 = (.XYData(i,j,2)-.YAxis.Min) * .YAxis.ScaleFactor
                y2 = (.XYData(i,j+1,2)-.YAxis.Min) * .YAxis.ScaleFactor
              ELSE
                y1 = (.qcLog10(.XYData(i,j,2))-.YAxis.Min) *.YAxis.ScaleFactor
                y2 = (.qcLog10(.XYData(i,j+1,2))-.YAxis.Min) *.YAxis.ScaleFactor
              END IF

              x1 = .XAxis.Ori + x1
              y1 = .YAxis.Ori - y1
              x2 = .XAxis.Ori + x2
              y2 = .YAxis.Ori - y2

              '--- Use API to draw lines
              qcMoveToEx(.Buffer.handle,x1,y1,0)
              qcLineTo(.Buffer.handle,x2,y2)
NoPlotXYLn:
            NEXT j
            qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldPen))
          NEXT i

        END WITH

      CASE csBoth
        WITH QCHART
          .ChartStyle = csPoints                    'Draw Points
          .DrawXY (Overlay)                         'Draw Points (May erase current)
          .ChartStyle = csLines                     'AND Lines
          .DrawXY (TRUE)                            'Overlay Lines (do NOT erase)
          .ChartStyle = csBoth                      'Reset ChartStyle for repaints
        END WITH

    END SELECT
    QCHART.ChartExists = TRUE

  END SUB
'---------------------------------------------------------------------------------------
PRIVATE:
  SUB DrawLine (Overlay AS INTEGER, ColNum AS INTEGER)
  'X Points are (OriX + VAL * XScaleFactor - XMin) (ScaleFactor = Axis.Len / Axis.Max)
  'Y Points are (OriY - VAL * YScaleFactor - YMin) (i.e. ^^  = Pixels per Unit)

    DIM i  AS INTEGER                               'Loop counters...
    DIM j  AS INTEGER
    DIM x1 AS SINGLE                                'for readability
    DIM y1 AS SINGLE
    DIM x2 AS SINGLE
    DIM y2 AS SINGLE
    DIM Start AS INTEGER
    DIM Finish AS INTEGER

    IF ColNum = 0 THEN                              'Normal, plot all cols
      Start = 1
      Finish = QCHART.Cols
    ELSE                                            'BarLine chart, plot specified
      Start = ColNum                                'ColNum only
      Finish = ColNum
    END IF

    IF Overlay = FALSE THEN
      WITH QCHART                                   'Set up the chart window
        .ClearBuffer                                'erase the current bitmap
        .SetSize
        .SetScale (1,.Rows)
        IF .Success = FALSE THEN                    'Log Scaling failed
          .ClearAll
          EXIT SUB
        END IF
        .SetSeries
        .XAxis.Div = .Rows                          'Forces a grid line for each X Label
        .XAxis.DrawZero = FALSE                     'No Values on the X
        .DrawAxes
        .DrawTitles
        .DrawLabels
        .DrawLegend
      END WITH
    END IF

    SELECT CASE QCHART.ChartStyle

      CASE csPoints
        WITH QCHART
          FOR i = Start TO Finish                           'Col 2 if BarLine else all .Cols
            FOR j = 1 TO .Rows

              IF .Data(i,j)=.Missing THEN GOTO NoPlotLinePt 'If data missing

              IF j = 1 THEN
                x1 = .XAxis.Ori + .Xaxis.TicIntvl * .5
              ELSE
                x1 = x1 + .Xaxis.TicIntvl
              END IF

              IF .YAxis.LogScale = FALSE THEN
                y1 = .YAxis.Ori - (.Data(i,j)-.YAxis.Min) * .YAxis.ScaleFactor
              ELSE
                y1 = .YAxis.Ori - (.qcLog10(.Data(i,j))-.YAxis.Min) *.YAxis.ScaleFactor
              END IF
              .DrawMarker (x1, y1, .Series(i).Marker, .Series(i).COLOR,0)
NoPlotLinePt:
            NEXT j
          NEXT i
        END WITH

      CASE csLines
        WITH QCHART
          qcSetBkColor (.Buffer.Handle, .PlotAreaColor)
          FOR i = Start TO Finish                           'Col 2 if BarLine else all .Cols
            .hPen = qcCreatePen(.Series(i).LineStyle, .Series(i).LineWidth, .Series(i).COLOR)
            .OldPen = qcSelectObject(.Buffer.Handle, .hPen)
            FOR j = 1 TO .Rows - 1

              IF .Data(i,j)=.Missing OR .Data(i,j+1)=.Missing THEN GOTO NoPlotLineLn

              IF j = 1 THEN
                x1 = .XAxis.Ori + .Xaxis.TicIntvl * .5
              ELSE
                x1 = x2
              END IF
              x2 = x1 + .Xaxis.TicIntvl

              IF .YAxis.LogScale = FALSE THEN
                y1 = .YAxis.Ori - (.Data(i,j)-.YAxis.Min) * .YAxis.ScaleFactor
                y2 = .YAxis.Ori - (.Data(i,j+1)-.YAxis.Min) * .YAxis.ScaleFactor
              ELSE
                y1 = .YAxis.Ori - (.qcLog10(.Data(i,j))-.YAxis.Min) *.YAxis.ScaleFactor
                y2 = .YAxis.Ori - (.qcLog10(.Data(i,j+1))-.YAxis.Min) *.YAxis.ScaleFactor
              END IF

              '--- Use API to draw lines
              qcMoveToEx(.Buffer.handle,x1,y1,0)
              qcLineTo(.Buffer.handle,x2,y2)
NoPlotLineLn:
            NEXT j
            qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldPen))
          NEXT i

        END WITH

      CASE csBoth
        WITH QCHART
          .ChartStyle = csPoints                    'Draw Points
          .DrawLine (Overlay,ColNum)                'Draw Points (May erase current)
          .ChartStyle = csLines                     'AND Lines
          .DrawLine (TRUE,ColNum)                   'Overlay Lines (do NOT erase)
          .ChartStyle = csBoth                      'Reset ChartStyle for repaints
        END WITH

    END SELECT
    QCHART.ChartExists = TRUE

  END SUB
'---------------------------------------------------------------------------------------
PRIVATE:
  SUB DrawBox (Overlay AS INTEGER)
  'X Points are (OriX + VAL * XScaleFactor - XMin) (ScaleFactor = Axis.Len / Axis.Max)
  'Y Points are (OriY - VAL * YScaleFactor - YMin) (i.e. ^^  = Pixels per Unit)

    DIM i  AS INTEGER                               'Loop counters...
    DIM j  AS INTEGER
    DIM x1 AS SINGLE                                'for readability
    DIM y1 AS SINGLE
    DIM x2 AS SINGLE
    DIM y2 AS SINGLE
    DIM XIntvl AS SINGLE                            'Distance between plots
    DIM LinWidth AS LONG                            'Width od Mid Line
    DIM LinColor AS LONG                            'Change for Hi-Lo
    DIM BoxWidth AS LONG                            'Width of bars

    IF Overlay = FALSE THEN
      WITH QCHART                                   'Set up the chart window
        .ClearBuffer                                'erase the current bitmap
        .SetSize
        .SetScale (1,.Rows)
        IF .Success = FALSE THEN                    'Log Scaling failed
          .ClearAll
          EXIT SUB
        END IF
        .SetSeries
        .Xaxis.Div = .Cols
        .XAxis.DrawZero = FALSE                     'No Values on the X
        .DrawAxes
        .DrawTitles
        .DrawLabels
        .DrawLegend
      END WITH
    END IF

    WITH QCHART
      XIntvl = .XAxis.LEN / .Cols
      LinWidth = XIntvl * .75
      BoxWidth = LinWidth * .75
      FOR i = 1 TO .Cols
        '--- Draw Min - Max Line (Whiskers)
        x1 = .XAxis.Ori + XIntvl * (i-1) + XIntvl / 2
        x2 = x1
        IF .YAxis.LogScale = FALSE THEN
          y1 = .YAxis.Ori - (.Data(i,5)-.YAxis.Min) * .YAxis.ScaleFactor 'Min
          y2 = .YAxis.Ori - (.Data(i,1)-.YAxis.Min) * .YAxis.ScaleFactor 'Max
        ELSE
          y1 = .YAxis.Ori - (.qcLog10(.Data(i,5))-.YAxis.Min) * .YAxis.ScaleFactor 'Min
          y2 = .YAxis.Ori - (.qcLog10(.Data(i,1))-.YAxis.Min) * .YAxis.ScaleFactor 'Max
        END IF
        .Buffer.Line (x1 , y1 , x2 , y2 , .fgColor)
        .Buffer.Line (x1 - LinWidth / 4 , y1 , x2 + LinWidth / 4 , y1 , .fgColor)
        .Buffer.Line (x1 - LinWidth / 4 , y2 , x2 + LinWidth / 4 , y2 , .fgColor)

        '--- Draw Quartile Box
        x1 = x1 - BoxWidth / 2
        x2 = x1 + BoxWidth + 1
        IF .YAxis.LogScale = FALSE THEN
          y1 = .YAxis.Ori - (.Data(i,4)-.YAxis.Min) * .YAxis.ScaleFactor + 1 'Q1
          y2 = .YAxis.Ori - (.Data(i,2)-.YAxis.Min) * .YAxis.ScaleFactor     'Q3
        ELSE
          y1 = .YAxis.Ori - (.qcLog10(.Data(i,4))-.YAxis.Min) * .YAxis.ScaleFactor + 1 'Q1
          y2 = .YAxis.Ori - (.qcLog10(.Data(i,2))-.YAxis.Min) * .YAxis.ScaleFactor     'Q3
        END IF
        IF .Series(i).HatchStyle = hsSolid THEN
          .hBrush = qcCreateSolidBrush(.Series(i).COLOR)
        ELSE
          .hBrush = qcCreateHatchBrush(.Series(i).HatchStyle, .Series(i).COLOR)
        END IF
        .OldBrush = qcSelectObject(.Buffer.Handle, .hBrush)
        qcRectangle (.Buffer.Handle,x1,y1,x2+1,y2)
        qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldBrush))

        '--- Draw Median Line
        x1 = .XAxis.Ori + XIntvl * (i-1) + XIntvl / 2 - LinWidth / 2
        x2 = x1 + LinWidth + 1
        IF .YAxis.LogScale = FALSE THEN
          y1 = .YAxis.Ori - (.Data(i,3)-.YAxis.Min) * .YAxis.ScaleFactor            'Q2
        ELSE
          y1 = .YAxis.Ori - (.qcLog10(.Data(i,3))-.YAxis.Min) * .YAxis.ScaleFactor  'Q2
        END IF
        y2 = y1
        LinColor = .Colors(24)
        IF .GreyScale = TRUE THEN LinColor = .Colors(27)
        .hBrush = qcCreateSolidBrush(LinColor)
        .OldBrush = qcSelectObject(.Buffer.Handle, .hBrush)
        qcRectangle (.Buffer.Handle,x1,y1+1,x2+1,y2-2)
        qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldBrush))
      NEXT i
    END WITH
    QCHART.ChartExists = TRUE

  END SUB
'------------------------------------------------------------------------------------------
PRIVATE:
  SUB DrawHiLo (Overlay AS INTEGER)
  'X Points are (OriX + VAL * XScaleFactor - XMin) (ScaleFactor = Axis.Len / Axis.Max)
  'Y Points are (OriY - VAL * YScaleFactor - YMin) (i.e. ^^  = Pixels per Unit)

    DIM i  AS INTEGER                               'Loop counters...
    DIM j  AS INTEGER
    DIM x1 AS SINGLE                                'for readability
    DIM y1 AS SINGLE
    DIM x2 AS SINGLE
    DIM y2 AS SINGLE
    DIM XIntvl AS SINGLE                            'Distance between plots
    DIM LinWidth AS LONG                            'Width od Mid Line
    DIM LinColor AS LONG                            'Change for Hi-Lo
    DIM BoxWidth AS LONG                            'Width of bars

    IF Overlay = FALSE THEN
      WITH QCHART                                   'Set up the chart window
        .ClearBuffer                                'erase the current bitmap
        .SetSize
        .SetScale (1,.Rows)
        IF .Success = FALSE THEN                    'Log Scaling failed
          .ClearAll
          EXIT SUB
        END IF
        .SetSeries
        .Xaxis.Div = .Cols
        .XAxis.DrawZero = FALSE                     'No Values on the X
        .DrawAxes
        .DrawTitles
        .DrawLabels
        IF .ChartStyle = csHiLoBox THEN .DrawLegend
      END WITH
    END IF

    WITH QCHART
      XIntvl = .XAxis.LEN / .Cols
      LinWidth = XIntvl * .75
      BoxWidth = LinWidth * .75
      FOR i = 1 TO .Cols

        x1 = .XAxis.Ori + XIntvl * (i-1) + XIntvl / 2
        x2 = x1
        IF .ChartStyle = csAntenna THEN
          '--- Draw Min - Max Line (Whiskers)
          IF .YAxis.LogScale = FALSE THEN
            y1 = .YAxis.Ori - (.Data(i,3)-.YAxis.Min) * .YAxis.ScaleFactor 'Lo
            y2 = .YAxis.Ori - (.Data(i,1)-.YAxis.Min) * .YAxis.ScaleFactor 'Hi
          ELSE
            y1 = .YAxis.Ori - (.qcLog10(.Data(i,3))-.YAxis.Min) * .YAxis.ScaleFactor 'Lo
            y2 = .YAxis.Ori - (.qcLog10(.Data(i,1))-.YAxis.Min) * .YAxis.ScaleFactor 'Hi
          END IF
          .Buffer.Line (x1 , y1 , x2 , y2 , .fgColor)
          .Buffer.Line (x1 - LinWidth / 4 , y1 , x2 + LinWidth / 4 , y1 , .fgColor)
          .Buffer.Line (x1 - LinWidth / 4 , y2 , x2 + LinWidth / 4 , y2 , .fgColor)
        ELSE
          '--- Draw Min - Max Box
          x1 = x1 - BoxWidth / 2
          x2 = x1 + BoxWidth + 1
          IF .YAxis.LogScale = FALSE THEN
            y1 = .YAxis.Ori - (.Data(i,3)-.YAxis.Min) * .YAxis.ScaleFactor + 1 'Lo
            y2 = .YAxis.Ori - (.Data(i,1)-.YAxis.Min) * .YAxis.ScaleFactor     'Hi
          ELSE
            y1 = .YAxis.Ori - (.qcLog10(.Data(i,3))-.YAxis.Min) * .YAxis.ScaleFactor + 1 'Lo
            y2 = .YAxis.Ori - (.qcLog10(.Data(i,1))-.YAxis.Min) * .YAxis.ScaleFactor     'Hi
          END IF
          IF .Series(i).HatchStyle = hsSolid THEN
            .hBrush = qcCreateSolidBrush(.Series(i).COLOR)
          ELSE
            .hBrush = qcCreateHatchBrush(.Series(i).HatchStyle, .Series(i).COLOR)
          END IF
          .OldBrush = qcSelectObject(.Buffer.Handle, .hBrush)
          qcRectangle (.Buffer.Handle,x1,y1,x2+1,y2)
          qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldBrush))
        END IF
        '--- Draw Close Line
        x1 = .XAxis.Ori + XIntvl * (i-1) + XIntvl / 2 - LinWidth / 2
        x2 = x1 + LinWidth + 1
        IF .YAxis.LogScale = FALSE THEN
          y1 = .YAxis.Ori - (.Data(i,2)-.YAxis.Min) * .YAxis.ScaleFactor            'Close
        ELSE
          y1 = .YAxis.Ori - (.qcLog10(.Data(i,2))-.YAxis.Min) * .YAxis.ScaleFactor  'Close
        END IF
        y2 = y1
        SELECT CASE .ChartStyle
          CASE csAntenna
            LinColor = .Colors(0)
          CASE csHiLoBox
            LinColor = .Colors(24)
        END SELECT
        IF .GreyScale = TRUE THEN LinColor = .Colors(27)
        .hBrush = qcCreateSolidBrush(LinColor)
        .OldBrush = qcSelectObject(.Buffer.Handle, .hBrush)
        qcRectangle (.Buffer.Handle,x1,y1+1,x2+1,y2-2)
        qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldBrush))
      NEXT i
    END WITH
    QCHART.ChartExists = TRUE

  END SUB

'------------------------------------------------------------------------------------------
PRIVATE:
  SUB DrawPie (Overlay AS INTEGER)

    DIM i  AS INTEGER                               'Loop counters...
    DIM x1 AS LONG                                  'for readability
    DIM y1 AS LONG
    DIM x2 AS LONG
    DIM y2 AS LONG
    DIM Total AS SINGLE
    DIM pi2 AS DOUBLE
    DIM pct AS SINGLE
    DIM Radius AS DOUBLE
    DIM Cum AS DOUBLE
    DIM xSize AS SINGLE
    DIM ySize AS SINGLE
    DIM xLeft AS LONG
    DIM xRight AS LONG
    DIM yTop AS LONG
    DIM yBottom AS LONG
    DIM TxtFactor AS SINGLE

    IF Overlay = FALSE THEN
      WITH QCHART                                   'Set up the chart window
        .ClearBuffer                                'erase the current bitmap
        .DoLegend = TRUE                            'Force to calculate sizes based on Legend
        .SetSize
        .SetSeries
        .DrawAxes                                   'Draws frame but no axes
        .DrawTitles
        .DrawLegend
      END WITH
    END IF

    WITH QCHART
      Total = .ColTotal(1)
      IF Total = 0 THEN
        MESSAGEDLG("Division by Zero!", 1, 4, 0)
        .ClearAll
        EXIT SUB
      END IF
      .Buffer.Font = .AxisFont
      TxtFactor = .Buffer.TextHeight("I")
      xSize = .XAxis.LEN - TxtFactor
      ySize = .YAxis.LEN - TxtFactor
      pi2 = 8*ATN(1)
      Radius = ySize / 2.5
      xLeft = (.XAxis.Ori + xSize / 2) - Radius
      xRight =(.XAxis.Ori + xSize / 2) + Radius
      yTop = (.YAxis.Ori - ySize / 2) - Radius
      yBottom = (.YAxis.Ori - ySize / 2) + Radius

      x1 = xRight                                     'Set Start point for 1st wedge
      y1 = (yTop + yBottom) \ 2
      Cum = 0
      FOR i = 1 TO .Rows
        IF .Data(1,i) <> .Missing THEN                'if data not missing

          Cum = Cum + .Data(1,i)                      'Calculate wedge endpoint
          x2 = .XAXis.Ori + xSize / 2 + Radius * COS(pi2 * Cum / Total)
          y2 = .YAxis.Ori - ySize / 2 - Radius * SIN(pi2 * Cum / Total)

          IF .Series(i).HatchStyle = hsSolid THEN     'Set brush color for wedge
            .hBrush = qcCreateSolidBrush(.Series(i).COLOR)
          ELSE
            .hBrush = qcCreateHatchBrush(.Series(i).HatchStyle, .Series(i).COLOR)
          END IF
          .OldBrush = qcSelectObject(.Buffer.Handle, .hBrush)
          qcPie (.Buffer.Handle, xLeft, yTop, xRight, yBottom, x1, y1, x2, y2)'Draw the wedge
          qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldBrush))

          SELECT CASE .ChartStyle                     'Print labels at midpoint of wedge
            CASE csPiePct
              pct = .Data(1,i)/Total * 100
              .AxisLbl.Text = FORMAT$("%-3.1f", pct) + " %"

            CASE csPieVal
              .AxisLbl.Text = FORMAT$("%-4.4g", .Data(1,i))

            CASE ELSE
              .AxisLbl.Text = ""
          END SELECT

          .AxisLbl.Left = .XAxis.Ori + xSize/2 + (Radius + TxtFactor)*_
                          COS(pi2 * (Cum -.Data(1,i)/2) / Total)
          .AxisLbl.Top = .YAxis.Ori - ySize/2 - (Radius + TxtFactor)*_
                         SIN(pi2 * (Cum -.Data(1,i)/2) / Total)
          IF COS(pi2 * (Cum - .Data(1,i)/2) / Total) < 0 THEN ' align left
            .AxisLbl.Left = .AxisLbl.Left - .Buffer.TextWidth(RTRIM$(.AxisLbl.Text))
          END IF
          .Buffer.TextOut (.AxisLbl.Left, .AxisLbl.Top, RTRIM$(.AxisLbl.Text),_
                           .Buffer.Font.COLOR, .bgColor)
          x1 = x2                                         'Update wedge start position
          y1 = y2

        END IF 'missing
      NEXT i

    END WITH
    QCHART.ChartExists = TRUE

  END SUB
'------------------------------------------------------------------------------------------
SUB DrawReal (Overlay AS INTEGER)
  'X Points are (OriX + VAL * XScaleFactor - XMin) (ScaleFactor = Axis.Len / Axis.Max)
  'Y Points are (OriY - VAL * YScaleFactor - YMin) (i.e. ^^  = Pixels per Unit)

    DIM i  AS INTEGER                               'Loop counters...
    DIM j  AS INTEGER
    DIM x1 AS SINGLE                                'for readability
    DIM y1 AS SINGLE
    DIM x2 AS SINGLE
    DIM y2 AS SINGLE
    DIM Start AS INTEGER

    IF Overlay = FALSE THEN
      WITH QCHART                                   'Set up the chart window
        .ChartStyle = csLines                       'Force to Lines only
        IF .Viewport < 0 OR .Rows <= .Viewport THEN 'Normal, plot all cols
          Start = 1
        ELSE                                        'Plot only those last X Points
          Start = .Rows - .Viewport                 'specified in .Viewport property
        END IF
        .ClearBuffer                                 'erase the current bitmap
        .SetSize
        .SetScale (1,.Rows)                          'Scales to all data
'        .SetScale (Start,.Rows)                      'Scales to Viewport data
        IF .Success = FALSE THEN                     'Log Scaling failed
          .ClearAll
          EXIT SUB
        END IF
        .SetSeries
        .XAxis.DrawZero = FALSE                      'No Values on the X
        .DrawAxes
        .DrawTitles
        .XAxis.Labeled = FALSE                       'Label X Axis locally (see below)
        .DrawLabels                                  'Label the Y Axis
        .DrawLegend
      END WITH
    END IF

    WITH QCHART
      '---- Label start and end values of X Axis
      .AxisLbl.Text = .LabelList.Item(0)
      .AxisLbl.Left = .XAxis.Ori - .Buffer.TextWidth(RTRIM$(.AxisLbl.Text)) / 2
      .AxisLbl.Top = .YAxis.Ori + .Buffer.TextHeight(.AxisLbl.Text) / 2
      .Buffer.TextOut (.AxisLbl.Left, .AxisLbl.Top,RTRIM$(.AxisLbl.Text),_
                       .Buffer.Font.COLOR, .bgColor)

      .AxisLbl.Text = .LabelList.Item(1)
      .AxisLbl.Left = .XAxis.Ori + .XAxis.Len_
                       - .Buffer.TextWidth(RTRIM$(.AxisLbl.Text)) / 2
      .AxisLbl.Top = .YAxis.Ori + .Buffer.TextHeight(.AxisLbl.Text) / 2
      .Buffer.TextOut (.AxisLbl.Left, .AxisLbl.Top,RTRIM$(.AxisLbl.Text),_
                       .Buffer.Font.COLOR, .bgColor)

      IF .Viewport > 0 THEN
        .XAxis.TicIntvl = .XAxis.LEN / .Viewport
      ELSE
        .XAxis.TicIntvl = .XAxis.LEN / (.Rows - 1)
      END IF

      qcSetBkColor (.Buffer.Handle, .PlotAreaColor)
      FOR i = 1 to .Cols
        .hPen = qcCreatePen(.Series(i).LineStyle, .Series(i).LineWidth, .Series(i).COLOR)
        .OldPen = qcSelectObject(.Buffer.Handle, .hPen)
        FOR j = Start TO .Rows - 1

          IF .Data(i,j)=.Missing OR .Data(i,j+1)=.Missing THEN GOTO NoPlotRealLn

          IF j = Start THEN
            x1 = .XAxis.Ori
          ELSE
            x1 = x2
          END IF
          x2 = x1 + .Xaxis.TicIntvl

          IF .YAxis.LogScale = FALSE THEN
            y1 = .YAxis.Ori - (.Data(i,j)-.YAxis.Min) * .YAxis.ScaleFactor
            y2 = .YAxis.Ori - (.Data(i,j+1)-.YAxis.Min) * .YAxis.ScaleFactor
          ELSE
            y1 = .YAxis.Ori - (.qcLog10(.Data(i,j))-.YAxis.Min) *.YAxis.ScaleFactor
            y2 = .YAxis.Ori - (.qcLog10(.Data(i,j+1))-.YAxis.Min) *.YAxis.ScaleFactor
          END IF

          '--- Use API to draw lines
          qcMoveToEx(.Buffer.handle,x1,y1,0)
          qcLineTo(.Buffer.handle,x2,y2)

NoPlotRealLn:
        NEXT j
        qcDeleteObject(qcSelectObject(.Buffer.Handle, .OldPen))
      NEXT i
    END WITH

    QCHART.ChartExists = TRUE

END SUB

'------------------------------------------------------------------------------------------
'------------------------- Public Methods -------------------------------------------------
'------------------------------------------------------------------------------------------
PUBLIC:
  SUB DrawChart(Overlay AS INTEGER)

    WITH QCHART
      SELECT CASE .ChartType
        CASE ctBar
          .DrawBar(Overlay, 0)
        CASE ctXY
          .DrawXY(Overlay)
        CASE ctLine
          .DrawLine(Overlay, 0)
        CASE ctBox
          .DrawBox(Overlay)
        CASE ctPie
          .DrawPie(Overlay)
        CASE ctHiLo
          .DrawHiLo(Overlay)
        CASE ctReal
          .DrawReal(Overlay)
        CASE ctBarLine
          .ChartType = ctBar
          .ChartStyle = csBar
          .DrawBar(Overlay, 1)
          .ChartType = ctLine
          .ChartStyle = csBoth
          .DrawLine(TRUE, 2)
          .ChartType = ctBarLine                          'Reset type for redraws
      END SELECT
      IF .Printing = FALSE THEN .PaintChart
    END WITH

  END SUB
'-------------------------------------------------------------------------------------------
PUBLIC:
  SUB RedrawChart               '<--- Call this SUB from your FORM.OnResize EVENT SUB

    WITH QCHART
      .Buffer.Width =  .ClientWidth                       'recalc dimensions
      .Buffer.Height = .ClientHeight
      IF .ChartExists = TRUE THEN .DrawChart(FALSE)       'only redraw if ChartExists
    END WITH

  END SUB
'-------------------------------------------------------------------------------------------
PUBLIC:
  SUB PrintChart (Prn AS INTEGER, Orient AS INTEGER, Margin AS INTEGER,_
                  Copies AS INTEGER, Colr AS BYTE)
  'Prints copies of graph to a full page with a user specified margin and orientation
  'Colr is Boolean: TRUE = Use color for printing, FALSE = Use B&W for printing

    DIM Source    AS QRect
    DIM Page      AS QRect
    DIM OldBW     AS BYTE

    IF QCHART.ChartExists = FALSE THEN EXIT SUB           'Don't print nonexistent chart

    WITH QCHART

      PRINTER.PrinterIndex = Prn
      PRINTER.Orientation = Orient
      PRINTER.Copies = Copies

      IF Orient = 0 THEN                                  'Portrait
        .Buffer.Width = 1920                              'Scale to page size
        .Buffer.Height = 2400
      ELSE                                                'Landscape
        .Buffer.Width = 2560
        .Buffer.Height = 1920
      END IF
                                                          'Set page size
      Page.Top = Margin
      Page.Left = Margin
      Page.Right = .Left + PRINTER.PageWidth - (Margin * 2)
      Page.Bottom = .Top + PRINTER.PageHeight - (Margin * 2)

      Source.Top = 0                                      'Set source size
      Source.Left = 0
      Source.Right = Source.Left + QCHART.Buffer.Width
      Source.Bottom = Source.Top + QCHART.Buffer.Height

      .MainFont.Size = .MainFont.Size * 3                 'Increase font sizes
      .SubFont.Size = .SubFont.Size * 3
      .AxisFont.Size = .AxisFont.Size * 3
      .LegendFont.Size = .LegendFont.Size * 3
      .MarkerSize = .MarkerSize * 3

      IF Colr = FALSE THEN
        OldBW = .BW                                       'Remember BW setting
        .BW = TRUE                                        'Change to BW for Printing
      END IF

      IF .XAxis.AutoScale = TRUE THEN                     'Keep same Axis Scales
        .XAxis.AutoScale = NOT .XAxis.AutoScale           'turn off Autoscale
      END IF
      IF .YAxis.AutoScale = TRUE THEN                     'Keep same Axis Scales
        .YAxis.AutoScale = NOT .YAxis.AutoScale           'turn off Autoscale
      END IF

      .Printing = TRUE                                    'Prevent screen redraw
      .DrawChart(FALSE)                                   'Redraw at Page Size

      PRINTER.BeginDoc                                    'Print it
        PRINTER.CopyRect(Page, QCHART.Buffer, Source)
      PRINTER.EndDoc

      .MainFont.Size = .MainFont.Size / 3                 'Restore to screen size
      .SubFont.Size = .SubFont.Size / 3
      .AxisFont.Size = .AxisFont.Size / 3
      .LegendFont.Size = .LegendFont.Size / 3
      .MarkerSize = .MarkerSize / 3
      IF Colr = FALSE THEN .BW = OldBW                    'Restore BW setting
      IF .XAxis.AutoScale = -2 THEN                       'AutoScale was changed
        .XAxis.AutoScale = NOT .XAxis.AutoScale           'Change it back
      END IF
      IF .YAxis.AutoScale = -2 THEN                       'AutoScale was changed
        .YAxis.AutoScale = NOT .YAxis.AutoScale           'Change it back
      END IF
      .ReDrawChart                                        'Redraw at Screen size
      .Printing = FALSE                                   'Reset Flag
    END WITH

  END SUB
'-------------------------------------------------------------------------------------------
PUBLIC:
  SUB CopyToClipboard (Wid AS INTEGER, Hgt AS INTEGER)

    DIM hBitmap AS INTEGER
    DIM Bitmap AS QBITMAP
    DIM Scale AS SINGLE
    DIM OldMain AS INTEGER
    DIM OldSub AS INTEGER
    DIM OldAxis AS INTEGER
    DIM OldLegend AS INTEGER
    DIM OldMarker AS INTEGER

    WITH QCHART

      OldMain = .MainFont.Size                                  'Remember
      OldSub = .SubFont.Size
      OldAxis = .AxisFont.Size
      OldLegend = .LegendFont.Size
      OldMarker = .MarkerSize

      Scale = (Hgt + Wid) / (.Buffer.Height + .Buffer.Width)    'Rescale
      .MainFont.Size = .MainFont.Size * Scale
      .SubFont.Size = .SubFont.Size * Scale
      .AxisFont.Size = .AxisFont.Size * Scale
      .LegendFont.Size = .LegendFont.Size * Scale
      .MarkerSize = .MarkerSize * Scale

      .Buffer.Height = Hgt                                      'Redraw off screen
      .Buffer.Width = Wid
      .Printing = TRUE
      .DrawChart(FALSE)

      Bitmap.BMP=.Buffer.BMP                                    'Make a copy of Buffer
      Bitmap.PixelFormat=0
      hBitmap=qcGetCurrentObjectBmp(bitmap.handle,7)

      Clipboard.Open                                            'Copy to Clipboard
        Clipboard.Clear
        Clipboard.SetAsHandle(2,hBitmap)
      Clipboard.Close

      .MainFont.Size = OldMain                                  'Restore
      .SubFont.Size = OldSub
      .AxisFont.Size = OldAxis
      .LegendFont.Size = OldLegend
      .MarkerSize = OldMarker

      .RedrawChart
      .Printing = FALSE

    END WITH

  END SUB
'-------------------------------------------------------------------------------------------
PUBLIC:
  SUB SaveChart (SaveAs AS BYTE)

    DIM File AS QFILESTREAM

    IF SaveAs = TRUE THEN GOTO qcShowSave
    WITH QCHART

      IF .CurrFile <> "NewChart.bmp" THEN                 'The file has been saved before
        File.Open(.dlgSaveQC.FileName, 65535)             '65535 = fmCreate
          .Buffer.SaveToStream (File)                     'save the data
        File.Close
        EXIT SUB
      END IF

qcShowSave:
      IF SaveAs = TRUE THEN
        .dlgSaveQC.Caption = "Save Graph As"
      ELSE
        .dlgSaveQC.Caption = "Save Graph"
      END IF
      .dlgSaveQC.FileName = .CurrFile
      .dlgSaveQC.Filter = "Bitmap Files|*.bmp|All Files|*.*"
      .dlgSaveQC.FilterIndex = 1

      IF .dlgSaveQC.Execute AND LEN(.dlgSaveQC.FileName) <> 0 THEN

        IF INSTR(UCASE$(.dlgSaveQC.FileName), ".BMP") = 0 THEN
         .dlgSaveQC.FileName = .dlgSaveQC.FileName + ".bmp"
        END IF

        IF FILEEXISTS(.dlgSaveQC.FileName) THEN           'check if file exists
          DIM Response AS INTEGER                         'ask user for decision
          Response =  MESSAGEDLG("File Already Exists. Overwrite " + .dlgSaveQC.FileName + "?",_
                                  0, 1 OR 2 OR 8, 0)      ' Y OR N OR Cancel
          SELECT CASE Response
            CASE 7                                        ' NO; don't overwrite, ask again
              GOTO qcShowSave                             '<--- Use of a local GOTO loop!
            CASE 2                                        'CANCEL;don't overwrite, don't ask again
              EXIT SUB
          END SELECT
        END IF

        File.Open(.dlgSaveQC.FileName, 65535)             '65535 = fmCreate
          .Buffer.SaveToStream (File)                     'save the data
        File.Close

        .CurrFile = .dlgSaveQC.FileName
      END IF
    END WITH

  END SUB
'-------------------------------------------------------------------------------------------


'-------------------------------------------------------------------------------------------
PUBLIC:
SUB SaveToFile (FileName AS String)

    DIM File AS QFILESTREAM

        File.Open(FileName, 65535)             '65535 = fmCreate
        QCHART.Buffer.SaveToStream (File)                     'save the data
        File.Close
        EXIT SUB

  END SUB
'-------------------------------------------------------------------------------------------

  CONSTRUCTOR

    Parent =            QFORM
    Missing =           -9.999E-45              'A rare value
    Viewport =          100

    '--- Expand and/or Redefine any way you like
    Colors(0) = RGB(0,0,0)              '-- Black
    Colors(1) = RGB(0,0,175)            '-- Blue
    Colors(2) = RGB(175,0,0)            '-- Red
    Colors(3) = RGB(0,175,0)            '-- Green
    Colors(4) = RGB(0,175,175)          '-- Cyan
    Colors(5) = RGB(175,0,175)          '-- Magenta
    Colors(6) = RGB(192,192,0)          '-- Yellow
    Colors(7) = RGB(75,75,225)          '-- Soft Blue
    Colors(8) = RGB(225,75,75)          '-- Soft Red
    Colors(9) = RGB(75,225,75)          '-- Soft Green
    Colors(10) = RGB(75,215,230)        '-- Soft Cyan
    Colors(11) = RGB(215,75,215)        '-- Soft Magenta
    Colors(12) = RGB(215,230,75)        '-- Soft Yellow
    Colors(13) = RGB(128,128,255)       '-- Torquoise
    Colors(14) = RGB(240,128,128)       '-- Rose Red
    Colors(15) = RGB(192,220,192)       '-- Money Green
    Colors(16) = RGB(166,202,240)       '-- Sky Blue
    Colors(17) = RGB(199,177,255)       '-- Lavender
    Colors(18) = RGB(255,226,177)       '-- Peach
    Colors(19) = RGB(0,0,255)           '-- Bright Blue
    Colors(20) = RGB(255,0,0)           '-- Bright Red
    Colors(21) = RGB(0,255,0)           '-- Bright Green
    Colors(22) = RGB(0,255,255)         '-- Bright Cyan
    Colors(23) = RGB(255,0,255)         '-- Bright Magenta
    Colors(24) = RGB(255,255,0)         '-- Bright Yellow
    Colors(25) = RGB(255,153,51)        '-- Orange
    Colors(26) = RGB(255,51,153)        '-- Pink
    Colors(27) = RGB(80,80,80)          '-- Dark Grey
    Colors(28) = RGB(128,128,128)       '-- Med Grey
    Colors(29) = RGB(208,208,208)       '-- Light Grey
    Colors(30) = RGB(255,255,255)       '-- Bright White


      bgColor =        Colors(30)   'Bright White
      fgColor =        Colors(23)    'Black
      PlotAreaColor =  Colors(4)   'Light Grey
      GridColor =      Colors(25)   'Dark Grey

  END CONSTRUCTOR


END TYPE'QChart
'----- End Object Definition ***************************************************************
