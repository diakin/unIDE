$IFNDEF __QDIGDISPLAY_INC   ' IncManager: include guard
$DEFINE __QDIGDISPLAY_INC
' QDigDisplay component for Rapid-Q by Peter Molloy
' ver : 1.00
' 13 April 2001
' teliah@optushome.com.au



TYPE QDigDisplay EXTENDS QCanvas
     PRIVATE :
              DImage AS QIMAGELIST              
     PUBLIC : 
              Left AS LONG
              Top AS LONG
              Width AS LONG
              Height AS LONG
              Display AS STRING
              
     constRUCTOR
              DImage.Width = 12
              DImage.Height = 24
              DImage.BkColor = clDefault
              DImage.AddBMPFile "32.bmp", 0
              DImage.AddBMPFile "33.bmp", 0
              DImage.AddBMPFile "34.bmp", 0
              DImage.AddBMPFile "35.bmp", 0
              DImage.AddBMPFile "36.bmp", 0
              DImage.AddBMPFile "37.bmp", 0
              DImage.AddBMPFile "38.bmp", 0
              DImage.AddBMPFile "39.bmp", 0
              DImage.AddBMPFile "40.bmp", 0
              DImage.AddBMPFile "41.bmp", 0
              DImage.AddBMPFile "42.bmp", 0
              DImage.AddBMPFile "43.bmp", 0
              DImage.AddBMPFile "44.bmp", 0
              DImage.AddBMPFile "45.bmp", 0
              DImage.AddBMPFile "46.bmp", 0
              DImage.AddBMPFile "47.bmp", 0
              DImage.AddBMPFile "48.bmp", 0
              DImage.AddBMPFile "49.bmp", 0
              DImage.AddBMPFile "50.bmp", 0
              DImage.AddBMPFile "51.bmp", 0
              DImage.AddBMPFile "52.bmp", 0
              DImage.AddBMPFile "53.bmp", 0
              DImage.AddBMPFile "54.bmp", 0
              DImage.AddBMPFile "55.bmp", 0
              DImage.AddBMPFile "56.bmp", 0
              DImage.AddBMPFile "57.bmp", 0
              DImage.AddBMPFile "58.bmp", 0
              DImage.AddBMPFile "59.bmp", 0 
              DImage.AddBMPFile "60.bmp", 0
              DImage.AddBMPFile "61.bmp", 0
              DImage.AddBMPFile "62.bmp", 0
              DImage.AddBMPFile "63.bmp", 0
              DImage.AddBMPFile "64.bmp", 0 
              Display = "0"        
     END constRUCTOR
              
     SUB DrawDisplay 
         WITH QDigDisplay              
              .Height = QDigDisplay.DImage.Height 
              .Width = QDigDisplay.DImage.Width * LEN(.Display)
              .ClientWidth = .Width
                     FOR L = 0 TO LEN(.Display)-1
                             N = ASC(MID$(.Display,L+1))-32
                                 .Draw(.Left + L* QDigDisplay.DImage.Width,.Top, _
                                 QDigDisplay.DImage.GetBMP(N))
                     NEXT 
               
         END WITH      
     END SUB
     EVENT OnPaint 
           QDigDisplay.DrawDisplay
     END EVENT
     
     
END TYPE

  
$ENDIF   ' IncManager: __QDIGDISPLAY_INC
