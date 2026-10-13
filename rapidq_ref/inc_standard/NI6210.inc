$IFNDEF __NI6210_INC   ' IncManager: include guard
$DEFINE __NI6210_INC
$INCLUDE "DAQmxConst.inc"
'NI6210.inc

'--- Declarations ---
'Declare function timer6210Over as long
'declare sub DAQmxReadCounter
declare function DAQmxErrChk (ErrCode as long) as string


'!!! <<<<<------    NI6210  declaration   ---------------------------------------------------------------------


'!!!*****************************************
'int32 DAQmxReadDigitalLines (TaskHandle taskHandle, int32 numSampsPerChan, float64 timeout, bool32 fillMode, uInt8 readArray[], 
'                             uInt32 arraySizeInBytes, int32 *sampsPerChanRead, int32 *numBytesPerSamp, bool32 *reserved);


Declare Function DAQmxReadDigitalLines Lib "nicaiu.dll"  Alias "DAQmxReadDigitalLines" (_
TaskHandle  as long,_ ' input
numSampsPerChan  as long,_ 'DAQmx_Val_Auto  input
timeout1 as long,timeout2 as long, _ ' input
fillMode  as long,_ 'input DAQmx_Val_GroupByChannel   Group by channel (non-interleaved);  DAQmx_Val_GroupByScanNumber   Group by scan number (interleaved)
lpReadArray as long,_ ' output
arraySizeInBytes  as long,_ 'input The size of the array, in samples, into which samples are read.
byref sampsPerChanRead as long,_' output
byref numBytesPerSamp as long,_' output
reserved as long_' input
) as long


'!!!*****************************************
'int32 DAQmxCreateDIChan (TaskHandle taskHandle, const char lines[], const char nameToAssignToLines[], int32 lineGrouping);

'Creates channel(s) to measure digital signals and adds the channel(s) to the task you specify with taskHandle. 
'You can group digital lines into one digital channel or separate them into multiple digital channels. 
'If you specify one or more entire ports in lines by using port physical channel names, you cannot separate the ports into multiple channels. 
'To separate ports into multiple channels, use this function multiple times with a different port each time.

'nameToAssignToLines  const char []  
'The name of the created virtual channel(s). If you create multiple virtual channels with one call to this function, 
'you can specify a list of names separated by commas. If you do not specify a name, NI-DAQmx uses the physical channel name 
'as the virtual channel name. If you specify your own names for nameToAssignToLines, you must use the names when you refer to these 
'channels in other NI-DAQmx functions. 

'Specifies whether to group digital lines into one or more virtual channels. 
'If you specify one or more entire ports in lines, you must set lineGrouping to DAQmx_Val_ChanForAllLines

Declare Function DAQmxCreateDIChan Lib "nicaiu.dll"  Alias "DAQmxCreateDIChan" (_
TaskHandle  as long,_
lines as string,_   'The names of the digital lines used to create a virtual channel. You can specify a list or range of lines.
nameToAssignToLines as string,_  '
lineGrouping as long_ ' DAQmx_Val_ChanPerLine One channel for each line  DAQmx_Val_ChanForAllLines One channel for all lines
) as long


'!!!*****************************************
'Configures the task to start acquiring or generating samples on a rising or falling edge of a digital signal.
Declare Function DAQmxCfgDigEdgeStartTrig Lib "nicaiu.dll"  Alias "DAQmxCfgDigEdgeStartTrig" (_
TaskHandle  as long,_
triggerSource as string,_   'The name of a terminal where there is a digital signal to use as the source of the trigger.
triggerEdge as long_ ' DAQmx_Val_Rising  DAQmx_Val_Falling 
) as long



'!!!*****************************************
Declare Function DAQmxCfgChangeDetectionTiming Lib "nicaiu.dll"  Alias "DAQmxCfgChangeDetectionTiming" (_
TaskHandle as long,_
risingEdgeChan as string, _
fallingEdgeChan as string, _
sampleMode as long, _
sampsPerChan0 as long,sampsPerChan1 as long_ 'uInt64
) as long 'int32

'!!!*****************************************
Declare Function DAQmxReadCounterF64  Lib "nicaiu.dll"  Alias "DAQmxReadCounterF64" (_
TaskHandle as long,_
numSampsPerChan as long,_
timeout1 as long,timeout2 as long, _
lpData as long, _
arraySizeInSamps  as long, _
byref sampsPerChanRead as long, _
reserved as long) as long

'otv= DAQmxReadCounterScalarF64(Ln2TaskHandle,10.0,&data2[0],NULL);
'(TaskHandle taskHandle, float64 timeout, float64 *value, bool32 *reserved);
Declare Function DAQmxReadCounterScalarF64  Lib "nicaiu.dll"  Alias "DAQmxReadCounterScalarF64" (_
TaskHandle as long,_
timeout1 as long,timeout2 as long, _
lpData as long, _
reserved as long) as long

'!!!*****************************************
Declare function DAQmxCfgSampClkTiming lib "nicaiu.dll" Alias "DAQmxCfgSampClkTiming" _
(taskHandle as long, _ 
source as string, _ 
rate1 as long,rate2 as long,_ '
activeEdge as long,_ '
sampleMode as long, _ '
sampsPerChanToAcquire1 as long, _
sampsPerChanToAcquire2 as long _
)  As Integer 


'!!!*****************************************
' 56 bytes parameters
Declare function DAQmxCreateCILinEncoderChan lib "nicaiu.dll" Alias "DAQmxCreateCILinEncoderChan" _
(taskHandle as long, _ '1 4b
counter as string, _ '2 4b
nameToAssignToChannel as string, _ '3 4b
decodingType as long, _ '4 4b
ZidxEnable as long, _ '5 4b 
ZidxVal1 as long,ZidxVal2 as long,_ '6 8b
ZidxPhase as long,_ '7 4b 
units as long, _ '8 4b
distPerPulse1 as long,distPerPulse2 as long, _ '9 8b
initialPos1 as long,initialPos2 as long, _ '10 8b
customScaleName as string  )  As Integer '11 4b 56b

brem 0
=========
DAQmxCreateCIAngEncoderChan (
taskHandle,_
const char counter[],_ ' The name of the counter to use to create virtual channels
const char nameToAssignToChannel[],_ 'The name to assign to the created virtual channel. If you specify your own 
'names for nameToAssignToChannel, you must use the names when you refer to these channels in other NI-DAQmx functions
int32 decodingType, 
'Specifies how to count and interpret the pulses that the encoder generates on signal A and signal B. 
'DAQmx_Val_X1, DAQmx_Val_X2, and DAQmx_Val_X4 are valid for quadrature encoders only. 
'DAQmx_Val_TwoPulseCounting is valid only for two-pulse encoders.
'DAQmx_Val_X2 and DAQmx_Val_X4 decoding are more sensitive to smaller changes in position than DAQmx_Val_X1 encoding, 
'with DAQmx_Val_X4 being the most sensitive. However, more sensitive decoding is more likely to produce erroneous measurements if 
'there is vibration in the encoder or other noise in the signals.

'Value  Description 
'DAQmx_Val_X1   If signal A leads signal B, count the rising edges of signal A. If signal B leads signal A, count the falling edges of signal A. 
'DAQmx_Val_X2   Count the rising and falling edges of signal A. 
'DAQmx_Val_X4   Count the rising and falling edges of both signal A and signal B. 
'DAQmx_Val_TwoPulseCounting   Increment the count on rising edges of signal A. Decrement the count on rising pulses of signal B. 

bool32 ZidxEnable, _ 'Specifies whether to enable z indexing for the measurement

float64 ZidxVal, _ 'The value, in units, to which to reset the measurement when signal Z is high and 
'signal A and signal B are at the states you specify with ZidxPhase

int32 ZidxPhase, _ 'The states at which signal A and signal B must be while signal Z is high for NI-DAQmx to reset the measurement. 
'If signal Z is never high while the signal A and signal B are high, for example, you must choose a phase other than DAQmx_Val_AHighBHigh.
'When signal Z goes high and how long it stays high varies from encoder to encoder. Refer to the documentation for the encoder to 
'determine the timing of signal Z with respect to signal A and signal B. 
'DAQmx_Val_AHighBHigh Reset the measurement when both signal A and signal B are at high logic.!!!
'DAQmx_Val_AHighBLow  Reset the measurement when signal A is at high logic and signal B is at low logic.!!!
'DAQmx_Val_ALowBHigh  Reset the measurement when signal A is at low logic and signal B is at high logic.!!!
'DAQmx_Val_ALowBLow   Reset the measurement when both signal A and signal B are at low logic.!!!

int32 units,_ 'The units to use to return angular position measurements from the channel

'DAQmx_Val_Degrees -Degrees  !!!
'DAQmx_Val_Radians -Radians !!!
'DAQmx_Val_Ticks -Timebase ticks !!!
'DAQmx_Val_FromCustomScale -Units a custom scale specifies. Use customScaleName to specify a custom scale.!!

uInt32 pulsesPerRev,_ 'The number of pulses the encoder generates per revolution. This value is the number of pulses on one of either A 
'signal or B signal, not the total number of pulses on both signal A and signal B.

float64 initialAngle,_ ' The starting angle of the encoder when the measurement begins. Specify this value in units.

const char customScaleName[] ' The name of a custom scale to apply to the channel. To use this parameter, you must set units to 
'DAQmx_Val_FromCustomScale. If you do not set units to DAQmx_Val_FromCustomScale, you must set customScaleName to NULL.

);
==============================
erem

'!!!*****************************************
' 56 bytes parameters
Declare function DAQmxCreateCIAngEncoderChan lib "nicaiu.dll" Alias "DAQmxCreateCIAngEncoderChan" _
(taskHandle as long, _ '1 4b
counter as string, _ '2 4b
nameToAssignToChannel as string, _ '3 4b
decodingType as long, _ '4 4b
ZidxEnable as long, _ '5 4b 
ZidxVal1 as long,ZidxVal2 as long,_ '6 8b
ZidxPhase as long,_ '7 4b 
units as long, _ '8 4b
pulsesPerRev as long, _ '9 4b
initialAngle1 as long,initialAngle2 as long, _ '10 8b
customScaleName as string  )  As Integer '11 4b 56b


'!!!*****************************************
Declare Function DAQmxResetDevice  Lib "nicaiu.dll"  Alias "DAQmxResetDevice" (_
devicename as string) as long

'!!!*****************************************
'int32 DAQmxGetExtendedErrorInfo (char errorString[], uInt32 bufferSize);
Declare Function DAQmxGetExtendedErrorInfo Lib "nicaiu.dll"  Alias "DAQmxGetExtendedErrorInfo" (_
byref errorString as string,_
bufferSize as long _
) as long


'!!!*****************************************
'int32 DAQmxReadCounterScalarU32 (_
'TaskHandle taskHandle, _
'float64 timeout, _
'uInt32 *value, _
'bool32 *reserved);

Declare Function DAQmxReadCounterScalarU32   Lib "nicaiu.dll"  Alias "DAQmxReadCounterScalarU32" (_
TaskHandle as long, _
timeout1 as long, timeout2 as long, _
byref CountValue as long, _
reserved as long) as long




'!!!*****************************************
brem 0
=========
'int32 DAQmxReadCounterU32 (TaskHandle taskHandle, int32 numSampsPerChan, float64 timeout, uInt32 readArray[], _
'uInt32 arraySizeInSamps, int32 *sampsPerChanRead, bool32 *reserved);
INPUT !!!
'int32 numSampsPerChan   !!!
'The number of samples, per channel, to read. The default value of -1 (DAQmx_Val_Auto) reads all available samples. 
'If readArray does not contain enough space, this function returns as many samples as fit in 
'float64 timeout  !!!
'The amount of time, in seconds, to wait for the function to read the sample(s). The default value is 10.0 seconds. 
'To specify an infinite wait, pass -1 (DAQmx_Val_WaitInfinitely). This function returns an error if the timeout elapses.
OUTPUT !!!
'uInt32 readArray[]  !!!
'The array to read samples into.

'sampsPerChanRead  !!!
'int32 * The actual number of samples read from each channel.
=========
erem 

Declare Function DAQmxReadCounterU32   Lib "nicaiu.dll"  Alias "DAQmxReadCounterU32" (_
TaskHandle as long, _
readArraynumSampsPerChan  as long, _
timeout1 as long, timeout2 as long, _
lpDataArray as long, _
arraySizeInSamps  as long, _
byref sampsPerChanRead as long, _
reserved as long) as long
'!!!*****************************************

'!!!*****************************************
'int32 __CFUNC     DAQmxGetErrorString       (int32 errorCode, char errorString[], uInt32 bufferSize);
Declare Function DAQmxGetErrorString Lib "nicaiu.dll"  Alias "DAQmxGetErrorString" (_
errorCode as long,_
byref errorString as string,_
bufferSize as long _
) as long

'!!!*****************************************
Declare Function DAQmxStartTask Lib "nicaiu.dll"  Alias "DAQmxStartTask" (_
taskHandle as long) as long

'!!!*****************************************
Declare Function DAQmxStopTask Lib "nicaiu.dll"  Alias "DAQmxStopTask" (_
taskHandle as long) as long

'!!!*****************************************
Declare Function DAQmxClearTask  Lib "nicaiu.dll"  Alias "DAQmxClearTask" (_
taskHandle as long) as long

'!!!*****************************************
Declare Function DAQmxCreateTask  Lib "nicaiu.dll"  Alias "DAQmxCreateTask" ( _
taskName As string, byref taskHandle as long ) As long
'======  начало программы ========   !!!
'dim timer6210 as QTimer
'timer6210.ontimer=timer6210Over
'timer6210.interval=50'100
'timer6210.enabled=0


'=== Global variables ===
posdataOld=-111
posdata=0
posdata2=0


DevName$="Dev0"
dim err as string*2048

errstring$="+++"+space$(256)

stops=0

taskname$="111"
taskname2$="222"

defint MyTaskHandle, MyTaskHandle2
MyTaskHandle=999
MyTaskHandle2=222

counter$="Dev1/ctr0"
counter2$="Dev1/ctr1"


ScaleName$=""
nameToAssignToChannel$=""

defdbl rate ' 
'defdbl CountVal ' единичный отсчет со счетчика канала 1
deflng CountVal ' единичный отсчет со счетчика канала 1
Countval=111
defint lpCountval=varptr(Countval)

'defdbl CountVal2 ' единичный отсчет со счетчика  канала 2
deflng CountVal2 ' единичный отсчет со счетчика  канала 2
Countva2l=222
defint lpCountval2=varptr(Countval2)


defint ZidxEnable

defdbl ZidxVal
ZidxVal=0.0
defint ZidxVal1,ZidxVal2

defdbl distPerPulse
distPerPulse=1.0
defint distPerPulse1 ,distPerPulse2

defdbl initialPos,
initialPos=0.0
defint initialPos1 ,initialPos2

defint initval

ZidxEnable=0

'-------- вспомогательные переменные ---------
dim memdataLong as qmemorystream

defint arraysize=1024 '4096 '65535
dim dataLong(arraysize) as Long
dim dataDbl(arraysize) as Double

' канал 2 
dim memdataLong2 as qmemorystream

dim dataLong2(arraysize) as Long
dim dataDbl2(arraysize) as Double

DefInt _timeout(0 To 1)
DefInt _ZidxVal(0 To 1)
DefInt _distPerPulse(0 To 1)
DefInt _initialPos(0 To 1)

DefInt _rate(0 To 1)

rate=10000000 ' максимальная частота сигнала с датчика 100000 Гц

MemCpy (VarPtr(_rate(0)), VarPtr(rate), 8)

MemCpy (VarPtr(_ZidxVal(0)), VarPtr(ZidxVal), 8)
MemCpy (VarPtr(_distPerPulse(0)), VarPtr(distPerPulse), 8)
MemCpy (VarPtr(_initialPos(0)), VarPtr(initialPos), 8)

defdbl timeout=DAQmx_Val_WaitInfinitely '10 ' интервал ожидание чтения, по умолчанию 10 сек, DAQmx_Val_WaitInfinitely - непрерывное ожидание.
MemCpy (VarPtr(_timeout(0)), VarPtr(timeout), 8)

defint sampsPerChanRead,sampsPerChanRead2, reserved,reserved2, errDAQmxReadCounterU32

errDAQmxReadCounterU32=999
sampsPerChanRead=666
sampsPerChanRead2=666
arraysize=ubound(dataLong)-1 '1024
'defint reserved=0

numSampsPerChan=DAQmx_Val_Auto

defint pulsesPerRev=225000 ' число штрихов датчика !!!
defint pulsesPerRev2=225000 ' число штрихов датчика !!!

memdataLong.savearray(dataLong(0),ubound(dataLong))
memdataLong.position=0

'errDAQmxReadCounterU32=999

'arraysize=ubound(dataLong)-1 '1024

reserved2=0



$ENDIF   ' IncManager: __NI6210_INC
