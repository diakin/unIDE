




DECLARE sub crea_pulsar_db
DECLARE sub inserisci_oggetto_in_pulsar_db
declare sub visualizza_tutti_da_pulsar_db
DECLARE SUB RQ_PulsarEngine LIB "pulsar.dll" ALIAS "RQ_PulsarEngine"(RetFunction$)
DECLARE SUB RQ_PulsarBuild LIB "pulsar.dll" ALIAS "RQ_PulsarBuild"(RetFunction$)
DECLARE SUB RQ_NewConventionalDB LIB "pulsar.dll" ALIAS "RQ_NewConventionalDB"(RetFunction$,Structure$,IndexField$,PulsarPath$,PulsarFile$)
DECLARE SUB RQ_SaveIndexConvDB LIB "pulsar.dll" ALIAS "RQ_SaveIndexConvDB"(RetFunction$,PulsarPath$,PulsarFile$,RecordToSave$)
DECLARE SUB RQ_GetQuantityOfRecords LIB "pulsar.dll" ALIAS "RQ_GetQuantityOfRecords"(RetFunction$,PulsarPath$,PulsarFile$)
DECLARE SUB RQ_GetRecordConvDB LIB "pulsar.dll" ALIAS "RQ_GetRecordConvDB"(RetFunction$,PulsarPath$,PulsarFile$,RecordNumber$)
DECLARE SUB RQ_SINEConvDB LIB "pulsar.dll" ALIAS "RQ_SINEConvDB"(RetFunction$,PulsarPath$,PulsarFile$,RecordToSave$)
DECLARE SUB RQ_SaveConvDB LIB "pulsar.dll" ALIAS "RQ_SaveConvDB"(RetFunction$,PulsarPath$,PulsarFile$,RecordToSave$)
DECLARE SUB RQ_ReindexConvDB LIB "pulsar.dll" ALIAS "RQ_ReindexConvDB"(RetFunction$,PulsarPath$,PulsarFile$)
DECLARE SUB RQ_ReturnRecordByte LIB "pulsar.dll" ALIAS "RQ_ReturnRecordByte"(RetFunction$,PulsarPath$,PulsarFile$,RecordNumber$)
DECLARE SUB RQ_SARIndexConDB LIB "pulsar.dll" ALIAS "RQ_SARIndexConDB"(RetFunction$,PulsarPath$,PulsarFile$,DataToSearch$)
DECLARE SUB RQ_SARByteConDB LIB "pulsar.dll" ALIAS "RQ_SARByteConDB"(RetFunction$,PulsarPath$,PulsarFile$,DataToSearch$)
DECLARE SUB RQ_DeleteRecordConvDB LIB "pulsar.dll" ALIAS "RQ_DeleteRecordConvDB"(RetFunction$,PulsarPath$,PulsarFile$,RecordNumber$)
DECLARE SUB RQ_ModifyRecordConvDB LIB "pulsar.dll" ALIAS "RQ_ModifyRecordConvDB"(RetFunction$,PulsarPath$,PulsarFile$,NewRecordInDB$,RecordToModify$)
DECLARE SUB RQ_GetCounter LIB "pulsar.dll" ALIAS "RQ_GetCounter"(RetFunction$,PulsarPath$,PulsarFile$)
DECLARE SUB RQ_SetCounter LIB "pulsar.dll" ALIAS "RQ_SetCounter"(RetFunction$,PulsarPath$,PulsarFile$,NumberToSet$)
DECLARE SUB RQ_DeleteLog LIB "pulsar.dll" ALIAS "RQ_DeleteLog"(RetFunction$,PulsarPath$,PulsarFile$)
DECLARE SUB RQ_SaveInLog LIB "pulsar.dll" ALIAS "RQ_SaveInLog"(RetFunction$,PulsarPath$,PulsarFile$,TextToSave$)
DECLARE SUB RQ_ReadLog LIB "pulsar.dll" ALIAS "RQ_ReadLog"(RetFunction$,PulsarPath$,PulsarFile$)

'-------------------- declare variabili per  oggetti n inseriti---------------------------------
'ogni oggetto inserito ha bisogno di diversi parametri posizione iniziale-xy1-xy2
'tipologia di oggetto
dim posizione_oggetto_1x(1000) as integer
dim posizione_oggetto_1y(1000) as integer
dim posizione_oggetto_2x(1000) as integer
dim posizione_oggetto_2y(1000) as integer
dim indice_oggetto(1000) as integer
dim nome_oggetto(1000) as string
dim nome_bmp(1000) as string
dim testo_oggetto(1000) as string

'-------inutilizzati - servono come esempio per la scala

DIM Image1_editor AS Qbitmap
Image1_editor.BMP = "test1.bmp"
DIM Image2_editor AS Qbitmap
Image2_editor.BMP = "test2.bmp"

dim rect1_editor as qrect
dim rect2_editor as qrect

'-----------------------------------------------------------------------------------------------

    TYPE Articoli
        Articolo_Nome AS STRING * 10
        Articolo_Codice AS STRING * 10
        Articolo_Descrizione AS STRING * 30
        Articolo_Categoria AS STRING * 10
        Articolo_Immagine 	AS STRING * 15 
        Articolo_Larghezza   	AS STRING * 4 
        Articolo_Profondita   AS STRING * 4 
        Articolo_Altezza   	AS STRING * 4
        Articolo_VDX     	AS STRING * 10
        Articolo_VDY   		AS STRING * 10 
        Articolo_Peso     	AS STRING * 4
        Articolo_Costo     	AS STRING * 6
        Articolo_UTILITA     	AS STRING * 10 
    END TYPE




    DIM DatabaseRecord AS Articoli 
    PulsarPath$="database"
    PulsarFile$="temp_DB" 
    IndexField$="Articolo_Nome"
    Structure$="Articolo_Nome:10,Articolo_Codice:10,Articolo_Descrizione:30,Articolo_Categoria:10,Articolo_Immagine:15,Articolo_Larghezza:4,Articolo_Profondita:4,Articolo_Altezza:4,Articolo_VDX:10,Articolo_VDY:10,Articolo_Peso:4,Articolo_Costo:6,Articolo_UTILITA:10"
    IndexField$="Articolo_Nome"
    RetFunction$=SPACE$(160)
sub crea_pulsar_db

    RQ_NewConventionalDB @RetFunction$,Structure$,IndexField$,PulsarPath$,PulsarFile$

    IF LEFT$(RetFunction$,2)<>"ok" THEN
        Msg$="OPERATION IS NOT COMPLETED: "+LTRIM$(RTRIM$(RetFunction$))
        MESSAGEBOX(Msg$, "Púlsar 3.0 in RapidQ", mbOK)
    ELSE
    END IF
end sub

'------inizializzazione database temporaneo-----------
  dim path as string
  path="database\temp_db.IDX"
IF FileExists(path) = 0 Then 
  'Dim FileOp As QSHFileOperation
  'FileOp.DefaultFlagsEx = fofSimpleProgress or fofNoConfirmMkDir
  'FileOp.CopyEx("tempus sans itc.TTF",path,DefaultFlagsEx=0,FALSE)
   crea_pulsar_db
end if

'----------------------inserisce oggetto da librerie a designer-preventivi-------------
sub inserisci_oggetto_in_pulsar_db

ShowMessage "selezionato item " + str$(Edit_nome.text)

    DatabaseRecord.Articolo_Nome=Edit_nome.text
    DatabaseRecord.Articolo_Codice=Edit_codice.text
    DatabaseRecord.Articolo_Descrizione=Edit_descrizione.text
    DatabaseRecord.Articolo_Categoria=Edit_categoria.text
    DatabaseRecord.Articolo_Immagine=image1.bmp
    DatabaseRecord.Articolo_Larghezza=Edit_larghezza.text
    DatabaseRecord.Articolo_Profondita=Edit_profondita.text
    DatabaseRecord.Articolo_Altezza=Edit_altezza.text
    DatabaseRecord.Articolo_VDX=" "
    DatabaseRecord.Articolo_VDY=" "
    DatabaseRecord.Articolo_Peso=Edit_peso.text
    DatabaseRecord.Articolo_Costo=Edit_prezzo.text
    DatabaseRecord.Articolo_UTILITA=" "


    	RecordToSave$=DatabaseRecord.Articolo_Nome
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_Codice
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_Descrizione
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_Categoria
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_Immagine
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_Larghezza
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_Profondita
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_Altezza
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_VDX
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_VDY
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_Peso
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_Costo
	RecordToSave$=RecordToSave$+DatabaseRecord.Articolo_UTILITA


    RetFunction$=SPACE$(160)

    RQ_SaveConvDB @RetFunction$,PulsarPath$,PulsarFile$,RecordToSave$

    IF LEFT$(RetFunction$,5)="ERROR" THEN

        'If record is saved, the packed function return "ok".
        'If error occur, function return error code in string
        'format: "ERROR CODE:xxx...." (xxx is error code -see púlsar manual-)
        Msg$="OPERATION IS NOT COMPLETED: "+LTRIM$(RTRIM$(RetFunction$))
        MESSAGEBOX(Msg$, "Púlsar 3.0 in RapidQ", mbOK)

    ELSE

        'record is saved
        MESSAGEBOX("OPERACION OK.", "Púlsar 3.0 in RapidQ", mbOK)

    END IF

end sub

sub visualizza_tutti_da_pulsar_db

    RetFunction$=SPACE$(160)

    RQ_GetQuantityOfRecords @RetFunction$,PulsarPath$,PulsarFile$

    IF LEFT$(RetFunction$,5)="ERROR" THEN


         Msg$="OPERATION IS NOT COMPLETED: "+LTRIM$(RTRIM$(RetFunction$))
         MESSAGEBOX(Msg$, "Púlsar 3.0 in RapidQ", mbOK)
         END

    END IF

    RecordsInDB$=LTRIM$(RTRIM$(RetFunction$)) 

    FOR Reading%=1 TO VAL(RecordsInDB$)

       RQ_GetRecordConvDB @RetFunction$,PulsarPath$,PulsarFile$,LTRIM$(RTRIM$(STR$(Reading%)))

       IF LCASE$(LEFT$(RetFunction$,5))="error" THEN

            Msg$="Error reading record number:"+ LTRIM$ ( RTRIM$ ( STR$ ( Reading% ) ) )
            MESSAGEBOX(Msg$, "Púlsar 3.0 in RapidQ", mbOK)
            END

        ELSE


    DatabaseRecord.Articolo_Nome=LEFT$(RetFunction$,10)
    DatabaseRecord.Articolo_Codice=MID$(RetFunction$,11,10)
    DatabaseRecord.Articolo_Descrizione=MID$(RetFunction$,21,30)
    DatabaseRecord.Articolo_Categoria=MID$(RetFunction$,51,10)
    DatabaseRecord.Articolo_Immagine=MID$(RetFunction$,61,15)
    DatabaseRecord.Articolo_Larghezza=MID$(RetFunction$,76,4)
    DatabaseRecord.Articolo_Profondita=MID$(RetFunction$,80,4)
    DatabaseRecord.Articolo_Altezza=MID$(RetFunction$,84,4)
    DatabaseRecord.Articolo_VDX=MID$(RetFunction$,88,10)
    DatabaseRecord.Articolo_VDY=MID$(RetFunction$,98,10)
    DatabaseRecord.Articolo_Peso=MID$(RetFunction$,108,4)
    DatabaseRecord.Articolo_Costo=MID$(RetFunction$,112,6)
    DatabaseRecord.Articolo_UTILITA=MID$(RetFunction$,118,10)


            'show the record
            dim Msg1$ as string
            Msg1$="APELLIDO: "+DatabaseRecord.Articolo_Nome+CHR$(10)+CHR$(13)
            Msg1$=Msg$+"NOMBRES: "+DatabaseRecord.Articolo_Descrizione+CHR$(10)+CHR$(13)
            Msg1$=Msg$+"E-MAIL: "+DatabaseRecord.Articolo_Immagine+CHR$(10)+CHR$(13)
            Msg1$=Msg$+"WEB: "+DatabaseRecord.Articolo_Categoria

            MESSAGEBOX(Msg1$, "Púlsar 3.0 in RapidQ", mbOK)

         END IF

    NEXT Reading%

end sub