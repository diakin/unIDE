$IFNDEF __RC4CRYPT_INC   ' IncManager: include guard
$DEFINE __RC4CRYPT_INC
'
' RC4crypt.inc
' (C) 2003-10-04 Martin Wehner
'
' Contact:  mailto:martin.wehner@firemail.de
' Homepage: http://mitglied.lycos.de/maweso/
'
' RC4 is a stream cipher symmetric key algorithm. It was
' developed in 1987 by Ronald Rivest and kept as a trade
' secret by RSA Data Security. On September 9, 1994, the
' RC4 algorithm was anonymously posted on the Internet on
' the Cyperpunks' Anonymous Remailers List.
' RC4 uses a variable length key from 1 to 256 bytes to
' initialize a 256-byte state table. The state table is
' used for subsequent generation of pseudo-random bytes
' and then to generate a pseudo-random stream which is
' XORed with the plaintext to give the ciphertext. Each
' element in the state table is swapped at least once. The
' RC4 key is often limited to 40 bits, because of export
' restrictions but it is sometimes used as a 128 bit key.
' It has the capability of using keys between 1 and 2048
' bits.
' Analysis shows that the period of the cipher is
' overwhelmingly likely to be greater than 10^100. Eight
' to sixteen machine operations are required per output
' byte, and the cipher can be expected to run very quickly
' in software. Independent analysts have scrutinized the
' algorithm and it is considered secure. RC4 is used in
' many commercial software packages.
'
' The type definition below is an adaptation of the RC4
' algorithm to RapidQ Basic. If you want to use this
' component then you must first create an object of type
' QRC4. After that you must call the procedure Init() to
' initialize the object with the key. If you now call the
' function Pipe() with a string then the string is encoded
' and returned by the function.
' If you want to decode then simply execute the same steps
' again but call the function Pipe() with the encoded
' string.
' This component can process data streams. Encode or
' decode data streams by calling the function Pipe() for
' each stream element. You are free with the size of the
' data packets because (Pipe(s) & Pipe(t)) is always equal
' to Pipe(s & t).
'
' Example:
'   $INCLUDE "RC4crypt.inc"
'   DEFSTR k = "1234567890"   ' This is the key
'   DEFSTR s = "abcdefghijklmnopqrstuvwxyz"
'   DEFSTR t = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
'   DIM rc4 AS QRC4
'   rc4.Init(k)   ' Initialize RC4 object with the key
'   s = rc4.Pipe(s)   ' Encode stream element s
'   t = rc4.Pipe(t)   ' Encode stream element t
'   rc4.Init(k)   ' Initialize RC4 object with the key again
'   ShowMessage(rc4.Pipe(s & t))   ' Concatenate and decode
'
' DISCLAIMER: ABSOLUTELY NO WARRANTY IS GIVEN FOR THIS
' COMPONENT! USE THIS TYPE DEFINITION AT YOUR OWN RISK!
'

TYPE QRC4 EXTENDS QOBJECT
PRIVATE:
stateTable(256) AS BYTE
randomIndex AS BYTE
i AS LONG
j AS LONG
k AS LONG
n AS LONG

PUBLIC:
SUB Reset
FOR QRC4.i = 0 TO 255
	QRC4.stateTable(QRC4.i) = QRC4.i
NEXT

QRC4.i = 0
QRC4.j = 0
END SUB

SUB Init (key AS STRING)
QRC4.Reset

QRC4.n = LEN(key)
IF 0 < QRC4.n THEN
	FOR QRC4.i = 0 TO 255
		QRC4.k = (QRC4.i MOD QRC4.n) + 1
		QRC4.j = (QRC4.j + QRC4.stateTable(QRC4.i) + ASC(key[QRC4.k])) AND 255
		SWAP QRC4.stateTable(QRC4.i), QRC4.stateTable(QRC4.j)
	NEXT
	
	QRC4.i = 0
	QRC4.j = 0
END IF
END SUB

FUNCTION Pipe (str AS STRING) AS STRING
result = ""

QRC4.n = LEN(str)
FOR QRC4.k = 1 TO QRC4.n
	QRC4.i = (QRC4.i + 1) AND 255
	QRC4.j = (QRC4.j + QRC4.stateTable(QRC4.i)) AND 255
	QRC4.randomIndex = (QRC4.stateTable(QRC4.i) + QRC4.stateTable(QRC4.j)) AND 255
	SWAP QRC4.stateTable(QRC4.i), QRC4.stateTable(QRC4.j)
	
	result = result & CHR$(ASC(str[QRC4.k]) XOR QRC4.stateTable(QRC4.randomIndex))
NEXT
END FUNCTION

constRUCTOR
Reset
END constRUCTOR
END TYPE


'DEFSTR k = "1234567890"   ' This is the key
'DEFSTR s = "abcdefghijklmnopqrstuvwxyz"
'DEFSTR t = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
'DIM rc4 AS QRC4
'rc4.Init(k)   ' Initialize RC4 object with the key
's = rc4.Pipe(s)   ' Encode stream element s
't = rc4.Pipe(t)   ' Encode stream element t
'rc4.Init(k)   ' Initialize RC4 object with the key again
'ShowMessage(rc4.Pipe(s & t))   ' Concatenate and decode
$ENDIF   ' IncManager: __RC4CRYPT_INC
