''=============================================================
'' PrintRichedit include file, put it at top off the mainprogram.
'' Capable of printing selected text. 
'' Function prints the current text of a Qrichedit box,      Written by M.Waterman
'' usage:  PrintRiched(name of qrichedit control, leftmarge in pixels) 
'' Version 0.50  
''============================================================= 
function PrintRichedit(sender as qrichedit,lmarge as integer) as long
	dim m as qmemorystream,mirror as qrichedit,dummy as qform
  	dim fontdat as string,charset as string,field as integer,forecolor as integer
	dim fontnames as string,colortable as string,line as integer,linedat as string  
	dim x as integer,y as integer ,heighest as integer,fontname as string
	dim fontsize as integer,fontcharset as integer,startline as integer,endline as integer 
	x=lmarge:y=0 
	swap sender.plaintext,field
                mirror.plaintext=0:mirror.parent=dummy
	sender.plaintext=0
   	m.position=0:m.clear:m.size=0
	swap sender.plaintext,field
	if sender.sellength>0 then
		field=messagebox ("Do you want to print the selected text?" + chr$(13)+"(no = all text)","Print what?",3)
		if field=2 then :m.clear:result=1:exit function:end if
		if field=6 then  
			''print selection 
			sender.copytoclipboard
			mirror.clear
			mirror.pastefromclipboard 
			mirror.savetostream(m)
			endline=mirror.linecount
		else
			sender.savetostream(m)
			endline=sender.linecount
		end if
	else
 	 	sender.savetostream(m)
		endline=sender.linecount
	end if
	m.position=0:line=0:forecolor=0:startline=0
	printer.begindoc
               	linedat= m.readline-"}"-"{":inc(line)
 	while instr(linedat,"\pard")=0
		''create font/chartable
           		if instr(linedat,"\fonttbl")>0 then
  			linedat=right$(linedat,len(linedat)-instr(linedat,"\fonttbl")-7)
			''fontdata
   			charset="":fontnames=""
   			for field=1 to tally(linedat,";")
     				fontdat=field$( field$(linedat,";",field),"\",5)
    				charset=charset+field$(fontdat," ",1)+"#"
    				fontnames=fontnames+right$(fontdat,len(fontdat)-instr(fontdat," "))+"#"
  			next field 
			charset=charset-"fcharset"
         		end if 
		''colortable
          		if instr(linedat,"\colortbl ")>0 then
			colortable="0#"
			linedat=right$(linedat,len(linedat)-instr(linedat,"\colortbl"))
             			for field=2 to tally(linedat,";")
				linedat=linedat-"red"-"blue"-"green"
				fontdat=field$(linedat,";",field)
 				colortable=colortable+str$(val(field$(fontdat,"\",2))+val(field$(fontdat,"\",3))*256+val(field$(fontdat,"\",4))*256^2)+"#"
			next field 
          		end if       
 		linedat= m.readline
		linedat=replacesubstr$(linedat,"\}",chr$(0))
		linedat=replacesubstr$(linedat,"\{",chr$(1))
		linedat=replacesubstr$(linedat,"\\",chr$(2)) 
		linedat=linedat-"}"-"{":inc(line)
	wend
	linedat=right$(linedat,len(linedat)-instr(linedat,"\pard")-4)
	startline=startline+line:endline=endline+line-1
	if startline=endline then inc(endline)
	''line loop
	while line <endline
		heighest=0 
		linedat=replacesubstr$(linedat," "," \1#" )
 		linedat=replacesubstr$(linedat,"\par","\2#" )
		linedat=replacesubstr$(linedat,"\strike","\3#" )
		linedat=replacesubstr$(linedat,"\ul","\4#" )
		linedat=replacesubstr$(linedat,"\cf","\5#" )
		linedat= replacesubstr$(linedat,"\fs","\6#")
		linedat= replacesubstr$(linedat,"\f","\7#")
		linedat=replacesubstr$(linedat,"\b","\8#" )
		linedat=replacesubstr$(linedat,"\i","\9#" )
		linedat=replacesubstr$(linedat,"\'","\10#" )
 		swap fontsize,printer.font.size
		swap fontname,printer.font.name
		swap fontcharset,printer.font.charset 
		for field=1 to tally(linedat,"\")+1
 			fontdat= field$(linedat,"\",field)
 			select case field$( fontdat,"#",1)
 				case "1" ''text
					if heighest<printer.textheight (field$(fontdat,"#",2)) then
						heighest=printer.textheight (field$(fontdat,"#",2)) 
					end if 
				case "2" ''emptyline 
					if heighest<printer.textheight (" ") then
						heighest=printer.textheight (" ") 
					end if 
    				case "6" ''fontsize 
					printer.font.size=val(field$(fontdat,"#",2))/2
				case "7" ''fontname	
					printer.font.name=field$(fontnames,"#",val(field$(fontdat,"#",2))+1)		
					printer.font.charset=val(field$(charset,"#",val(field$(fontdat,"#",2))+1))
 			end select  
		next field 
		y=y+heighest
		swap fontsize,printer.font.size
		swap fontname,printer.font.name
		swap fontcharset,printer.font.charset 
		for field=1 to tally(linedat,"\")+1
 			fontdat= field$(linedat,"\",field)
 			select case field$( fontdat,"#",1)
 				case "1" ''text
					fontdat=replacesubstr$(fontdat,chr$(0),"}")
					fontdat=replacesubstr$(fontdat,chr$(1),"{")
					fontdat=replacesubstr$(fontdat,chr$(2),"\")
					if x+printer.textwidth(fontdat)>printer.pagewidth then 
						x=lmarge
						y=y+heighest
					end if 
					if y>printer.pageheight then 
						y=heighest
						printer.newpage
					end if 
					printer.textout(x,y-printer.textheight( field$(fontdat,"#",2)), field$(fontdat,"#",2),forecolor,-1)
					x=x+printer.textwidth(field$(fontdat,"#",2))			
				case "3" ''strikeout 
 					if rtrim$(field$( fontdat,"#",2))="0" then
    						printer.font.delstyles (3) 
 					else
   						printer.font.addstyles (3) 
 					end if
				case "4" ''underline 
					if rtrim$(field$( fontdat,"#",2))="none" then
  						printer.font.delstyles (2)
					else
  						printer.font.addstyles (2)
					end if 
				case "5" ''color 
					forecolor=val( field$(colortable,"#",val(field$(fontdat,"#",2))+1))
				case "6" ''fontsize 
					printer.font.size=val(field$(fontdat,"#",2))/2
				case "7" ''fontname	
					printer.font.name=field$(fontnames,"#",val(field$(fontdat,"#",2))+1)		
					printer.font.charset=val(field$(charset,"#",val(field$(fontdat,"#",2))+1))
				case "8" ''bold
 					if rtrim$(field$( fontdat,"#",2))="0" then
  						printer.font.delstyles (0)
					else
  						printer.font.addstyles (0)
					end if 
				case "9" ''italic
 					if rtrim$(field$( fontdat,"#",2))="0" then
    						printer.font.delstyles (1) 
 					else
   						printer.font.addstyles (1) 
 					end if
				case "10" ''special signs bytecode
					fontdat=chr$(val(convbase$(rtrim$(ucase$(field$( fontdat,"#",2))),16,10)))  
					printer.textout(x,y-printer.textheight(fontdat),fontdat,forecolor,-1)
					x=x+printer.textwidth(fontdat)		
 			end select  
		next field 
		linedat= m.readline
		linedat=replacesubstr$(linedat,"\}",chr$(0))
		linedat=replacesubstr$(linedat,"\{",chr$(1))
		linedat=replacesubstr$(linedat,"\\",chr$(2)) 
		linedat=linedat-"}"-"{":inc(line)
 		x=0
	wend
	printer.enddoc 
end function
  