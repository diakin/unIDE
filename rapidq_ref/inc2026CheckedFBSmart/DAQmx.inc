
brem 0
****************************************
// NI-DAQmx Typedefs
#ifndef _NI_int8_DEFINED_

#define _NI_int8_DEFINED_
	typedef signed char        int8;
#endif

#ifndef _NI_uInt8_DEFINED_

#define _NI_uInt8_DEFINED_
	typedef unsigned char      uInt8;
#endif
#ifndef _NI_int16_DEFINED_

#define _NI_int16_DEFINED_
	typedef signed short       int16;
#endif
#ifndef _NI_uInt16_DEFINED_

#define _NI_uInt16_DEFINED_
	typedef unsigned short     uInt16;
#endif
#ifndef _NI_int32_DEFINED_
#define _NI_int32_DEFINED_
	typedef signed long        int32;
#endif
#ifndef _NI_uInt32_DEFINED_
#define _NI_uInt32_DEFINED_
	typedef unsigned long      uInt32;
#endif
#ifndef _NI_float32_DEFINED_
#define _NI_float32_DEFINED_
	typedef float              float32;
#endif
#ifndef _NI_float64_DEFINED_
#define _NI_float64_DEFINED_
	typedef double             float64;
#endif
#ifndef _NI_int64_DEFINED_
#define _NI_int64_DEFINED_
#ifdef __linux__
	typedef long long int      int64;
#else
	typedef __int64            int64;
#endif
#endif
#ifndef _NI_uInt64_DEFINED_
#define _NI_uInt64_DEFINED_
#ifdef __linux__
	typedef unsigned long long uInt64;
#else
	typedef unsigned __int64   uInt64;
#endif
#endif

typedef uInt32             bool32;
typedef uInt32             TaskHandle;

#ifndef TRUE
 #define TRUE            (1L)
#endif
#ifndef FALSE
 #define FALSE           (0L)
#endif
#ifndef NULL
 #define NULL            (0L)
#endif




Declare Function DAQmxAddGlobalChansToTask  ((TaskHandle taskHandle, const char channelNames[])) as int32
Declare Function DAQmxAdjust1102Cal  (uInt32 calHandle, float64 refVoltage, float64 measOutput) as int32
Declare Function DAQmxAdjust1104Cal  () as int32
Declare Function DAQmxAdjust1112Cal  () as int32
Declare Function DAQmxAdjust1124Cal  () as int32
Declare Function DAQmxAdjust1125Cal  () as int32
Declare Function DAQmxAdjust1126Cal  () as int32
Declare Function DAQmxAdjust1141Cal  () as int32
Declare Function DAQmxAdjust1142Cal  () as int32
Declare Function DAQmxAdjust1143Cal  () as int32
Declare Function DAQmxAdjust1502Cal  () as int32
Declare Function DAQmxAdjust1503Cal  () as int32
Declare Function DAQmxAdjust1503CurrentCal  () as int32
Declare Function DAQmxAdjust1520Cal  () as int32
Declare Function DAQmxAdjust153xCal  () as int32
Declare Function DAQmxAdjust1540Cal  () as int32
Declare Function DAQmxAdjust4204Cal  () as int32
Declare Function DAQmxAdjust4220Cal  () as int32
Declare Function DAQmxAdjust4224Cal  () as int32
Declare Function DAQmxAdjustDSAAICal  () as int32
Declare Function DAQmxAdjustDSAAOCal  () as int32
Declare Function DAQmxAdjustDSATimebaseCal  () as int32
Declare Function DAQmxAOSeriesCalAdjust  () as int32
Declare Function DAQmxCalculateReversePolyCoeff  () as int32
Declare Function DAQmxCfgAnlgEdgeRefTrig  () as int32
Declare Function DAQmxCfgAnlgEdgeStartTrig  () as int32
Declare Function DAQmxCfgAnlgWindowRefTrig  () as int32
Declare Function DAQmxCfgAnlgWindowStartTrig  () as int32
Declare Function DAQmxCfgBurstHandshakingTimingExportClock  () as int32
Declare Function DAQmxCfgBurstHandshakingTimingImportClock  () as int32

'------------------------ !!!
'DAQmxCfgChangeDetectionTiming  (_
'TaskHandle taskHandle,_
'const char risingEdgeChan[], _
'const char fallingEdgeChan[], _
'int32 sampleMode, _
'uInt64 sampsPerChan);

Declare Function DAQmxCfgChangeDetectionTiming  (_
TaskHandle as long,_
risingEdgeChan as string, _
fallingEdgeChan as string, _
sampleMode as long, _
sampsPerChan0 as long,sampsPerChan1 as long_ 'uInt64
) as int32
'------------------------


Declare Function DAQmxCfgDigEdgeAdvTrig  () as int32
Declare Function DAQmxCfgDigEdgeRefTrig  () as int32
Declare Function DAQmxCfgDigEdgeStartTrig  () as int32
Declare Function DAQmxCfgDigPatternRefTrig  () as int32
Declare Function DAQmxCfgDigPatternStartTrig  () as int32
Declare Function DAQmxCfgHandshakingTiming  () as int32
Declare Function DAQmxCfgImplicitTiming  () as int32
Declare Function DAQmxCfgInputBuffer  () as int32
Declare Function DAQmxCfgOutputBuffer  () as int32
Declare Function DAQmxCfgPipelinedSampClkTiming  () as int32

Declare Function DAQmxCfgSampClkTiming  () as int32

Declare Function DAQmxChangeExtCalPassword  () as int32
Declare Function DAQmxClearTask  () as int32
Declare Function DAQmxClearTEDS  () as int32
Declare Function DAQmxCloseExtCal  () as int32
Declare Function DAQmxConfigureTEDS  () as int32
Declare Function DAQmxConnectTerms  () as int32
Declare Function DAQmxControlWatchdogTask  () as int32
Declare Function DAQmxCreateAIAccelChan  () as int32
Declare Function DAQmxCreateAICurrentChan  () as int32
Declare Function DAQmxCreateAICurrentRMSChan  () as int32
Declare Function DAQmxCreateAIDeviceTempChan  () as int32
Declare Function DAQmxCreateAIFreqVoltageChan  () as int32
Declare Function DAQmxCreateAIMicrophoneChan  () as int32
Declare Function DAQmxCreateAIPosLVDTChan  () as int32
Declare Function DAQmxCreateAIPosRVDTChan  () as int32
Declare Function DAQmxCreateAIResistanceChan  () as int32
Declare Function DAQmxCreateAIRTDChan  () as int32
Declare Function DAQmxCreateAIStrainGageChan  () as int32
Declare Function DAQmxCreateAITempBuiltInSensorChan  () as int32
Declare Function DAQmxCreateAIThrmcplChan  () as int32
Declare Function DAQmxCreateAIThrmstrChanIex  () as int32
Declare Function DAQmxCreateAIThrmstrChanVex  () as int32
Declare Function DAQmxCreateAIVoltageChan  () as int32
Declare Function DAQmxCreateAIVoltageChanWithExcit  () as int32
Declare Function DAQmxCreateAIVoltageRMSChan  () as int32
Declare Function DAQmxCreateAOCurrentChan  () as int32
Declare Function DAQmxCreateAOFuncGenChan  () as int32
Declare Function DAQmxCreateAOVoltageChan  () as int32
Declare Function DAQmxCreateCIAngEncoderChan  () as int32
Declare Function DAQmxCreateCICountEdgesChan  () as int32
Declare Function DAQmxCreateCIFreqChan  () as int32
Declare Function DAQmxCreateCIGPSTimestampChan  () as int32
Declare Function DAQmxCreateCILinEncoderChan  () as int32
Declare Function DAQmxCreateCIPeriodChan  () as int32
Declare Function DAQmxCreateCIPulseWidthChan  () as int32
Declare Function DAQmxCreateCISemiPeriodChan  () as int32
Declare Function DAQmxCreateCITwoEdgeSepChan  () as int32
Declare Function DAQmxCreateCOPulseChanFreq  () as int32
Declare Function DAQmxCreateCOPulseChanTicks  () as int32
Declare Function DAQmxCreateCOPulseChanTime  () as int32
Declare Function DAQmxCreateDIChan  () as int32
Declare Function DAQmxCreateDOChan  () as int32
Declare Function DAQmxCreateLinScale  () as int32
Declare Function DAQmxCreateMapScale  () as int32
Declare Function DAQmxCreatePolynomialScale  () as int32
Declare Function DAQmxCreateTableScale  () as int32
Declare Function DAQmxCreateTask  () as int32
Declare Function DAQmxCreateTEDSAIAccelChan  () as int32
Declare Function DAQmxCreateTEDSAICurrentChan  () as int32
Declare Function DAQmxCreateTEDSAIMicrophoneChan  () as int32
Declare Function DAQmxCreateTEDSAIPosLVDTChan  () as int32
Declare Function DAQmxCreateTEDSAIPosRVDTChan  () as int32
Declare Function DAQmxCreateTEDSAIResistanceChan  () as int32
Declare Function DAQmxCreateTEDSAIRTDChan  () as int32
Declare Function DAQmxCreateTEDSAIStrainGageChan  () as int32
Declare Function DAQmxCreateTEDSAIThrmcplChan  () as int32
Declare Function DAQmxCreateTEDSAIThrmstrChanIex  () as int32
Declare Function DAQmxCreateTEDSAIThrmstrChanVex  () as int32
Declare Function DAQmxCreateTEDSAIVoltageChan  () as int32
Declare Function DAQmxCreateTEDSAIVoltageChanWithExcit  () as int32
Declare Function DAQmxCreateWatchdogTimerTask  () as int32
Declare Function DAQmxDeleteSavedGlobalChan  () as int32
Declare Function DAQmxDeleteSavedScale  () as int32
Declare Function DAQmxDeleteSavedTask  () as int32
Declare Function DAQmxDisableAdvTrig  () as int32
Declare Function DAQmxDisableRefTrig  () as int32
Declare Function DAQmxDisableStartTrig  () as int32
Declare Function DAQmxDisconnectTerms  () as int32
Declare Function DAQmxESeriesCalAdjust  () as int32
Declare Function DAQmxExportSignal  () as int32
Declare Function DAQmxGetAIChanCalCalDate  () as int32
Declare Function DAQmxGetAIChanCalExpDate  () as int32
Declare Function DAQmxGetErrorString  () as int32
Declare Function DAQmxGetExtCalLastDateAndTime  () as int32
Declare Function DAQmxGetExtendedErrorInfo  () as int32
Declare Function DAQmxGetNthTaskChannel  () as int32
Declare Function DAQmxGetNthTaskDevice  () as int32
Declare Function DAQmxGetNthTaskReadChannel  () as int32
Declare Function DAQmxGetSelfCalLastDateAndTime  () as int32
Declare Function DAQmxInitExtCal  () as int32
Declare Function DAQmxIsReadOrWriteLate  () as int32
Declare Function DAQmxIsTaskDone  () as int32
Declare Function DAQmxLoadTask  () as int32
Declare Function DAQmxMSeriesCalAdjust  () as int32
Declare Function DAQmxPerformBridgeOffsetNullingCal  () as int32
Declare Function DAQmxReadAnalogF64  () as int32
Declare Function DAQmxReadAnalogScalarF64  () as int32
Declare Function DAQmxReadBinaryI16  () as int32
Declare Function DAQmxReadBinaryI32  () as int32
Declare Function DAQmxReadBinaryU16  () as int32
Declare Function DAQmxReadBinaryU32  () as int32
Declare Function DAQmxReadCounterF64  () as int32
Declare Function DAQmxReadCounterScalarF64  () as int32
Declare Function DAQmxReadCounterScalarU32  () as int32
Declare Function DAQmxReadCounterU32  () as int32
Declare Function DAQmxReadDigitalLines  () as int32
Declare Function DAQmxReadDigitalScalarU32  () as int32
Declare Function DAQmxReadDigitalU16  () as int32
Declare Function DAQmxReadDigitalU32  () as int32
Declare Function DAQmxReadDigitalU8  () as int32
Declare Function DAQmxReadRaw  () as int32
Declare Function DAQmxRegisterDoneEvent  () as int32
Declare Function DAQmxRegisterEveryNSamplesEvent  () as int32
Declare Function DAQmxRegisterSignalEvent  () as int32
Declare Function DAQmxResetDevice  () as int32
Declare Function DAQmxRestoreLastExtCalConst  () as int32
Declare Function DAQmxSaveGlobalChan  () as int32
Declare Function DAQmxSaveScale  () as int32
Declare Function DAQmxSaveTask  () as int32
Declare Function DAQmxSCBaseboardCalAdjust  () as int32
Declare Function DAQmxSelfCal  () as int32
Declare Function DAQmxSendSoftwareTrigger  () as int32
Declare Function DAQmxSetAIChanCalCalDate  () as int32
Declare Function DAQmxSetAIChanCalExpDate  () as int32
Declare Function DAQmxSetAnalogPowerUpStates  () as int32
Declare Function DAQmxSetDigitalLogicFamilyPowerUpState  () as int32
Declare Function DAQmxSetDigitalPowerUpStates  () as int32
Declare Function DAQmxSetup1102Cal  () as int32
Declare Function DAQmxSetup1104Cal  () as int32
Declare Function DAQmxSetup1112Cal  () as int32
Declare Function DAQmxSetup1124Cal  () as int32
Declare Function DAQmxSetup1125Cal  () as int32
Declare Function DAQmxSetup1126Cal  () as int32
Declare Function DAQmxSetup1141Cal  () as int32
Declare Function DAQmxSetup1142Cal  () as int32
Declare Function DAQmxSetup1143Cal  () as int32
Declare Function DAQmxSetup1502Cal  () as int32
Declare Function DAQmxSetup1503Cal  () as int32
Declare Function DAQmxSetup1520Cal  () as int32
Declare Function DAQmxSetup153xCal  () as int32
Declare Function DAQmxSetup1540Cal  () as int32
Declare Function DAQmxSSeriesCalAdjust  () as int32
Declare Function DAQmxStartTask  () as int32
Declare Function DAQmxStopTask  () as int32
Declare Function DAQmxSwitchCloseRelays  () as int32
Declare Function DAQmxSwitchConnect  () as int32
Declare Function DAQmxSwitchConnectMulti  () as int32
Declare Function DAQmxSwitchCreateScanList  () as int32
Declare Function DAQmxSwitchDisconnect  () as int32
Declare Function DAQmxSwitchDisconnectAll  () as int32
Declare Function DAQmxSwitchDisconnectMulti  () as int32
Declare Function DAQmxSwitchFindPath  () as int32
Declare Function DAQmxSwitchGetMultiRelayCount  () as int32
Declare Function DAQmxSwitchGetMultiRelayPos  () as int32
Declare Function DAQmxSwitchGetSingleRelayCount  () as int32
Declare Function DAQmxSwitchGetSingleRelayPos  () as int32
Declare Function DAQmxSwitchOpenRelays  () as int32
Declare Function DAQmxSwitchSetTopologyAndReset  () as int32
Declare Function DAQmxSwitchWaitForSettling  () as int32
Declare Function DAQmxTaskControl  () as int32
Declare Function DAQmxTristateOutputTerm  () as int32
Declare Function DAQmxWaitForNextSampleClock  () as int32
Declare Function DAQmxWaitUntilTaskDone  () as int32
Declare Function DAQmxWriteAnalogF64  () as int32
Declare Function DAQmxWriteAnalogScalarF64  () as int32
Declare Function DAQmxWriteBinaryI16  () as int32
Declare Function DAQmxWriteBinaryU16  () as int32
Declare Function DAQmxWriteCtrFreq  () as int32
Declare Function DAQmxWriteCtrFreqScalar  () as int32
Declare Function DAQmxWriteCtrTicks  () as int32
Declare Function DAQmxWriteCtrTicksScalar  () as int32
Declare Function DAQmxWriteCtrTime  () as int32
Declare Function DAQmxWriteCtrTimeScalar  () as int32
Declare Function DAQmxWriteDigitalLines  () as int32
Declare Function DAQmxWriteDigitalScalarU32  () as int32
Declare Function DAQmxWriteDigitalU16  () as int32
Declare Function DAQmxWriteDigitalU32  () as int32
Declare Function DAQmxWriteDigitalU8  () as int32
Declare Function DAQmxWriteRaw  () as int32
Declare Function DAQmxWriteToTEDSFromArray  () as int32
Declare Function DAQmxWriteToTEDSFromFile  () as int32


int32 __CFUNC     DAQmxSwitchSetTopologyAndReset (const char deviceName[], const char newTopology[]);

// For possible values of the output parameter pathStatus see value set SwitchPathType in Values section above.
int32 __CFUNC     DAQmxSwitchFindPath            (const char switchChannel1[], const char switchChannel2[], char path[], uInt32 pathBufferSize, int32 *pathStatus);

int32 __CFUNC     DAQmxSwitchOpenRelays          (const char relayList[], bool32 waitForSettling);
int32 __CFUNC     DAQmxSwitchCloseRelays         (const char relayList[], bool32 waitForSettling);

int32 __CFUNC     DAQmxSwitchGetSingleRelayCount (const char relayName[], uInt32 *count);
int32 __CFUNC     DAQmxSwitchGetMultiRelayCount  (const char relayList[], uInt32 count[], uInt32 countArraySize, uInt32 *numRelayCountsRead);
// For possible values of the output parameter relayPos see value set RelayPos in Values section above.
int32 __CFUNC     DAQmxSwitchGetSingleRelayPos   (const char relayName[], uInt32 *relayPos);
// For possible values in the output array relayPos see value set RelayPos in Values section above.
int32 __CFUNC     DAQmxSwitchGetMultiRelayPos    (const char relayList[], uInt32 relayPos[], uInt32 relayPosArraySize, uInt32 *numRelayPossRead);

int32 __CFUNC     DAQmxSwitchWaitForSettling     (const char deviceName[]);

int32 __CFUNC_C   DAQmxGetSwitchChanAttribute    (const char switchChannelName[], int32 attribute, void *value);
int32 __CFUNC_C   DAQmxSetSwitchChanAttribute    (const char switchChannelName[], int32 attribute, ...);

int32 __CFUNC_C   DAQmxGetSwitchDeviceAttribute  (const char deviceName[], int32 attribute, void *value, ...);
int32 __CFUNC_C   DAQmxSetSwitchDeviceAttribute  (const char deviceName[], int32 attribute, ...);

int32 __CFUNC_C   DAQmxGetSwitchScanAttribute    (TaskHandle taskHandle, int32 attribute, void *value);
int32 __CFUNC_C   DAQmxSetSwitchScanAttribute    (TaskHandle taskHandle, int32 attribute, ...);
int32 __CFUNC     DAQmxResetSwitchScanAttribute  (TaskHandle taskHandle, int32 attribute);


/******************************************************/
/***                Signal Routing                  ***/
/******************************************************/


int32 __CFUNC     DAQmxConnectTerms         (const char sourceTerminal[], const char destinationTerminal[], int32 signalModifiers);
int32 __CFUNC     DAQmxDisconnectTerms      (const char sourceTerminal[], const char destinationTerminal[]);
int32 __CFUNC     DAQmxTristateOutputTerm   (const char outputTerminal[]);


/******************************************************/
/***                Device Control                  ***/
/******************************************************/


int32 __CFUNC     DAQmxResetDevice              (const char deviceName[]);

int32 __CFUNC_C   DAQmxGetDeviceAttribute       (const char deviceName[], int32 attribute, void *value, ...);

/******************************************************/
/***              Watchdog Timer                    ***/
/******************************************************/


int32 __CFUNC_C   DAQmxCreateWatchdogTimerTask    (const char deviceName[], const char taskName[], TaskHandle *taskHandle, float64 timeout, const char lines[], int32 expState, ...);
int32 __CFUNC     DAQmxControlWatchdogTask        (TaskHandle taskHandle, int32 action);

int32 __CFUNC_C  DAQmxGetWatchdogAttribute        (TaskHandle taskHandle, const char lines[], int32 attribute, void *value, ...);
int32 __CFUNC_C  DAQmxSetWatchdogAttribute        (TaskHandle taskHandle, const char lines[], int32 attribute, ...);
int32 __CFUNC    DAQmxResetWatchdogAttribute      (TaskHandle taskHandle, const char lines[], int32 attribute);


/******************************************************/
/***                 Calibration                    ***/
/******************************************************/


int32 __CFUNC     DAQmxSelfCal                    (const char deviceName[]);
int32 __CFUNC     DAQmxPerformBridgeOffsetNullingCal(TaskHandle taskHandle, const char channel[]);
int32 __CFUNC     DAQmxGetSelfCalLastDateAndTime  (const char deviceName[], uInt32 *year, uInt32 *month, uInt32 *day, uInt32 *hour, uInt32 *minute);
int32 __CFUNC     DAQmxGetExtCalLastDateAndTime   (const char deviceName[], uInt32 *year, uInt32 *month, uInt32 *day, uInt32 *hour, uInt32 *minute);
int32 __CFUNC     DAQmxRestoreLastExtCalConst     (const char deviceName[]);

int32 __CFUNC     DAQmxESeriesCalAdjust           (uInt32 calHandle, float64 referenceVoltage);
int32 __CFUNC     DAQmxMSeriesCalAdjust           (uInt32 calHandle, float64 referenceVoltage);
int32 __CFUNC     DAQmxSSeriesCalAdjust           (uInt32 calHandle, float64 referenceVoltage);
int32 __CFUNC     DAQmxSCBaseboardCalAdjust       (uInt32 calHandle, float64 referenceVoltage);
int32 __CFUNC     DAQmxAOSeriesCalAdjust          (uInt32 calHandle, float64 referenceVoltage);

int32 __CFUNC     DAQmxDeviceSupportsCal          (const char deviceName[], bool32 *calSupported);

int32 __CFUNC_C   DAQmxGetCalInfoAttribute        (const char deviceName[], int32 attribute, void *value, ...);
int32 __CFUNC_C   DAQmxSetCalInfoAttribute        (const char deviceName[], int32 attribute, ...);

int32 __CFUNC     DAQmxInitExtCal                 (const char deviceName[], const char password[], uInt32 *calHandle);
int32 __CFUNC     DAQmxCloseExtCal                (uInt32 calHandle, int32 action);
int32 __CFUNC     DAQmxChangeExtCalPassword       (const char deviceName[], const char password[], const char newPassword[]);

int32 __CFUNC     DAQmxAdjustDSAAICal             (uInt32 calHandle, float64 referenceVoltage);
int32 __CFUNC     DAQmxAdjustDSAAOCal             (uInt32 calHandle, uInt32 channel, float64 requestedLowVoltage, float64 actualLowVoltage, float64 requestedHighVoltage, float64 actualHighVoltage, float64 gainSetting);
int32 __CFUNC     DAQmxAdjustDSATimebaseCal       (uInt32 calHandle, float64 referenceFrequency);

int32 __CFUNC     DAQmxAdjust4204Cal              (uInt32 calHandle, const char channelNames[], float64 lowPassFreq, bool32 trackHoldEnabled, float64 inputVal);
int32 __CFUNC     DAQmxAdjust4220Cal              (uInt32 calHandle, const char channelNames[], float64 gain, float64 inputVal);
int32 __CFUNC     DAQmxAdjust4224Cal              (uInt32 calHandle, const char channelNames[], float64 gain, float64 inputVal);
// Note: This function is obsolete and now always returns zero.
int32 __CFUNC     DAQmxAdjust4225Cal              (uInt32 calHandle, const char channelNames[], float64 gain, float64 inputVal);

int32 __CFUNC     DAQmxSetup1102Cal               (uInt32 calHandle, const char channelNames[], float64 gain);
int32 __CFUNC     DAQmxAdjust1102Cal              (uInt32 calHandle, float64 refVoltage, float64 measOutput);
int32 __CFUNC     DAQmxSetup1125Cal               (uInt32 calHandle, const char channelNames[], float64 gain);
int32 __CFUNC     DAQmxAdjust1125Cal              (uInt32 calHandle, float64 refVoltage, float64 measOutput);
int32 __CFUNC     DAQmxSetup1520Cal               (uInt32 calHandle, const char channelNames[], float64 gain);
int32 __CFUNC     DAQmxAdjust1520Cal              (uInt32 calHandle, float64 refVoltage, float64 measOutput);


/******************************************************/
/***                     TEDS                       ***/
/******************************************************/

int32 __CFUNC     DAQmxConfigureTEDS              (const char physicalChannel[], const char filePath[]);
int32 __CFUNC     DAQmxClearTEDS                  (const char physicalChannel[]);
int32 __CFUNC     DAQmxWriteToTEDSFromArray       (const char physicalChannel[], uInt8 bitStream[], uInt32 arraySize, int32 basicTEDSOptions);
int32 __CFUNC     DAQmxWriteToTEDSFromFile        (const char physicalChannel[], const char filePath[], int32 basicTEDSOptions);
int32 __CFUNC_C   DAQmxGetPhysicalChanAttribute   (const char physicalChannel[], int32 attribute, void *value, ...);


/******************************************************/
/***                  Real-Time                     ***/
/******************************************************/

int32 __CFUNC     DAQmxWaitForNextSampleClock(TaskHandle taskHandle, float64 timeout, bool32 *isLate);
int32 __CFUNC_C   DAQmxGetRealTimeAttribute  (TaskHandle taskHandle, int32 attribute, void *value, ...);
int32 __CFUNC_C   DAQmxSetRealTimeAttribute  (TaskHandle taskHandle, int32 attribute, ...);
int32 __CFUNC     DAQmxResetRealTimeAttribute(TaskHandle taskHandle, int32 attribute);

// Note: This function is obsolete and now always returns zero.
bool32 __CFUNC    DAQmxIsReadOrWriteLate     (int32 errorCode);


/******************************************************/
/***                   Storage                      ***/
/******************************************************/

int32 __CFUNC     DAQmxSaveTask                    (TaskHandle taskHandle, const char saveAs[], const char author[], uInt32 options);
int32 __CFUNC     DAQmxSaveGlobalChan              (TaskHandle taskHandle, const char channelName[], const char saveAs[], const char author[], uInt32 options);
int32 __CFUNC     DAQmxSaveScale                   (const char scaleName[], const char saveAs[], const char author[], uInt32 options);
int32 __CFUNC     DAQmxDeleteSavedTask             (const char taskName[]);
int32 __CFUNC     DAQmxDeleteSavedGlobalChan       (const char channelName[]);
int32 __CFUNC     DAQmxDeleteSavedScale            (const char scaleName[]);

int32 __CFUNC_C   DAQmxGetPersistedTaskAttribute   (const char taskName[], int32 attribute, void *value, ...);
int32 __CFUNC_C   DAQmxGetPersistedChanAttribute   (const char channel[], int32 attribute, void *value, ...);
int32 __CFUNC_C   DAQmxGetPersistedScaleAttribute  (const char scaleName[], int32 attribute, void *value, ...);


/******************************************************/
/***              System Configuration              ***/
/******************************************************/

int32 __CFUNC_C   DAQmxGetSystemInfoAttribute (int32 attribute, void *value, ...);
int32 __CFUNC_C   DAQmxSetDigitalPowerUpStates(const char deviceName[], const char channelNames[], int32 state, ...);
int32 __CFUNC_C   DAQmxSetAnalogPowerUpStates(const char deviceName[], const char channelNames[], float64 state, int32 channelType, ...);

/******************************************************/
/***                 Error Handling                 ***/
/******************************************************/


int32 __CFUNC     DAQmxGetErrorString       (int32 errorCode, char errorString[], uInt32 bufferSize);
int32 __CFUNC     DAQmxGetExtendedErrorInfo (char errorString[], uInt32 bufferSize);


/******************************************************************************
 *** NI-DAQmx Specific Attribute Get/Set/Reset Function Declarations **********
 ******************************************************************************/

//********** Buffer **********
//*** Set/Get functions for DAQmx_Buf_Input_BufSize ***
int32 __CFUNC DAQmxGetBufInputBufSize(TaskHandle taskHandle, uInt32 *data);
int32 __CFUNC DAQmxSetBufInputBufSize(TaskHandle taskHandle, uInt32 data);
int32 __CFUNC DAQmxResetBufInputBufSize(TaskHandle taskHandle);
//*** Set/Get functions for DAQmx_Buf_Input_OnbrdBufSize ***
int32 __CFUNC DAQmxGetBufInputOnbrdBufSize(TaskHandle taskHandle, uInt32 *data);
//*** Set/Get functions for DAQmx_Buf_Output_BufSize ***
int32 __CFUNC DAQmxGetBufOutputBufSize(TaskHandle taskHandle, uInt32 *data);
int32 __CFUNC DAQmxSetBufOutputBufSize(TaskHandle taskHandle, uInt32 data);
int32 __CFUNC DAQmxResetBufOutputBufSize(TaskHandle taskHandle);
//*** Set/Get functions for DAQmx_Buf_Output_OnbrdBufSize ***
int32 __CFUNC DAQmxGetBufOutputOnbrdBufSize(TaskHandle taskHandle, uInt32 *data);
int32 __CFUNC DAQmxSetBufOutputOnbrdBufSize(TaskHandle taskHandle, uInt32 data);
int32 __CFUNC DAQmxResetBufOutputOnbrdBufSize(TaskHandle taskHandle);

//********** Calibration Info **********
//*** Set/Get functions for DAQmx_SelfCal_Supported ***
int32 __CFUNC DAQmxGetSelfCalSupported(const char deviceName[], bool32 *data);
//*** Set/Get functions for DAQmx_SelfCal_LastTemp ***
int32 __CFUNC DAQmxGetSelfCalLastTemp(const char deviceName[], float64 *data);
//*** Set/Get functions for DAQmx_ExtCal_RecommendedInterval ***
int32 __CFUNC DAQmxGetExtCalRecommendedInterval(const char deviceName[], uInt32 *data);
//*** Set/Get functions for DAQmx_ExtCal_LastTemp ***
int32 __CFUNC DAQmxGetExtCalLastTemp(const char deviceName[], float64 *data);
//*** Set/Get functions for DAQmx_Cal_UserDefinedInfo ***
int32 __CFUNC DAQmxGetCalUserDefinedInfo(const char deviceName[], char *data, uInt32 bufferSize);
int32 __CFUNC DAQmxSetCalUserDefinedInfo(const char deviceName[], const char *data);
//*** Set/Get functions for DAQmx_Cal_UserDefinedInfo_MaxSize ***
int32 __CFUNC DAQmxGetCalUserDefinedInfoMaxSize(const char deviceName[], uInt32 *data);
//*** Set/Get functions for DAQmx_Cal_DevTemp ***
int32 __CFUNC DAQmxGetCalDevTemp(const char deviceName[], float64 *data);

//********** Channel **********
//*** Set/Get functions for DAQmx_AI_Max ***
int32 __CFUNC DAQmxGetAIMax(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIMax(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIMax(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Min ***
int32 __CFUNC DAQmxGetAIMin(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIMin(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIMin(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_CustomScaleName ***
int32 __CFUNC DAQmxGetAICustomScaleName(TaskHandle taskHandle, const char channel[], char *data, uInt32 bufferSize);
int32 __CFUNC DAQmxSetAICustomScaleName(TaskHandle taskHandle, const char channel[], const char *data);
int32 __CFUNC DAQmxResetAICustomScaleName(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_MeasType ***
// Uses value set AIMeasurementType
int32 __CFUNC DAQmxGetAIMeasType(TaskHandle taskHandle, const char channel[], int32 *data);
//*** Set/Get functions for DAQmx_AI_Voltage_Units ***
// Uses value set VoltageUnits1
int32 __CFUNC DAQmxGetAIVoltageUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIVoltageUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIVoltageUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Temp_Units ***
// Uses value set TemperatureUnits1
int32 __CFUNC DAQmxGetAITempUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAITempUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAITempUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Thrmcpl_Type ***
// Uses value set ThermocoupleType1
int32 __CFUNC DAQmxGetAIThrmcplType(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIThrmcplType(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIThrmcplType(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Thrmcpl_CJCSrc ***
// Uses value set CJCSource1
int32 __CFUNC DAQmxGetAIThrmcplCJCSrc(TaskHandle taskHandle, const char channel[], int32 *data);
//*** Set/Get functions for DAQmx_AI_Thrmcpl_CJCVal ***
int32 __CFUNC DAQmxGetAIThrmcplCJCVal(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIThrmcplCJCVal(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIThrmcplCJCVal(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Thrmcpl_CJCChan ***
int32 __CFUNC DAQmxGetAIThrmcplCJCChan(TaskHandle taskHandle, const char channel[], char *data, uInt32 bufferSize);
//*** Set/Get functions for DAQmx_AI_RTD_Type ***
// Uses value set RTDType1
int32 __CFUNC DAQmxGetAIRTDType(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIRTDType(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIRTDType(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_RTD_R0 ***
int32 __CFUNC DAQmxGetAIRTDR0(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIRTDR0(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIRTDR0(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_RTD_A ***
int32 __CFUNC DAQmxGetAIRTDA(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIRTDA(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIRTDA(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_RTD_B ***
int32 __CFUNC DAQmxGetAIRTDB(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIRTDB(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIRTDB(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_RTD_C ***
int32 __CFUNC DAQmxGetAIRTDC(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIRTDC(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIRTDC(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Thrmstr_A ***
int32 __CFUNC DAQmxGetAIThrmstrA(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIThrmstrA(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIThrmstrA(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Thrmstr_B ***
int32 __CFUNC DAQmxGetAIThrmstrB(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIThrmstrB(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIThrmstrB(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Thrmstr_C ***
int32 __CFUNC DAQmxGetAIThrmstrC(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIThrmstrC(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIThrmstrC(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Thrmstr_R1 ***
int32 __CFUNC DAQmxGetAIThrmstrR1(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIThrmstrR1(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIThrmstrR1(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_ForceReadFromChan ***
int32 __CFUNC DAQmxGetAIForceReadFromChan(TaskHandle taskHandle, const char channel[], bool32 *data);
int32 __CFUNC DAQmxSetAIForceReadFromChan(TaskHandle taskHandle, const char channel[], bool32 data);
int32 __CFUNC DAQmxResetAIForceReadFromChan(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Current_Units ***
// Uses value set CurrentUnits1
int32 __CFUNC DAQmxGetAICurrentUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAICurrentUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAICurrentUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Strain_Units ***
// Uses value set StrainUnits1
int32 __CFUNC DAQmxGetAIStrainUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIStrainUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIStrainUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_StrainGage_GageFactor ***
int32 __CFUNC DAQmxGetAIStrainGageGageFactor(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIStrainGageGageFactor(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIStrainGageGageFactor(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_StrainGage_PoissonRatio ***
int32 __CFUNC DAQmxGetAIStrainGagePoissonRatio(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIStrainGagePoissonRatio(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIStrainGagePoissonRatio(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_StrainGage_Cfg ***
// Uses value set StrainGageBridgeType1
int32 __CFUNC DAQmxGetAIStrainGageCfg(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIStrainGageCfg(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIStrainGageCfg(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Resistance_Units ***
// Uses value set ResistanceUnits1
int32 __CFUNC DAQmxGetAIResistanceUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIResistanceUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIResistanceUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Freq_Units ***
// Uses value set FrequencyUnits
int32 __CFUNC DAQmxGetAIFreqUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIFreqUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIFreqUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Freq_ThreshVoltage ***
int32 __CFUNC DAQmxGetAIFreqThreshVoltage(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIFreqThreshVoltage(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIFreqThreshVoltage(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Freq_Hyst ***
int32 __CFUNC DAQmxGetAIFreqHyst(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIFreqHyst(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIFreqHyst(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_LVDT_Units ***
// Uses value set LengthUnits2
int32 __CFUNC DAQmxGetAILVDTUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAILVDTUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAILVDTUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_LVDT_Sensitivity ***
int32 __CFUNC DAQmxGetAILVDTSensitivity(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAILVDTSensitivity(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAILVDTSensitivity(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_LVDT_SensitivityUnits ***
// Uses value set LVDTSensitivityUnits1
int32 __CFUNC DAQmxGetAILVDTSensitivityUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAILVDTSensitivityUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAILVDTSensitivityUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_RVDT_Units ***
// Uses value set AngleUnits1
int32 __CFUNC DAQmxGetAIRVDTUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIRVDTUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIRVDTUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_RVDT_Sensitivity ***
int32 __CFUNC DAQmxGetAIRVDTSensitivity(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIRVDTSensitivity(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIRVDTSensitivity(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_RVDT_SensitivityUnits ***
// Uses value set RVDTSensitivityUnits1
int32 __CFUNC DAQmxGetAIRVDTSensitivityUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIRVDTSensitivityUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIRVDTSensitivityUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_SoundPressure_MaxSoundPressureLvl ***
int32 __CFUNC DAQmxGetAISoundPressureMaxSoundPressureLvl(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAISoundPressureMaxSoundPressureLvl(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAISoundPressureMaxSoundPressureLvl(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_SoundPressure_Units ***
// Uses value set SoundPressureUnits1
int32 __CFUNC DAQmxGetAISoundPressureUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAISoundPressureUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAISoundPressureUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Microphone_Sensitivity ***
int32 __CFUNC DAQmxGetAIMicrophoneSensitivity(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIMicrophoneSensitivity(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIMicrophoneSensitivity(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Accel_Units ***
// Uses value set AccelUnits2
int32 __CFUNC DAQmxGetAIAccelUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIAccelUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIAccelUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Accel_Sensitivity ***
int32 __CFUNC DAQmxGetAIAccelSensitivity(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIAccelSensitivity(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIAccelSensitivity(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Accel_SensitivityUnits ***
// Uses value set AccelSensitivityUnits1
int32 __CFUNC DAQmxGetAIAccelSensitivityUnits(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIAccelSensitivityUnits(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIAccelSensitivityUnits(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_TEDS_Units ***
int32 __CFUNC DAQmxGetAITEDSUnits(TaskHandle taskHandle, const char channel[], char *data, uInt32 bufferSize);
//*** Set/Get functions for DAQmx_AI_Coupling ***
// Uses value set Coupling1
int32 __CFUNC DAQmxGetAICoupling(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAICoupling(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAICoupling(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Impedance ***
// Uses value set Impedance1
int32 __CFUNC DAQmxGetAIImpedance(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIImpedance(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIImpedance(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_TermCfg ***
// Uses value set InputTermCfg
int32 __CFUNC DAQmxGetAITermCfg(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAITermCfg(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAITermCfg(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_InputSrc ***
int32 __CFUNC DAQmxGetAIInputSrc(TaskHandle taskHandle, const char channel[], char *data, uInt32 bufferSize);
int32 __CFUNC DAQmxSetAIInputSrc(TaskHandle taskHandle, const char channel[], const char *data);
int32 __CFUNC DAQmxResetAIInputSrc(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_ResistanceCfg ***
// Uses value set ResistanceConfiguration
int32 __CFUNC DAQmxGetAIResistanceCfg(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIResistanceCfg(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIResistanceCfg(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_LeadWireResistance ***
int32 __CFUNC DAQmxGetAILeadWireResistance(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAILeadWireResistance(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAILeadWireResistance(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Bridge_Cfg ***
// Uses value set BridgeConfiguration1
int32 __CFUNC DAQmxGetAIBridgeCfg(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIBridgeCfg(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIBridgeCfg(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Bridge_NomResistance ***
int32 __CFUNC DAQmxGetAIBridgeNomResistance(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIBridgeNomResistance(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIBridgeNomResistance(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Bridge_InitialVoltage ***
int32 __CFUNC DAQmxGetAIBridgeInitialVoltage(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIBridgeInitialVoltage(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIBridgeInitialVoltage(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Bridge_ShuntCal_Enable ***
int32 __CFUNC DAQmxGetAIBridgeShuntCalEnable(TaskHandle taskHandle, const char channel[], bool32 *data);
int32 __CFUNC DAQmxSetAIBridgeShuntCalEnable(TaskHandle taskHandle, const char channel[], bool32 data);
int32 __CFUNC DAQmxResetAIBridgeShuntCalEnable(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Bridge_ShuntCal_Select ***
// Uses value set ShuntCalSelect
int32 __CFUNC DAQmxGetAIBridgeShuntCalSelect(TaskHandle taskHandle, const char channel[], int32 *data);
int32 __CFUNC DAQmxSetAIBridgeShuntCalSelect(TaskHandle taskHandle, const char channel[], int32 data);
int32 __CFUNC DAQmxResetAIBridgeShuntCalSelect(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Bridge_ShuntCal_GainAdjust ***
int32 __CFUNC DAQmxGetAIBridgeShuntCalGainAdjust(TaskHandle taskHandle, const char channel[], float64 *data);
int32 __CFUNC DAQmxSetAIBridgeShuntCalGainAdjust(TaskHandle taskHandle, const char channel[], float64 data);
int32 __CFUNC DAQmxResetAIBridgeShuntCalGainAdjust(TaskHandle taskHandle, const char channel[]);
//*** Set/Get functions for DAQmx_AI_Bridge_Balance_CoarsePot ***
int32 __CFUNC DAQmxGetAIBr