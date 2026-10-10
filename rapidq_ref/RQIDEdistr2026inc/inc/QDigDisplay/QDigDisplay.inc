' QDigDisplay component for Rapid-Q by Peter Molloy
' ver : 1.01
' 15 April 2001
' teliah@optushome.com.au

bmpdir$=""'CURDIR$+"QDigDisplay\"

TYPE QDigDisplay EXTENDS QCanvas
     PRIVATE :
              DImage AS QIMAGELIST
              DRect AS QRECT
              SRect AS QRECT
              DBitMap AS QBITMAP
     PUBLIC : 
              Left AS LONG
              Top AS LONG
              Width AS LONG
              Height AS LONG
              Display AS STRING 
              
     CONSTRUCTOR
              DImage.Width = 12 
              DImage.Height = 24
              DImage.BkColor = clDefault
              DImage.AddBMPFile bmpdir$+"32.bmp", 0
              DImage.AddBMPFile bmpdir$+"33.bmp", 0
              DImage.AddBMPFile bmpdir$+"34.bmp", 0
              DImage.AddBMPFile bmpdir$+"35.bmp", 0
              DImage.AddBMPFile bmpdir$+"36.bmp", 0
              DImage.AddBMPFile bmpdir$+"37.bmp", 0
              DImage.AddBMPFile bmpdir$+"38.bmp", 0
              DImage.AddBMPFile bmpdir$+"39.bmp", 0
              DImage.AddBMPFile bmpdir$+"40.bmp", 0
              DImage.AddBMPFile bmpdir$+"41.bmp", 0
              DImage.AddBMPFile bmpdir$+"42.bmp", 0
              DImage.AddBMPFile bmpdir$+"43.bmp", 0
              DImage.AddBMPFile bmpdir$+"44.bmp", 0
              DImage.AddBMPFile bmpdir$+"45.bmp", 0
              DImage.AddBMPFile bmpdir$+"46.bmp", 0
              DImage.AddBMPFile bmpdir$+"47.bmp", 0
              DImage.AddBMPFile bmpdir$+"48.bmp", 0
              DImage.AddBMPFile bmpdir$+"49.bmp", 0
              DImage.AddBMPFile bmpdir$+"50.bmp", 0
              DImage.AddBMPFile bmpdir$+"51.bmp", 0
              DImage.AddBMPFile bmpdir$+"52.bmp", 0
              DImage.AddBMPFile bmpdir$+"53.bmp", 0
              DImage.AddBMPFile bmpdir$+"54.bmp", 0
              DImage.AddBMPFile bmpdir$+"55.bmp", 0
              DImage.AddBMPFile bmpdir$+"56.bmp", 0
              DImage.AddBMPFile bmpdir$+"57.bmp", 0
              DImage.AddBMPFile bmpdir$+"58.bmp", 0
              DImage.AddBMPFile bmpdir$+"59.bmp", 0 
              DImage.AddBMPFile bmpdir$+"60.bmp", 0
              DImage.AddBMPFile bmpdir$+"61.bmp", 0
              DImage.AddBMPFile bmpdir$+"62.bmp", 0
              DImage.AddBMPFile bmpdir$+"63.bmp", 0
              DImage.AddBMPFile bmpdir$+"64.bmp", 0 
              DImage.AddBMPFile bmpdir$+"65.bmp", 0
              DImage.AddBMPFile bmpdir$+"66.bmp", 0 
              DImage.AddBMPFile bmpdir$+"67.bmp", 0 
              DImage.AddBMPFile bmpdir$+"68.bmp", 0
              DImage.AddBMPFile bmpdir$+"69.bmp", 0
              DImage.AddBMPFile bmpdir$+"70.bmp", 0
              DImage.AddBMPFile bmpdir$+"71.bmp", 0
              DImage.AddBMPFile bmpdir$+"72.bmp", 0
              DImage.AddBMPFile bmpdir$+"73.bmp", 0
              DImage.AddBMPFile bmpdir$+"74.bmp", 0
              DImage.AddBMPFile bmpdir$+"75.bmp", 0
              DImage.AddBMPFile bmpdir$+"76.bmp", 0
              DImage.AddBMPFile bmpdir$+"77.bmp", 0 
              DImage.AddBMPFile bmpdir$+"78.bmp", 0
              DImage.AddBMPFile bmpdir$+"79.bmp", 0
              DImage.AddBMPFile bmpdir$+"80.bmp", 0
              DImage.AddBMPFile bmpdir$+"81.bmp", 0
              DImage.AddBMPFile bmpdir$+"82.bmp", 0
              DImage.AddBMPFile bmpdir$+"83.bmp", 0
              DImage.AddBMPFile bmpdir$+"84.bmp", 0
              DImage.AddBMPFile bmpdir$+"85.bmp", 0
              DImage.AddBMPFile bmpdir$+"86.bmp", 0
              DImage.AddBMPFile bmpdir$+"87.bmp", 0
              DImage.AddBMPFile bmpdir$+"88.bmp", 0
              DImage.AddBMPFile bmpdir$+"89.bmp", 0 
              DImage.AddBMPFile bmpdir$+"90.bmp", 0                   
              Display = "0"
              
              
     END CONSTRUCTOR
     
     
         
     SUB DrawDisplay 
         WITH QDigDisplay              
              .Height = QDigDisplay.DImage.Height 
              .Width = QDigDisplay.DImage.Width * LEN(.Display)
              .ClientWidth = .Width + .Left
                     FOR L = 0 TO LEN(.Display)-1
                             N = ASC(MID$(.Display,L+1))
                             IF N > 90 THEN N = N - 32
                             N = N - 32
                                 .Draw(.Left + L* QDigDisplay.DImage.Width,.Top, _
                                 QDigDisplay.DImage.GetBMP(N))
                     NEXT 
               
         END WITH      
     END SUB

     EVENT OnPaint 
           QDigDisplay.DrawDisplay
     END EVENT
     
     
END TYPE

