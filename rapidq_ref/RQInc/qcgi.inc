'QCGI.INC
'©2001-2005 Chris Warrington
'    rapidq.basic.c45207@spamgourmet.com
'
'Version: 1.6
'	Date: 2005-Feb-22
'Uses some modifications by C. Baker <yahoojunk@pacific-steel.com> (18-SEPT-2003):
' - Only one pass through the query string
' - Replaced a do/while loop with the faster for/next loop

'This program is free software; you can redistribute it and/or modify
'it under the terms of the GNU General Public License as published by
'the Free Software Foundation; either version 2 of the License, or
'(at your option) any later version.
'
'This program is distributed in the hope that it will be useful,
'but WITHOUT ANY WARRANTY; without even the implied warranty of
'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'GNU General Public License for more details.
'
'You should have received a copy of the GNU General Public License
'along with this program; if not, write to the Free Software
'Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
'
'A copy of the GNU General Public License can be found in the file gpl.txt
'
'The GNU General Public License allows you to USE this library in any of your programs,
'but you MUST release the source code. If you modify this library, those changes must
'also be released. Be sure to see gpl.txt for the legal mumbo-jumbo

$IFNDEF _QCGI_INC
$DEFINE _QCGI_INC

CONST CGI_INPUT_DEFAULT = 32767
CONST CGI_INPUT_LARGE = 65535
CONST CGI_INPUT_SMALL = 255

CONST CGI_MAX_PAIRS = 256

TYPE QCGI EXTENDS QOBJECT
	PUBLIC:
		'Properties
		MaxInput    AS INTEGER PROPERTY SET SetMaxInput
		AutoConvert AS BYTE PROPERTY SET SetAutoConvert

	PRIVATE:

		'CGI Variables
		_Accept AS STRING
		_AuthType AS STRING
		_ContentLength AS INTEGER
		_ContentType AS STRING
		_Cookie AS STRING
		_GatewayInterface AS STRING
		_PathInfo AS STRING
		_PathTranslated AS STRING
		_Referer AS STRING
		_RemoteAddr AS STRING
		_RemoteHost AS STRING
		_RemoteIdent AS STRING
		_RemoteUser AS STRING
		_RequestMethod AS STRING
		_ScriptName AS STRING
		_ServerSoftware AS STRING
		_ServerName AS STRING
		_ServerPort AS INTEGER
		_ServerProtocol AS STRING
		_QueryString AS STRING
		_UserAgent AS STRING

	PUBLIC:
		'Property Methods
		PROPERTY SET SetMaxInput(value AS INTEGER)
			IF (value > 0) THEN
				THIS.MaxInput = value
			END IF
		END PROPERTY

		PROPERTY SET SetAutoConvert(value AS BYTE)
			IF  (value = 1) THEN
				THIS.AutoConvert = 1
			ELSE
				THIS.AutoConvert = 0
			END IF
		END PROPERTY

		FUNCTION Accept AS STRING
			Result = THIS._Accept
		END FUNCTION

		FUNCTION AuthType AS STRING
			Result = THIS._AuthType
		END FUNCTION

		FUNCTION ContentLength AS INTEGER
			Result = THIS._ContentLength
		END FUNCTION

		FUNCTION ContentType AS STRING
			Result = THIS._ContentType
		END FUNCTION

		FUNCTION Cookie AS STRING
			Result = THIS._Cookie
		END FUNCTION

		FUNCTION GatewayInterface AS STRING
			Result = THIS._GatewayInterface
		END FUNCTION

		FUNCTION PathInfo AS STRING
			Result = THIS._PathInfo
		END FUNCTION

		FUNCTION PathTranslated AS STRING
			Result = THIS._PathTranslated
		END FUNCTION

		FUNCTION Referer AS STRING
			Result = THIS._Referer
		END FUNCTION

		FUNCTION RemoteAddr AS STRING
			Result = THIS._RemoteAddr
		END FUNCTION

		FUNCTION RemoteHost AS STRING
			Result = THIS._RemoteHost
		END FUNCTION

		FUNCTION RemoteIdent AS STRING
			Result = THIS._RemoteIdent
		END FUNCTION

		FUNCTION RemoteUser AS STRING
			Result = THIS._RemoteUser
		END FUNCTION

		FUNCTION RequestMethod AS STRING
			Result = THIS._RequestMethod
		END FUNCTION

		FUNCTION ScriptName AS STRING
			Result = THIS._ScriptName
		END FUNCTION

		FUNCTION ServerSoftware AS STRING
			Result = THIS._ServerSoftware
		END FUNCTION

		FUNCTION ServerName AS STRING
			Result = THIS._ServerName
		END FUNCTION

		FUNCTION ServerPort AS INTEGER
			Result = THIS._ServerPort
		END FUNCTION

		FUNCTION ServerProtocol AS STRING
			Result = THIS._ServerProtocol
		END FUNCTION

		FUNCTION QueryString AS STRING
			Result = THIS._QueryString
		END FUNCTION

		FUNCTION UserAgent AS STRING
			Result = THIS._UserAgent
		END FUNCTION

	PRIVATE:
		'Internal Varibles
		total AS INTEGER 'the total number of name/value pairs stored
		pairs(1 TO CGI_MAX_PAIRS, 1 TO 2) AS STRING  'keeps the name/value pair
		parsed  AS BYTE  'a flag to tell if the query string has been parsed


		'Adds a new name/value pair to the collection
		FUNCTION InsertPair(name AS STRING, value AS STRING) AS INTEGER
			DEFINT insertIndex = 0

			'The list is kept in alphabetical order so a binary search can be used
			IF (CGI_MAX_PAIRS < THIS.total + 1) THEN 'cannot add any more
				Result = -1
				EXIT FUNCTION
			ELSEIF (THIS.total = 0) THEN 'first one
				insertIndex = 1
			ELSE 'normal case: find and move down
				'Find the index at which to inset the new pair
				insertIndex = 1
				WHILE ((insertIndex <= THIS.total) AND (THIS.pairs(insertIndex, 1) < name))
					insertIndex++
				WEND

				IF (THIS.pairs(insertIndex, 1) = name) THEN 'we are inserting the same name, so update the value
					THIS.pairs(insertIndex, 2) = value
					Result = insertIndex
					EXIT FUNCTION
				END IF

				'Move all the pairs down one in preparation for an insert
				DEFINT i = THIS.total
				WHILE (i >= insertIndex)
					THIS.pairs(i + 1, 1) = THIS.pairs(i, 1)
					THIS.pairs(i + 1, 2) = THIS.pairs(i, 2)
					i--
				WEND
			END IF

			THIS.pairs(insertIndex, 1) = name
			THIS.pairs(insertIndex, 2) = value

			THIS.total++
			Result = insertIndex
		END FUNCTION

		'Preforms a binary search to find the proper name/value pair
		FUNCTION FindPair(name AS STRING, BYREF value AS STRING) AS INTEGER
			IF (THIS.total = 0) THEN
				Result = -1
				EXIT FUNCTION
			END IF

			DEFINT high = THIS.total + 1, low = 0, find

			WHILE (high - low > 1)
				find = (high + low) / 2 'the middle of the two

				IF (THIS.pairs(find, 1) > name) THEN 'too high, look lower
					high = find
				ELSE 'too low, look higher
					low = find
				END IF
			WEND

			IF (low = 0) THEN
				Result = -1
			ELSEIF (THIS.pairs(low, 1) <> name) THEN
				Result = -1
			ELSE
				value = THIS.pairs(low, 2)
				Result = low
			END IF
		END FUNCTION

		'Looks ahead the given number of characters from the index in the given string. The string is passed BYREF for preformance
		FUNCTION LookAhead(BYREF str AS STRING, num AS INTEGER, index AS INTEGER) AS STRING
			IF (index + num) > LEN(str) THEN 'make sure we can look ahead
				Result = ""
				EXIT FUNCTION
			ELSE
				Result = MID$(str, index + 1, num) 'look ahead preview& from, but not including, index&
			END IF
		END FUNCTION

		'Decodes a two-digit hex number into its ASCII character
		FUNCTION SimpleDeHex(chars$ AS STRING) AS STRING
			Result = ""
			IF LEN(chars$) <> 2 THEN 'make sure we don't have too many or too few
				EXIT FUNCTION
			ELSE
				DEFINT charAsc = VAL(CONVBASE$(UCASE$(chars$), 16, 10)) 'convert from base 16 (hex) to base 10
				IF (charAsc >= ASC(" ") AND charAsc <= ASC("~")) THEN 'make sure it is a "printable" character
					Result = CHR$(charAsc)
				END IF
			END IF
		END FUNCTION

		'Appends new to the right varaible based on mode
		SUB Append(new AS STRING, BYREF name AS STRING, BYREF value AS STRING, mode AS INTEGER)
			IF (mode = 1) THEN
				value = value + new
			ELSE
				name = name + new
			END IF
		END SUB

	PUBLIC:
		'Parses the query string (even if it is from POST data)
		SUB Parse()
			IF (THIS.parsed = 1) THEN EXIT SUB

			DEFSTR qs

			IF UCASE$(THIS.RequestMethod) = "POST" THEN
				'Make sure we don't have too much...
				IF THIS.ContentLength > THIS.MaxInput THEN
					qs = GET$(THIS.MaxInput)
				ELSE
					qs = GET$(THIS.ContentLength)
				END IF
			ELSEIF UCASE$(THIS.RequestMethod) = "GET" THEN
				IF LEN(ENVIRON$("QUERY_STRING")) > THIS.MaxInput THEN
					qs = LEFT$(ENVIRON$("QUERY_STRING"), THIS.MaxInput)
				ELSE
					qs = ENVIRON$("QUERY_STRING")
				END IF
			ELSE
				qs = ""
			END IF

			IF LEN(qs) > 0 THEN 'No query string; don't process
				DEFSTR name, value
				DEFINT i, mode = 0 'mode = 0 for name; mode = 1 for value
		
				FOR i = 1 TO LEN(qs)
					IF qs[i] = "&" THEN 'Store the just finished pair
						IF (THIS.InsertPair(UCASE$(name), value) = -1) THEN 'Cannot add any more pairs
							EXIT FOR
						ELSE 'reset name, value. and mode
							name = ""
							value = ""
							mode = 0
						END IF
					ELSEIF qs[i] = "=" THEN 'Switch from storing in the name to storing in the value
						mode = 1
					ELSE ' not a control character (= or &) so add it to the whatever part of the pair we are working on
						IF (THIS.AutoConvert = 1) THEN
							IF qs[i] = "%" THEN
								DEFSTR converted = THIS.SimpleDeHex(THIS.LookAhead(qs, 2, i))
								IF (converted) <> "" THEN
									THIS.Append(converted, name, value, mode)
									i = i + 2 'advance index to proper position (skips the two characters just decoded
								ELSE
									THIS.Append(qs[i], name, value, mode)
								END IF
							ELSEIF qs[i] = "+" THEN
								DEFSTR lookAhead = THIS.LookAhead(qs, 1, i)
								IF (lookAhead = "+" OR lookAhead = " ") THEN 'the next character is a plus or a space, so don't turn this plus into a space
									THIS.Append("+", name, value, mode)
								ELSE
									THIS.Append(" ", name, value, mode)
								END IF
							ELSE 'normal character
								THIS.Append(qs[i], name, value, mode)
							END IF 'qs[i] = %
						ELSE 'don't convert
							THIS.Append(qs[i], name, value, mode)
						END IF 'THIS.AutoConvert
					END IF
				NEXT i

				'Add the last name/value pair, if it exists
				IF (name <> "") THEN
					THIS.InsertPair(UCASE$(name), value)
				END IF
			END IF 'LEN(qs) > 0
			THIS.parsed = 1
		END SUB

		CONSTRUCTOR
			_Accept = ENVIRON$("HTTP_ACCEPT")
			_AuthType = ENVIRON$("AUTH_TYPE")
			_ContentLength = VAL(ENVIRON$("CONTENT_LENGTH"))
			_ContentType = ENVIRON$("CONTENT_TYPE")
			_Cookie = ENVIRON$("HTTP_COOKIE")
			_GatewayInterface = ENVIRON$("GATEWAY_INTERFACE")
			_PathInfo = ENVIRON$("PATH_INFO")
			_PathTranslated =ENVIRON$("PATH_TRANSLATED")
			_Referer = ENVIRON$("HTTP_REFERER")
			_RemoteAddr = ENVIRON$("REMOTE_ADDR")
			_RemoteHost = ENVIRON$("REMOTE_HOST")
			_RemoteIdent = ENVIRON$("REMOTE_IDENT")
			_RemoteUser = ENVIRON$("REMOTE_USER")
			_RequestMethod = ENVIRON$("REQUEST_METHOD")
			_ScriptName = ENVIRON$("SCRIPT_NAME")
			_ServerSoftware = ENVIRON$("SERVER_SOFTWARE")
			_ServerName = ENVIRON$("SERVER_NAME")
			_ServerPort = VAL(ENVIRON$("SERVER_PORT"))
			_ServerProtocol = ENVIRON$("SERVER_PROTOCOL")
			_QueryString = ENVIRON$("QUERY_STRING")
			_UserAgent = ENVIRON$("HTTP_USER_AGENT")

			MaxInput = CGI_INPUT_DEFAULT
			AutoConvert = 1
			total = 0

			parsed = 0 'False
		END CONSTRUCTOR

		'Gets the value of the given name/value pair
		FUNCTION Get(name AS STRING, BYREF value AS STRING) AS INTEGER
			IF THIS.parsed <> 1 THEN
				THIS.Parse()
			END IF

			DEFSTR return

			IF (THIS.FindPair(UCASE$(name), value) = -1) THEN 'name not found
				Result = 0
			ELSE 'name was found
				Result = 1
			END IF
		END FUNCTION
END TYPE

$ENDIF