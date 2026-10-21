'
' RC4crypt.inc
' (C) 2003-09-27 Martin Wehner
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
' The function below is an adaptation of the RC4 algorithm
' to RapidQ Basic (http://www.basicguru.com/rapidq). The
' key assigned to the first parameter is used to encode
' the string given in the second parameter. The encoded
' string is returned by the function.
' If you want to decode then you must call this function
' again with the same key and the encoded string as second
' parameter.
'
' Example:
'   $INCLUDE "RC4crypt.inc"
'   DIM s AS STRING
'   s = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
'   s = RC4("1234567890", s)   ' Encode s
'   s = RC4("1234567890", s)   ' Decode s
'   ShowMessage(s)
'
' DISCLAIMER: ABSOLUTELY NO WARRANTY IS GIVEN FOR THIS
' COMPONENT! USE THIS FUNCTION AT YOUR OWN RISK!
'

$include "rapidq.inc"


FUNCTION RC4 (key AS STRING, str AS STRING) AS STRING
DIM stateTable(256) AS BYTE, randomIndex AS BYTE
DIM i AS LONG, j AS LONG, k AS LONG, n AS LONG

result = ""

n = LEN(key)
IF 0 < n THEN
	FOR i = 0 TO 255
		stateTable(i) = i
	NEXT
	
	j = 0
	FOR i = 0 TO 255
		k = (i MOD n) + 1
		j = (j + stateTable(i) + ASC(key[k])) AND 255
		SWAP stateTable(i), stateTable(j)
	NEXT
	
	j = 0
	n = LEN(str)
	FOR k = 1 TO n
		i = k AND 255
		j = (j + stateTable(i)) AND 255
		randomIndex = (stateTable(i) + stateTable(j)) AND 255
		SWAP stateTable(i), stateTable(j)
		
		result = result & CHR$(ASC(str[k]) XOR stateTable(randomIndex))
	NEXT
END IF
END FUNCTION


' Example:
'   $INCLUDE "RC4crypt.inc"
DIM s AS STRING
s = "qwerty123"
print"s=";s
cd$="gdf3f*^&%h8k87e548)95п4-9w%YT356GQ65gtr54)-_8%gff5f4r*^&%h8ktmh4r14f(*"
cd1$="q234ff4fq34fq34RTQ#%T$%T$E2345"
cd1$ = RC4("1234567890111999362412", cd1$)   ' Encode s
print"cd1RC4$=";cd1$
print"len cd1RC4$=";len(cd1$)

cd2$="й234ва4апк45п;%:П%Н4нвЦавdра5пhР5уНуцкпр:5апмe4№5Р"
cd2$ = RC4("1234567890111999362412", cd2$)   ' Encode s
print"cd2RC4$=";cd2$
print"len cd2RC4$=";len(cd2$)



ns$=""

for i=1 to len(s)
	ns$=ns$+cd$[i]+s[i]
next i

print "ns1$=";ns$

ns$ = RC4("1234567890111999", ns$)   ' Encode s
print "nsRC4$=";ns$
ns$ = RC4("1234567890111999", ns$)   ' Decode s
print"ns$=";ns$

ns2$=cd1$+ns$+cd2$
print"ns2$=";ns2$

cd1$=left$(ns2$,30) 
cd2$=right$(ns2$,50) 
ns2$=ns2$-cd1$
ns$=ns2$-cd2$
print"ns$=";ns$

zz=len(ns$)'/2
s=""
print"zz=";zz

for i=2 to zz step 2
	s=s+ns$[i]
next i
print"s!!!!!=";s


