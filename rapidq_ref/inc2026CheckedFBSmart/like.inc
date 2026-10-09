
' LIKE Function - pattern matching routine for Rapid-Q by William Yu
' This emulates the VB LIKE operator.
' Thanks to Thomas Binder for the original C code
'
' ?   Any single character.
' *   Zero or more characters.
' #   Any single digit (0-9).
' [charlist]  Any single character in charlist.
' [!charlist] Any single character not in charlist.
'
' A group of one or more characters (charlist) enclosed in brackets ([ ])
' can be used to match any single character in string and can include almost
' any character code, including digits.
'
' Note:   To match the special characters left bracket ([), question
' mark (?), number sign (#), and asterisk (*), enclose them in brackets.
' The right bracket (]) can't be used within a group to match itself, but
' it can be used outside a group as an individual character.
'
' By using a hyphen (-) to separate the upper and lower bounds of the range,
' charlist can specify a range of characters. For example, [A-Z] results in
' a match if the corresponding character position in string contains any
' uppercase letters in the range A-Z. Multiple ranges are included within
' the brackets without delimiters.


DECLARE FUNCTION Like(ParseString AS STRING, Pattern AS STRING) AS INTEGER
DECLARE FUNCTION IsDigit(S AS STRING) AS INTEGER

CONST INVERT = "!"       '-- Some like ^ or ~ instead, whatever you want

'*****************************************
FUNCTION IsDigit(S AS STRING) AS INTEGER
IF S >= "0" AND S <= "9" THEN
	IsDigit = 1
ELSE
	IsDigit = 0
END IF
END FUNCTION


'*****************************************
FUNCTION Like(ParseString AS STRING, Pattern AS STRING) AS INTEGER
DIM prev AS INTEGER, matched AS INTEGER, reverse AS INTEGER

WHILE Pattern <> ""
	SELECT CASE MID$(Pattern, 1, 1)
	CASE "?"
		IF ParseString = "" THEN
			Like = 0
			EXIT FUNCTION
		END IF
	CASE "#"
		IF IsDigit(MID$(ParseString, 1, 1)) = 0 THEN
			Like = 0
			EXIT FUNCTION
		END IF
	CASE "*"
		DO
		Pattern = MID$(Pattern, 2, LEN(Pattern)-1)
		LOOP UNTIL MID$(Pattern, 1, 1) <> "*"
		IF Pattern = "" THEN
			Like = 1
			EXIT FUNCTION
		END IF
		WHILE ParseString <> ""
			IF Like(ParseString, Pattern) THEN
				Like = 1
				EXIT FUNCTION
			END IF
			IF ParseString <> "" THEN
				ParseString = MID$(ParseString, 2, LEN(ParseString)-1)
			END IF
		WEND
		Like = 0
		EXIT FUNCTION
	CASE "["
		reverse = (MID$(Pattern, 2, 1) = INVERT)
		IF reverse THEN
			Pattern = MID$(Pattern, 2, LEN(Pattern)-1)
		END IF
		prev = 256: matched = 0
		DO
		Pattern = MID$(Pattern, 2, LEN(Pattern)-1)
		IF (Pattern <> "") AND (esc <> 0 OR MID$(Pattern, 1, 1) <> "]") THEN
			IF MID$(Pattern, 1, 1) = "-" THEN
				Pattern = MID$(Pattern, 2, LEN(Pattern)-1)
				IF Pattern = "" THEN
					Like = 0
					EXIT FUNCTION
				END IF
				matched = matched OR (MID$(ParseString, 1, 1) <= MID$(Pattern, 1, 1) AND ASC(MID$(ParseString, 1, 1)) >= prev)
			ELSE
				matched = matched OR (MID$(ParseString, 1, 1) = MID$(Pattern, 1, 1))
			END IF
			prev = ASC(MID$(Pattern, 1, 1))
		ELSE
			EXIT DO
		END IF
		esc = 0
		LOOP
		IF (prev = 256 OR MID$(Pattern, 1, 1) <> "]" OR ABS(matched) = ABS(reverse)) THEN
			Like = 0
			EXIT FUNCTION
		END IF
	CASE ELSE
		IF MID$(ParseString, 1, 1) <> MID$(Pattern, 1, 1) THEN
			Like = 0
			EXIT FUNCTION
		END IF
	END SELECT
	ParseString = MID$(ParseString, 2, LEN(ParseString)-1)
	Pattern = MID$(Pattern, 2, LEN(Pattern)-1)
WEND

Like = ABS(LEN(ParseString) = 0)
END FUNCTION


'-- Test code

'print "Like('24','##')=", Like("24","##")

'?"Like(aBBBa, a*a)=", Like("aBBBa","a*a")
'?Like("F","[!A-Z]")
'?Like("a2a","a#a")
'?Like("aM5b","a[A-GL-P]#[!c-e]")
'?Like("BAT123khg","B?T*")
'?Like("CAT123khg","B?T*")

'?Like("Combine(10, 20) = 30", "*(*?,*?)*=*#")
