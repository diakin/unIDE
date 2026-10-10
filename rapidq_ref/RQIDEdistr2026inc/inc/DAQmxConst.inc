
''*****************************************************************************
' *** NI-DAQmx Attributes ******************************************************
' ******************************************************************************/
const minus_1=-1

'********** Buffer Attributes **********
$define DAQmx_Buf_Input_BufSize                                          &H186C ' Specifies the number of samples the input buffer can hold for each channel in the task. Zero indicates to allocate no buffer. Use a buffer size of 0 to perform a hardware-timed operation without using a buffer. Setting this property overrides the automatic input buffer allocation that NI-DAQmx performs.
$define DAQmx_Buf_Input_OnbrdBufSize                                     &H230A ' Indicates in samples per channel the size of the onboard input buffer of the device.
$define DAQmx_Buf_Output_BufSize                                         &H186D ' Specifies the number of samples the output buffer can hold for each channel in the task. Zero indicates to allocate no buffer. Use a buffer size of 0 to perform a hardware-timed operation without using a buffer. Setting this property overrides the automatic output buffer allocation that NI-DAQmx performs.
$define DAQmx_Buf_Output_OnbrdBufSize                                    &H230B ' Specifies in samples per channel the size of the onboard output buffer of the device.

'********** Calibration Info Attributes **********
$define DAQmx_SelfCal_Supported                                          &H1860 ' Indicates whether the device supports self calibration.
$define DAQmx_SelfCal_LastTemp                                           &H1864 ' Indicates in degrees Celsius the temperature of the device at the time of the last self calibration. Compare this temperature to the current onboard temperature to determine if you should perform another calibration.
$define DAQmx_ExtCal_RecommendedInterval                                 &H1868 ' Indicates in months the National Instruments recommended interval between each external calibration of the device.
$define DAQmx_ExtCal_LastTemp                                            &H1867 ' Indicates in degrees Celsius the temperature of the device at the time of the last external calibration. Compare this temperature to the current onboard temperature to determine if you should perform another calibration.
$define DAQmx_Cal_UserDefinedInfo                                        &H1861 ' Specifies a string that contains arbitrary, user-defined information. This number of characters in this string can be no more than Max Size.
$define DAQmx_Cal_UserDefinedInfo_MaxSize                                &H191C ' Indicates the maximum length in characters of Information.
$define DAQmx_Cal_DevTemp                                                &H223B ' Indicates in degrees Celsius the current temperature of the device.

'********** Channel Attributes **********
$define DAQmx_AI_Max                                                     &H17DD ' Specifies the maximum value you expect to measure. This value is in the units you specify with a units property. When you query this property, it returns the coerced maximum value that the device can measure with the current settings.
$define DAQmx_AI_Min                                                     &H17DE ' Specifies the minimum value you expect to measure. This value is in the units you specify with a units property.  When you query this property, it returns the coerced minimum value that the device can measure with the current settings.
$define DAQmx_AI_CustomScaleName                                         &H17E0 ' Specifies the name of a custom scale for the channel.
$define DAQmx_AI_MeasType                                                &H0695 ' Indicates the measurement to take with the analog input channel and in some cases, such as for temperature measurements, the sensor to use.
$define DAQmx_AI_Voltage_Units                                           &H1094 ' Specifies the units to use to return voltage measurements from the channel.
$define DAQmx_AI_Temp_Units                                              &H1033 ' Specifies the units to use to return temperature measurements from the channel.
$define DAQmx_AI_Thrmcpl_Type                                            &H1050 ' Specifies the type of thermocouple connected to the channel. Thermocouple types differ in composition and measurement range.
$define DAQmx_AI_Thrmcpl_CJCSrc                                          &H1035 ' Indicates the source of cold-junction compensation.
$define DAQmx_AI_Thrmcpl_CJCVal                                          &H1036 ' Specifies the temperature of the cold junction if CJC Source is DAQmx_Val_ConstVal. Specify this value in the units of the measurement.
$define DAQmx_AI_Thrmcpl_CJCChan                                         &H1034 ' Indicates the channel that acquires the temperature of the cold junction if CJC Source is DAQmx_Val_Chan. If the channel is a temperature channel, NI-DAQmx acquires the temperature in the correct units. Other channel types, such as a resistance channel with a custom sensor, must use a custom scale to scale values to degrees Celsius.
$define DAQmx_AI_RTD_Type                                                &H1032 ' Specifies the type of RTD connected to the channel.
$define DAQmx_AI_RTD_R0                                                  &H1030 ' Specifies in ohms the sensor resistance at 0 deg C. The Callendar-Van Dusen equation requires this value. Refer to the sensor documentation to determine this value.
$define DAQmx_AI_RTD_A                                                   &H1010 ' Specifies the 'A' constant of the Callendar-Van Dusen equation. NI-DAQmx requires this value when you use a custom RTD.
$define DAQmx_AI_RTD_B                                                   &H1011 ' Specifies the 'B' constant of the Callendar-Van Dusen equation. NI-DAQmx requires this value when you use a custom RTD.
$define DAQmx_AI_RTD_C                                                   &H1013 ' Specifies the 'C' constant of the Callendar-Van Dusen equation. NI-DAQmx requires this value when you use a custom RTD.
$define DAQmx_AI_Thrmstr_A                                               &H18C9 ' Specifies the 'A' constant of the Steinhart-Hart thermistor equation.
$define DAQmx_AI_Thrmstr_B                                               &H18CB ' Specifies the 'B' constant of the Steinhart-Hart thermistor equation.
$define DAQmx_AI_Thrmstr_C                                               &H18CA ' Specifies the 'C' constant of the Steinhart-Hart thermistor equation.
$define DAQmx_AI_Thrmstr_R1                                              &H1061 ' Specifies in ohms the value of the reference resistor if you use voltage excitation. NI-DAQmx ignores this value for current excitation.
$define DAQmx_AI_ForceReadFromChan                                       &H18F8 ' Specifies whether to read from the channel if it is a cold-junction compensation channel. By default, an NI-DAQmx Read function does not return data from cold-junction compensation channels.  Setting this property to TRUE forces read operations to return the cold-junction compensation channel data with the other channels in the task.
$define DAQmx_AI_Current_Units                                           &H0701 ' Specifies the units to use to return current measurements from the channel.
$define DAQmx_AI_Strain_Units                                            &H0981 ' Specifies the units to use to return strain measurements from the channel.
$define DAQmx_AI_StrainGage_GageFactor                                   &H0994 ' Specifies the sensitivity of the strain gage.  Gage factor relates the change in electrical resistance to the change in strain. Refer to the sensor documentation for this value.
$define DAQmx_AI_StrainGage_PoissonRatio                                 &H0998 ' Specifies the ratio of lateral strain to axial strain in the material you are measuring.
$define DAQmx_AI_StrainGage_Cfg                                          &H0982 ' Specifies the bridge configuration of the strain gages.
$define DAQmx_AI_Resistance_Units                                        &H0955 ' Specifies the units to use to return resistance measurements.
$define DAQmx_AI_Freq_Units                                              &H0806 ' Specifies the units to use to return frequency measurements from the channel.
$define DAQmx_AI_Freq_ThreshVoltage                                      &H0815 ' Specifies the voltage level at which to recognize waveform repetitions. You should select a voltage level that occurs only once within the entire period of a waveform. You also can select a voltage that occurs only once while the voltage rises or falls.
$define DAQmx_AI_Freq_Hyst                                               &H0814 ' Specifies in volts a window below Threshold Level. The input voltage must pass below Threshold Level minus this value before NI-DAQmx recognizes a waveform repetition at Threshold Level. Hysteresis can improve the measurement accuracy when the signal contains noise or jitter.
$define DAQmx_AI_LVDT_Units                                              &H0910 ' Specifies the units to use to return linear position measurements from the channel.
$define DAQmx_AI_LVDT_Sensitivity                                        &H0939 ' Specifies the sensitivity of the LVDT. This value is in the units you specify with Sensitivity Units. Refer to the sensor documentation to determine this value.
$define DAQmx_AI_LVDT_SensitivityUnits                                   &H219A ' Specifies the units of Sensitivity.
$define DAQmx_AI_RVDT_Units                                              &H0877 ' Specifies the units to use to return angular position measurements from the channel.
$define DAQmx_AI_RVDT_Sensitivity                                        &H0903 ' Specifies the sensitivity of the RVDT. This value is in the units you specify with Sensitivity Units. Refer to the sensor documentation to determine this value.
$define DAQmx_AI_RVDT_SensitivityUnits                                   &H219B ' Specifies the units of Sensitivity.
$define DAQmx_AI_SoundPressure_MaxSoundPressureLvl                       &H223A ' Specifies the maximum instantaneous sound pressure level you expect to measure. This value is in decibels, referenced to 20 micropascals. NI-DAQmx uses the maximum sound pressure level to calculate values in pascals for Maximum Value and Minimum Value for the channel.
$define DAQmx_AI_SoundPressure_Units                                     &H1528 ' Specifies the units to use to return sound pressure measurements from the channel.
$define DAQmx_AI_Microphone_Sensitivity                                  &H1536 ' Specifies the sensitivity of the microphone. This value is in mV/Pa. Refer to the sensor documentation to determine this value.
$define DAQmx_AI_Accel_Units                                             &H0673 ' Specifies the units to use to return acceleration measurements from the channel.
$define DAQmx_AI_Accel_Sensitivity                                       &H0692 ' Specifies the sensitivity of the accelerometer. This value is in the units you specify with Sensitivity Units. Refer to the sensor documentation to determine this value.
$define DAQmx_AI_Accel_SensitivityUnits                                  &H219C ' Specifies the units of Sensitivity.
$define DAQmx_AI_TEDS_Units                                              &H21E0 ' Indicates the units defined by TEDS information associated with the channel.
$define DAQmx_AI_Coupling                                                &H0064 ' Specifies the coupling for the channel.
$define DAQmx_AI_Impedance                                               &H0062 ' Specifies the input impedance of the channel.
$define DAQmx_AI_TermCfg                                                 &H1097 ' Specifies the terminal configuration for the channel.
$define DAQmx_AI_InputSrc                                                &H2198 ' Specifies the source of the channel. You can use the signal from the I/O connector or one of several calibration signals. Certain devices have a single calibration signal bus. For these devices, you must specify the same calibration signal for all channels you connect to a calibration signal.
$define DAQmx_AI_ResistanceCfg                                           &H1881 ' Specifies the resistance configuration for the channel. NI-DAQmx uses this value for any resistance-based measurements, including temperature measurement using a thermistor or RTD.
$define DAQmx_AI_LeadWireResistance                                      &H17EE ' Specifies in ohms the resistance of the wires that lead to the sensor.
$define DAQmx_AI_Bridge_Cfg                                              &H0087 ' Specifies the type of Wheatstone bridge that the sensor is.
$define DAQmx_AI_Bridge_NomResistance                                    &H17EC ' Specifies in ohms the resistance across each arm of the bridge in an unloaded position.
$define DAQmx_AI_Bridge_InitialVoltage                                   &H17ED ' Specifies in volts the output voltage of the bridge in the unloaded condition. NI-DAQmx subtracts this value from any measurements before applying scaling equations.
$define DAQmx_AI_Bridge_ShuntCal_Enable                                  &H0094 ' Specifies whether to enable a shunt calibration switch. Use Shunt Cal Select to select the switch(es) to enable.
$define DAQmx_AI_Bridge_ShuntCal_Select                                  &H21D5 ' Specifies which shunt calibration switch(es) to enable.  Use Shunt Cal Enable to enable the switch(es) you specify with this property.
$define DAQmx_AI_Bridge_ShuntCal_GainAdjust                              &H193F ' Specifies the result of a shunt calibration. NI-DAQmx multiplies data read from the channel by the value of this property. This value should be close to 1.0.
$define DAQmx_AI_Bridge_Balance_CoarsePot                                &H17F1 ' Specifies by how much to compensate for offset in the signal. This value can be between 0 and 127.
$define DAQmx_AI_Bridge_Balance_FinePot                                  &H18F4 ' Specifies by how much to compensate for offset in the signal. This value can be between 0 and 4095.
$define DAQmx_AI_CurrentShunt_Loc                                        &H17F2 ' Specifies the shunt resistor location for current measurements.
$define DAQmx_AI_CurrentShunt_Resistance                                 &H17F3 ' Specifies in ohms the external shunt resistance for current measurements.
$define DAQmx_AI_Excit_Src                                               &H17F4 ' Specifies the source of excitation.
$define DAQmx_AI_Excit_Val                                               &H17F5 ' Specifies the amount of excitation that the sensor requires. If Voltage or Current is  DAQmx_Val_Voltage, this value is in volts. If Voltage or Current is  DAQmx_Val_Current, this value is in amperes.
$define DAQmx_AI_Excit_UseForScaling                                     &H17FC ' Specifies if NI-DAQmx divides the measurement by the excitation. You should typically set this property to TRUE for ratiometric transducers. If you set this property to TRUE, set Maximum Value and Minimum Value to reflect the scaling.
$define DAQmx_AI_Excit_UseMultiplexed                                    &H2180 ' Specifies if the SCXI-1122 multiplexes the excitation to the upper half of the channels as it advances through the scan list.
$define DAQmx_AI_Excit_ActualVal                                         &H1883 ' Specifies the actual amount of excitation supplied by an internal excitation source.  If you read an internal excitation source more precisely with an external device, set this property to the value you read.  NI-DAQmx ignores this value for external excitation.
$define DAQmx_AI_Excit_DCorAC                                            &H17FB ' Specifies if the excitation supply is DC or AC.
$define DAQmx_AI_Excit_VoltageOrCurrent                                  &H17F6 ' Specifies if the channel uses current or voltage excitation.
$define DAQmx_AI_ACExcit_Freq                                            &H0101 ' Specifies the AC excitation frequency in Hertz.
$define DAQmx_AI_ACExcit_SyncEnable                                      &H0102 ' Specifies whether to synchronize the AC excitation source of the channel to that of another channel. Synchronize the excitation sources of multiple channels to use multichannel sensors. Set this property to FALSE for the master channel and to TRUE for the slave channels.
$define DAQmx_AI_ACExcit_WireMode                                        &H18CD ' Specifies the number of leads on the LVDT or RVDT. Some sensors require you to tie leads together to create a four- or five- wire sensor. Refer to the sensor documentation for more information.
$define DAQmx_AI_Atten                                                   &H1801 ' Specifies the amount of attenuation to use.
$define DAQmx_AI_Lowpass_Enable                                          &H1802 ' Specifies whether to enable the lowpass filter of the channel.
$define DAQmx_AI_Lowpass_CutoffFreq                                      &H1803 ' Specifies the frequency in Hertz that corresponds to the -3dB cutoff of the filter.
$define DAQmx_AI_Lowpass_SwitchCap_ClkSrc                                &H1884 ' Specifies the source of the filter clock. If you need a higher resolution for the filter, you can supply an external clock to increase the resolution. Refer to the SCXI-1141/1142/1143 User Manual for more information.
$define DAQmx_AI_Lowpass_SwitchCap_ExtClkFreq                            &H1885 ' Specifies the frequency of the external clock when you set Clock Source to DAQmx_Val_External.  NI-DAQmx uses this frequency to set the pre- and post- filters on the SCXI-1141, SCXI-1142, and SCXI-1143. On those devices, NI-DAQmx determines the filter cutoff by using the equation f/(100*n), where f is the external frequency, and n is the external clock divisor. Refer to the SCXI-1141/1142/1143 User Manual for more...
$define DAQmx_AI_Lowpass_SwitchCap_ExtClkDiv                             &H1886 ' Specifies the divisor for the external clock when you set Clock Source to DAQmx_Val_External. On the SCXI-1141, SCXI-1142, and SCXI-1143, NI-DAQmx determines the filter cutoff by using the equation f/(100*n), where f is the external frequency, and n is the external clock divisor. Refer to the SCXI-1141/1142/1143 User Manual for more information.
$define DAQmx_AI_Lowpass_SwitchCap_OutClkDiv                             &H1887 ' Specifies the divisor for the output clock.  NI-DAQmx uses the cutoff frequency to determine the output clock frequency. Refer to the SCXI-1141/1142/1143 User Manual for more information.
$define DAQmx_AI_ResolutionUnits                                         &H1764 ' Indicates the units of Resolution Value.
$define DAQmx_AI_Resolution                                              &H1765 ' Indicates the resolution of the analog-to-digital converter of the channel. This value is in the units you specify with Resolution Units.
$define DAQmx_AI_RawSampSize                                             &H22DA ' Indicates in bits the size of a raw sample from the device.
$define DAQmx_AI_RawSampJustification                                    &H0050 ' Indicates the justification of a raw sample from the device.
$define DAQmx_AI_Dither_Enable                                           &H0068 ' Specifies whether to enable dithering.  Dithering adds Gaussian noise to the input signal. You can use dithering to achieve higher resolution measurements by over sampling the input signal and averaging the results.
$define DAQmx_AI_ChanCal_HasValidCalInfo                                 &H2297 ' Indicates if the channel has calibration information.
$define DAQmx_AI_ChanCal_EnableCal                                       &H2298 ' Specifies whether to enable the channel calibration associated with the channel.
$define DAQmx_AI_ChanCal_ApplyCalIfExp                                   &H2299 ' Specifies whether to apply the channel calibration to the channel after the expiration date has passed.
$define DAQmx_AI_ChanCal_ScaleType                                       &H229C ' Specifies the method or equation form that the calibration scale uses.
$define DAQmx_AI_ChanCal_Table_PreScaledVals                             &H229D ' Specifies the reference values collected when calibrating the channel.
$define DAQmx_AI_ChanCal_Table_ScaledVals                                &H229E ' Specifies the acquired values collected when calibrating the channel.
$define DAQmx_AI_ChanCal_Poly_ForwardCoeff                               &H229F ' Specifies the forward polynomial values used for calibrating the channel.
$define DAQmx_AI_ChanCal_Poly_ReverseCoeff                               &H22A0 ' Specifies the reverse polynomial values used for calibrating the channel.
$define DAQmx_AI_ChanCal_OperatorName                                    &H22A3 ' Specifies the name of the operator who performed the channel calibration.
$define DAQmx_AI_ChanCal_Desc                                            &H22A4 ' Specifies the description entered for the calibration of the channel.
$define DAQmx_AI_ChanCal_Verif_RefVals                                   &H22A1 ' Specifies the reference values collected when verifying the calibration. NI-DAQmx stores these values as a record of calibration accuracy and does not use them in the scaling process.
$define DAQmx_AI_ChanCal_Verif_AcqVals                                   &H22A2 ' Specifies the acquired values collected when verifying the calibration. NI-DAQmx stores these values as a record of calibration accuracy and does not use them in the scaling process.
$define DAQmx_AI_Rng_High                                                &H1815 ' Specifies the upper limit of the input range of the device. This value is in the native units of the device. On E Series devices, for example, the native units is volts.
$define DAQmx_AI_Rng_Low                                                 &H1816 ' Specifies the lower limit of the input range of the device. This value is in the native units of the device. On E Series devices, for example, the native units is volts.
$define DAQmx_AI_Gain                                                    &H1818 ' Specifies a gain factor to apply to the channel.
$define DAQmx_AI_SampAndHold_Enable                                      &H181A ' Specifies whether to enable the sample and hold circuitry of the device. When you disable sample and hold circuitry, a small voltage offset might be introduced into the signal.  You can eliminate this offset by using Auto Zero Mode to perform an auto zero on the channel.
$define DAQmx_AI_AutoZeroMode                                            &H1760 ' Specifies when to measure ground. NI-DAQmx subtracts the measured ground voltage from every sample.
$define DAQmx_AI_DataXferMech                                            &H1821 ' Specifies the data transfer mode for the device.
$define DAQmx_AI_DataXferReqCond                                         &H188B ' Specifies under what condition to transfer data from the onboard memory of the device to the buffer.
$define DAQmx_AI_DataXferCustomThreshold                                 &H230C ' Specifies the number of samples that must be in the FIFO to transfer data from the device if Data Transfer Request Condition is DAQmx_Val_OnbrdMemCustomThreshold.
$define DAQmx_AI_MemMapEnable                                            &H188C ' Specifies for NI-DAQmx to map hardware registers to the memory space of the customer process, if possible. Mapping to the memory space of the customer process increases performance. However, memory mapping can adversely affect the operation of the device and possibly result in a system crash if software in the process unintentionally accesses the mapped registers.
$define DAQmx_AI_RawDataCompressionType                                  &H22D8 ' Specifies the type of compression to apply to raw samples returned from the device.
$define DAQmx_AI_LossyLSBRemoval_CompressedSampSize                      &H22D9 ' Specifies the number of bits to return in a raw samples when Raw Data Compression Type is set to DAQmx_Val_LossyLSBRemoval.
$define DAQmx_AI_DevScalingCoeff                                         &H1930 ' Indicates the coefficients of a polynomial equation that NI-DAQmx uses to scale values from the native format of the device to volts. Each element of the array corresponds to a term of the equation. For example, if index two of the array is 4, the third term of the equation is 4x^2. Scaling coefficients do not account for any custom scales or sensors contained by the channel.
$define DAQmx_AI_EnhancedAliasRejectionEnable                            &H2294 ' Specifies whether to enable enhanced alias rejection. By default, enhanced alias rejection is enabled on supported devices. Leave this property set to the default value for most applications.
$define DAQmx_AO_Max                                                     &H1186 ' Specifies the maximum value you expect to generate. The value is in the units you specify with a units property. If you try to write a value larger than the maximum value, NI-DAQmx generates an error. NI-DAQmx might coerce this value to a smaller value if other task settings restrict the device from generating the desired maximum.
$define DAQmx_AO_Min                                                     &H1187 ' Specifies the minimum value you expect to generate. The value is in the units you specify with a units property. If you try to write a value smaller than the minimum value, NI-DAQmx generates an error. NI-DAQmx might coerce this value to a larger value if other task settings restrict the device from generating the desired minimum.
$define DAQmx_AO_CustomScaleName                                         &H1188 ' Specifies the name of a custom scale for the channel.
$define DAQmx_AO_OutputType                                              &H1108 ' Indicates whether the channel generates voltage or current.
$define DAQmx_AO_Voltage_Units                                           &H1184 ' Specifies in what units to generate voltage on the channel. Write data to the channel in the units you select.
$define DAQmx_AO_Current_Units                                           &H1109 ' Specifies in what units to generate current on the channel. Write data to the channel is in the units you select.
$define DAQmx_AO_OutputImpedance                                         &H1490 ' Specifies in ohms the impedance of the analog output stage of the device.
$define DAQmx_AO_LoadImpedance                                           &H0121 ' Specifies in ohms the load impedance connected to the analog output channel.
$define DAQmx_AO_IdleOutputBehavior                                      &H2240 ' Specifies the state of the channel when no generation is in progress.
$define DAQmx_AO_TermCfg                                                 &H188E ' Specifies the terminal configuration of the channel.
$define DAQmx_AO_ResolutionUnits                                         &H182B ' Specifies the units of Resolution Value.
$define DAQmx_AO_Resolution                                              &H182C ' Indicates the resolution of the digital-to-analog converter of the channel. This value is in the units you specify with Resolution Units.
$define DAQmx_AO_DAC_Rng_High                                            &H182E ' Specifies the upper limit of the output range of the device. This value is in the native units of the device. On E Series devices, for example, the native units is volts.
$define DAQmx_AO_DAC_Rng_Low                                             &H182D ' Specifies the lower limit of the output range of the device. This value is in the native units of the device. On E Series devices, for example, the native units is volts.
$define DAQmx_AO_DAC_Ref_ConnToGnd                                       &H0130 ' Specifies whether to ground the internal DAC reference. Grounding the internal DAC reference has the effect of grounding all analog output channels and stopping waveform generation across all analog output channels regardless of whether the channels belong to the current task. You can ground the internal DAC reference only when Source is DAQmx_Val_Internal and Allow Connecting DAC Reference to Ground at Runtime is...
$define DAQmx_AO_DAC_Ref_AllowConnToGnd                                  &H1830 ' Specifies whether to allow grounding the internal DAC reference at run time. You must set this property to TRUE and set Source to DAQmx_Val_Internal before you can set Connect DAC Reference to Ground to TRUE.
$define DAQmx_AO_DAC_Ref_Src                                             &H0132 ' Specifies the source of the DAC reference voltage. The value of this voltage source determines the full-scale value of the DAC.
$define DAQmx_AO_DAC_Ref_ExtSrc                                          &H2252 ' Specifies the source of the DAC reference voltage if Source is DAQmx_Val_External.
$define DAQmx_AO_DAC_Ref_Val                                             &H1832 ' Specifies in volts the value of the DAC reference voltage. This voltage determines the full-scale range of the DAC. Smaller reference voltages result in smaller ranges, but increased resolution.
$define DAQmx_AO_DAC_Offset_Src                                          &H2253 ' Specifies the source of the DAC offset voltage. The value of this voltage source determines the full-scale value of the DAC.
$define DAQmx_AO_DAC_Offset_ExtSrc                                       &H2254 ' Specifies the source of the DAC offset voltage if Source is DAQmx_Val_External.
$define DAQmx_AO_DAC_Offset_Val                                          &H2255 ' Specifies in volts the value of the DAC offset voltage. To achieve best accuracy, the DAC offset value should be hand calibrated.
$define DAQmx_AO_ReglitchEnable                                          &H0133 ' Specifies whether to enable reglitching.  The output of a DAC normally glitches whenever the DAC is updated with a new value. The amount of glitching differs from code to code and is generally largest at major code transitions.  Reglitching generates uniform glitch energy at each code transition and provides for more uniform glitches.  Uniform glitch energy makes it easier to filter out the noise introduced from g...
$define DAQmx_AO_Gain                                                    &H0118 ' Specifies in decibels the gain factor to apply to the channel.
$define DAQmx_AO_UseOnlyOnBrdMem                                         &H183A ' Specifies whether to write samples directly to the onboard memory of the device, bypassing the memory buffer. Generally, you cannot update onboard memory after you start the task. Onboard memory includes data FIFOs.
$define DAQmx_AO_DataXferMech                                            &H0134 ' Specifies the data transfer mode for the device.
$define DAQmx_AO_DataXferReqCond                                         &H183C ' Specifies under what condition to transfer data from the buffer to the onboard memory of the device.
$define DAQmx_AO_MemMapEnable                                            &H188F ' Specifies if NI-DAQmx maps hardware registers to the memory space of the customer process, if possible. Mapping to the memory space of the customer process increases performance. However, memory mapping can adversely affect the operation of the device and possibly result in a system crash if software in the process unintentionally accesses the mapped registers.
$define DAQmx_AO_DevScalingCoeff                                         &H1931 ' Indicates the coefficients of a linear equation that NI-DAQmx uses to scale values from a voltage to the native format of the device.  Each element of the array corresponds to a term of the equation. For example, if index two of the array is 4, the third term of the equation is 4x^2.  Scaling coefficients do not account for any custom scales that may be applied to the channel.
$define DAQmx_AO_EnhancedImageRejectionEnable                            &H2241 ' Specifies whether to enable the DAC interpolation filter. Disable the interpolation filter to improve DAC signal-to-noise ratio at the expense of degraded image rejection.
$define DAQmx_DI_InvertLines                                             &H0793 ' Specifies whether to invert the lines in the channel. If you set this property to TRUE, the lines are at high logic when off and at low logic when on.
$define DAQmx_DI_NumLines                                                &H2178 ' Indicates the number of digital lines in the channel.
$define DAQmx_DI_DigFltr_Enable                                          &H21D6 ' Specifies whether to enable the digital filter for the line(s) or port(s). You can enable the filter on a line-by-line basis. You do not have to enable the filter for all lines in a channel.
$define DAQmx_DI_DigFltr_MinPulseWidth                                   &H21D7 ' Specifies in seconds the minimum pulse width the filter recognizes as a valid high or low state transition.
$define DAQmx_DI_Tristate                                                &H1890 ' Specifies whether to tristate the lines in the channel. If you set this property to TRUE, NI-DAQmx tristates the lines in the channel. If you set this property to FALSE, NI-DAQmx does not modify the configuration of the lines even if the lines were previously tristated. Set this property to FALSE to read lines in other tasks or to read output-only lines.
$define DAQmx_DI_DataXferMech                                            &H2263 ' Specifies the data transfer mode for the device.
$define DAQmx_DI_DataXferReqCond                                         &H2264 ' Specifies under what condition to transfer data from the onboard memory of the device to the buffer.
$define DAQmx_DO_OutputDriveType                                         &H1137 ' Specifies the drive type for digital output channels.
$define DAQmx_DO_InvertLines                                             &H1133 ' Specifies whether to invert the lines in the channel. If you set this property to TRUE, the lines are at high logic when off and at low logic when on.
$define DAQmx_DO_NumLines                                                &H2179 ' Indicates the number of digital lines in the channel.
$define DAQmx_DO_Tristate                                                &H18F3 ' Specifies whether to stop driving the channel and set it to a high-impedance state. You must commit the task for this setting to take effect.
$define DAQmx_DO_UseOnlyOnBrdMem                                         &H2265 ' Specifies whether to write samples directly to the onboard memory of the device, bypassing the memory buffer. Generally, you cannot update onboard memory after you start the task. Onboard memory includes data FIFOs.
$define DAQmx_DO_DataXferMech                                            &H2266 ' Specifies the data transfer mode for the device.
$define DAQmx_DO_DataXferReqCond                                         &H2267 ' Specifies under what condition to transfer data from the buffer to the onboard memory of the device.
$define DAQmx_CI_Max                                                     &H189C ' Specifies the maximum value you expect to measure. This value is in the units you specify with a units property. When you query this property, it returns the coerced maximum value that the hardware can measure with the current settings.
$define DAQmx_CI_Min                                                     &H189D ' Specifies the minimum value you expect to measure. This value is in the units you specify with a units property. When you query this property, it returns the coerced minimum value that the hardware can measure with the current settings.
$define DAQmx_CI_CustomScaleName                                         &H189E ' Specifies the name of a custom scale for the channel.
$define DAQmx_CI_MeasType                                                &H18A0 ' Indicates the measurement to take with the channel.
$define DAQmx_CI_Freq_Units                                              &H18A1 ' Specifies the units to use to return frequency measurements.
$define DAQmx_CI_Freq_Term                                               &H18A2 ' Specifies the input terminal of the signal to measure.
$define DAQmx_CI_Freq_StartingEdge                                       &H0799 ' Specifies between which edges to measure the frequency of the signal.
$define DAQmx_CI_Freq_MeasMeth                                           &H0144 ' Specifies the method to use to measure the frequency of the signal.
$define DAQmx_CI_Freq_MeasTime                                           &H0145 ' Specifies in seconds the length of time to measure the frequency of the signal if Method is DAQmx_Val_HighFreq2Ctr. Measurement accuracy increases with increased measurement time and with increased signal frequency. If you measure a high-frequency signal for too long, however, the count register could roll over, which results in an incorrect measurement.
$define DAQmx_CI_Freq_Div                                                &H0147 ' Specifies the value by which to divide the input signal if  Method is DAQmx_Val_LargeRng2Ctr. The larger the divisor, the more accurate the measurement. However, too large a value could cause the count register to roll over, which results in an incorrect measurement.
$define DAQmx_CI_Freq_DigFltr_Enable                                     &H21E7 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_Freq_DigFltr_MinPulseWidth                              &H21E8 ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_Freq_DigFltr_TimebaseSrc                                &H21E9 ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_Freq_DigFltr_TimebaseRate                               &H21EA ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_Freq_DigSync_Enable                                     &H21EB ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_Period_Units                                            &H18A3 ' Specifies the unit to use to return period measurements.
$define DAQmx_CI_Period_Term                                             &H18A4 ' Specifies the input terminal of the signal to measure.
$define DAQmx_CI_Period_StartingEdge                                     &H0852 ' Specifies between which edges to measure the period of the signal.
$define DAQmx_CI_Period_MeasMeth                                         &H192C ' Specifies the method to use to measure the period of the signal.
$define DAQmx_CI_Period_MeasTime                                         &H192D ' Specifies in seconds the length of time to measure the period of the signal if Method is DAQmx_Val_HighFreq2Ctr. Measurement accuracy increases with increased measurement time and with increased signal frequency. If you measure a high-frequency signal for too long, however, the count register could roll over, which results in an incorrect measurement.
$define DAQmx_CI_Period_Div                                              &H192E ' Specifies the value by which to divide the input signal if Method is DAQmx_Val_LargeRng2Ctr. The larger the divisor, the more accurate the measurement. However, too large a value could cause the count register to roll over, which results in an incorrect measurement.
$define DAQmx_CI_Period_DigFltr_Enable                                   &H21EC ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_Period_DigFltr_MinPulseWidth                            &H21ED ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_Period_DigFltr_TimebaseSrc                              &H21EE ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_Period_DigFltr_TimebaseRate                             &H21EF ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_Period_DigSync_Enable                                   &H21F0 ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_CountEdges_Term                                         &H18C7 ' Specifies the input terminal of the signal to measure.
$define DAQmx_CI_CountEdges_Dir                                          &H0696 ' Specifies whether to increment or decrement the counter on each edge.
$define DAQmx_CI_CountEdges_DirTerm                                      &H21E1 ' Specifies the source terminal of the digital signal that controls the count direction if Direction is DAQmx_Val_ExtControlled.
$define DAQmx_CI_CountEdges_CountDir_DigFltr_Enable                      &H21F1 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_CountEdges_CountDir_DigFltr_MinPulseWidth               &H21F2 ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_CountEdges_CountDir_DigFltr_TimebaseSrc                 &H21F3 ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_CountEdges_CountDir_DigFltr_TimebaseRate                &H21F4 ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_CountEdges_CountDir_DigSync_Enable                      &H21F5 ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_CountEdges_InitialCnt                                   &H0698 ' Specifies the starting value from which to count.
$define DAQmx_CI_CountEdges_ActiveEdge                                   &H0697 ' Specifies on which edges to increment or decrement the counter.
$define DAQmx_CI_CountEdges_DigFltr_Enable                               &H21F6 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_CountEdges_DigFltr_MinPulseWidth                        &H21F7 ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_CountEdges_DigFltr_TimebaseSrc                          &H21F8 ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_CountEdges_DigFltr_TimebaseRate                         &H21F9 ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_CountEdges_DigSync_Enable                               &H21FA ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_AngEncoder_Units                                        &H18A6 ' Specifies the units to use to return angular position measurements from the channel.
$define DAQmx_CI_AngEncoder_PulsesPerRev                                 &H0875 ' Specifies the number of pulses the encoder generates per revolution. This value is the number of pulses on either signal A or signal B, not the total number of pulses on both signal A and signal B.
$define DAQmx_CI_AngEncoder_InitialAngle                                 &H0881 ' Specifies the starting angle of the encoder. This value is in the units you specify with Units.
$define DAQmx_CI_LinEncoder_Units                                        &H18A9 ' Specifies the units to use to return linear encoder measurements from the channel.
$define DAQmx_CI_LinEncoder_DistPerPulse                                 &H0911 ' Specifies the distance to measure for each pulse the encoder generates on signal A or signal B. This value is in the units you specify with Units.
$define DAQmx_CI_LinEncoder_InitialPos                                   &H0915 ' Specifies the position of the encoder when the measurement begins. This value is in the units you specify with Units.
$define DAQmx_CI_Encoder_DecodingType                                    &H21E6 ' Specifies how to count and interpret the pulses the encoder generates on signal A and signal B. DAQmx_Val_X1, DAQmx_Val_X2, and DAQmx_Val_X4 are valid for quadrature encoders only. DAQmx_Val_TwoPulseCounting is valid for two-pulse encoders only.
$define DAQmx_CI_Encoder_AInputTerm                                      &H219D ' Specifies the terminal to which signal A is connected.
$define DAQmx_CI_Encoder_AInput_DigFltr_Enable                           &H21FB ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_Encoder_AInput_DigFltr_MinPulseWidth                    &H21FC ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_Encoder_AInput_DigFltr_TimebaseSrc                      &H21FD ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_Encoder_AInput_DigFltr_TimebaseRate                     &H21FE ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_Encoder_AInput_DigSync_Enable                           &H21FF ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_Encoder_BInputTerm                                      &H219E ' Specifies the terminal to which signal B is connected.
$define DAQmx_CI_Encoder_BInput_DigFltr_Enable                           &H2200 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_Encoder_BInput_DigFltr_MinPulseWidth                    &H2201 ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_Encoder_BInput_DigFltr_TimebaseSrc                      &H2202 ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_Encoder_BInput_DigFltr_TimebaseRate                     &H2203 ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_Encoder_BInput_DigSync_Enable                           &H2204 ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_Encoder_ZInputTerm                                      &H219F ' Specifies the terminal to which signal Z is connected.
$define DAQmx_CI_Encoder_ZInput_DigFltr_Enable                           &H2205 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_Encoder_ZInput_DigFltr_MinPulseWidth                    &H2206 ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_Encoder_ZInput_DigFltr_TimebaseSrc                      &H2207 ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_Encoder_ZInput_DigFltr_TimebaseRate                     &H2208 ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_Encoder_ZInput_DigSync_Enable                           &H2209 ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_Encoder_ZIndexEnable                                    &H0890 ' Specifies whether to use Z indexing for the channel.
$define DAQmx_CI_Encoder_ZIndexVal                                       &H0888 ' Specifies the value to which to reset the measurement when signal Z is high and signal A and signal B are at the states you specify with Z Index Phase. Specify this value in the units of the measurement.
$define DAQmx_CI_Encoder_ZIndexPhase                                     &H0889 ' Specifies the states at which signal A and signal B must be while signal Z is high for NI-DAQmx to reset the measurement. If signal Z is never high while signal A and signal B are high, for example, you must choose a phase other than DAQmx_Val_AHighBHigh.
$define DAQmx_CI_PulseWidth_Units                                        &H0823 ' Specifies the units to use to return pulse width measurements.
$define DAQmx_CI_PulseWidth_Term                                         &H18AA ' Specifies the input terminal of the signal to measure.
$define DAQmx_CI_PulseWidth_StartingEdge                                 &H0825 ' Specifies on which edge of the input signal to begin each pulse width measurement.
$define DAQmx_CI_PulseWidth_DigFltr_Enable                               &H220A ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_PulseWidth_DigFltr_MinPulseWidth                        &H220B ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_PulseWidth_DigFltr_TimebaseSrc                          &H220C ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_PulseWidth_DigFltr_TimebaseRate                         &H220D ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_PulseWidth_DigSync_Enable                               &H220E ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_TwoEdgeSep_Units                                        &H18AC ' Specifies the units to use to return two-edge separation measurements from the channel.
$define DAQmx_CI_TwoEdgeSep_FirstTerm                                    &H18AD ' Specifies the source terminal of the digital signal that starts each measurement.
$define DAQmx_CI_TwoEdgeSep_FirstEdge                                    &H0833 ' Specifies on which edge of the first signal to start each measurement.
$define DAQmx_CI_TwoEdgeSep_First_DigFltr_Enable                         &H220F ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_TwoEdgeSep_First_DigFltr_MinPulseWidth                  &H2210 ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_TwoEdgeSep_First_DigFltr_TimebaseSrc                    &H2211 ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_TwoEdgeSep_First_DigFltr_TimebaseRate                   &H2212 ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_TwoEdgeSep_First_DigSync_Enable                         &H2213 ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_TwoEdgeSep_SecondTerm                                   &H18AE ' Specifies the source terminal of the digital signal that stops each measurement.
$define DAQmx_CI_TwoEdgeSep_SecondEdge                                   &H0834 ' Specifies on which edge of the second signal to stop each measurement.
$define DAQmx_CI_TwoEdgeSep_Second_DigFltr_Enable                        &H2214 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_TwoEdgeSep_Second_DigFltr_MinPulseWidth                 &H2215 ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_TwoEdgeSep_Second_DigFltr_TimebaseSrc                   &H2216 ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_TwoEdgeSep_Second_DigFltr_TimebaseRate                  &H2217 ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_TwoEdgeSep_Second_DigSync_Enable                        &H2218 ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_SemiPeriod_Units                                        &H18AF ' Specifies the units to use to return semi-period measurements.
$define DAQmx_CI_SemiPeriod_Term                                         &H18B0 ' Specifies the input terminal of the signal to measure.
$define DAQmx_CI_SemiPeriod_StartingEdge                                 &H22FE ' Specifies on which edge of the input signal to begin semi-period measurement. Semi-period measurements alternate between high time and low time, starting on this edge.
$define DAQmx_CI_SemiPeriod_DigFltr_Enable                               &H2219 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_SemiPeriod_DigFltr_MinPulseWidth                        &H221A ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_SemiPeriod_DigFltr_TimebaseSrc                          &H221B ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_SemiPeriod_DigFltr_TimebaseRate                         &H221C ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_SemiPeriod_DigSync_Enable                               &H221D ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_Timestamp_Units                                         &H22B3 ' Specifies the units to use to return timestamp measurements.
$define DAQmx_CI_Timestamp_InitialSeconds                                &H22B4 ' Specifies the number of seconds that elapsed since the beginning of the current year. This value is ignored if  Synchronization Method is DAQmx_Val_IRIGB.
$define DAQmx_CI_GPS_SyncMethod                                          &H1092 ' Specifies the method to use to synchronize the counter to a GPS receiver.
$define DAQmx_CI_GPS_SyncSrc                                             &H1093 ' Specifies the terminal to which the GPS synchronization signal is connected.
$define DAQmx_CI_CtrTimebaseSrc                                          &H0143 ' Specifies the terminal of the timebase to use for the counter.
$define DAQmx_CI_CtrTimebaseRate                                         &H18B2 ' Specifies in Hertz the frequency of the counter timebase. Specifying the rate of a counter timebase allows you to take measurements in terms of time or frequency rather than in ticks of the timebase. If you use an external timebase and do not specify the rate, you can take measurements only in terms of ticks of the timebase.
$define DAQmx_CI_CtrTimebaseActiveEdge                                   &H0142 ' Specifies whether a timebase cycle is from rising edge to rising edge or from falling edge to falling edge.
$define DAQmx_CI_CtrTimebase_DigFltr_Enable                              &H2271 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CI_CtrTimebase_DigFltr_MinPulseWidth                       &H2272 ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CI_CtrTimebase_DigFltr_TimebaseSrc                         &H2273 ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CI_CtrTimebase_DigFltr_TimebaseRate                        &H2274 ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CI_CtrTimebase_DigSync_Enable                              &H2275 ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CI_Count                                                   &H0148 ' Indicates the current value of the count register.
$define DAQmx_CI_OutputState                                             &H0149 ' Indicates the current state of the out terminal of the counter.
$define DAQmx_CI_TCReached                                               &H0150 ' Indicates whether the counter rolled over. When you query this property, NI-DAQmx resets it to FALSE.
$define DAQmx_CI_CtrTimebaseMasterTimebaseDiv                            &H18B3 ' Specifies the divisor for an external counter timebase. You can divide the counter timebase in order to measure slower signals without causing the count register to roll over.
$define DAQmx_CI_DataXferMech                                            &H0200 ' Specifies the data transfer mode for the channel.
$define DAQmx_CI_NumPossiblyInvalidSamps                                 &H193C ' Indicates the number of samples that the device might have overwritten before it could transfer them to the buffer.
$define DAQmx_CI_DupCountPrevent                                         &H21AC ' Specifies whether to enable duplicate count prevention for the channel.
$define DAQmx_CI_Prescaler                                               &H2239 ' Specifies the divisor to apply to the signal you connect to the counter source terminal. Scaled data that you read takes this setting into account. You should use a prescaler only when you connect an external signal to the counter source terminal and when that signal has a higher frequency than the fastest onboard timebase.
$define DAQmx_CO_OutputType                                              &H18B5 ' Indicates how to define pulses generated on the channel.
$define DAQmx_CO_Pulse_IdleState                                         &H1170 ' Specifies the resting state of the output terminal.
$define DAQmx_CO_Pulse_Term                                              &H18E1 ' Specifies on which terminal to generate pulses.
$define DAQmx_CO_Pulse_Time_Units                                        &H18D6 ' Specifies the units in which to define high and low pulse time.
$define DAQmx_CO_Pulse_HighTime                                          &H18BA ' Specifies the amount of time that the pulse is at a high voltage. This value is in the units you specify with Units or when you create the channel.
$define DAQmx_CO_Pulse_LowTime                                           &H18BB ' Specifies the amount of time that the pulse is at a low voltage. This value is in the units you specify with Units or when you create the channel.
$define DAQmx_CO_Pulse_Time_InitialDelay                                 &H18BC ' Specifies in seconds the amount of time to wait before generating the first pulse.
$define DAQmx_CO_Pulse_DutyCyc                                           &H1176 ' Specifies the duty cycle of the pulses. The duty cycle of a signal is the width of the pulse divided by period. NI-DAQmx uses this ratio and the pulse frequency to determine the width of the pulses and the delay between pulses.
$define DAQmx_CO_Pulse_Freq_Units                                        &H18D5 ' Specifies the units in which to define pulse frequency.
$define DAQmx_CO_Pulse_Freq                                              &H1178 ' Specifies the frequency of the pulses to generate. This value is in the units you specify with Units or when you create the channel.
$define DAQmx_CO_Pulse_Freq_InitialDelay                                 &H0299 ' Specifies in seconds the amount of time to wait before generating the first pulse.
$define DAQmx_CO_Pulse_HighTicks                                         &H1169 ' Specifies the number of ticks the pulse is high.
$define DAQmx_CO_Pulse_LowTicks                                          &H1171 ' Specifies the number of ticks the pulse is low.
$define DAQmx_CO_Pulse_Ticks_InitialDelay                                &H0298 ' Specifies the number of ticks to wait before generating the first pulse.
$define DAQmx_CO_CtrTimebaseSrc                                          &H0339 ' Specifies the terminal of the timebase to use for the counter. Typically, NI-DAQmx uses one of the internal counter timebases when generating pulses. Use this property to specify an external timebase and produce custom pulse widths that are not possible using the internal timebases.
$define DAQmx_CO_CtrTimebaseRate                                         &H18C2 ' Specifies in Hertz the frequency of the counter timebase. Specifying the rate of a counter timebase allows you to define output pulses in seconds rather than in ticks of the timebase. If you use an external timebase and do not specify the rate, you can define output pulses only in ticks of the timebase.
$define DAQmx_CO_CtrTimebaseActiveEdge                                   &H0341 ' Specifies whether a timebase cycle is from rising edge to rising edge or from falling edge to falling edge.
$define DAQmx_CO_CtrTimebase_DigFltr_Enable                              &H2276 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_CO_CtrTimebase_DigFltr_MinPulseWidth                       &H2277 ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_CO_CtrTimebase_DigFltr_TimebaseSrc                         &H2278 ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_CO_CtrTimebase_DigFltr_TimebaseRate                        &H2279 ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_CO_CtrTimebase_DigSync_Enable                              &H227A ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_CO_Count                                                   &H0293 ' Indicates the current value of the count register.
$define DAQmx_CO_OutputState                                             &H0294 ' Indicates the current state of the output terminal of the counter.
$define DAQmx_CO_AutoIncrCnt                                             &H0295 ' Specifies a number of timebase ticks by which to increment each successive pulse.
$define DAQmx_CO_CtrTimebaseMasterTimebaseDiv                            &H18C3 ' Specifies the divisor for an external counter timebase. You can divide the counter timebase in order to generate slower signals without causing the count register to roll over.
$define DAQmx_CO_PulseDone                                               &H190E ' Indicates if the task completed pulse generation. Use this value for retriggerable pulse generation when you need to determine if the device generated the current pulse. When you query this property, NI-DAQmx resets it to FALSE.
$define DAQmx_CO_Prescaler                                               &H226D ' Specifies the divisor to apply to the signal you connect to the counter source terminal. Pulse generations defined by frequency or time take this setting into account, but pulse generations defined by ticks do not. You should use a prescaler only when you connect an external signal to the counter source terminal and when that signal has a higher frequency than the fastest onboard timebase.
$define DAQmx_CO_RdyForNewVal                                            &H22FF ' Indicates whether the counter is ready for new continuous pulse train values.
$define DAQmx_ChanType                                                   &H187F ' Indicates the type of the virtual channel.
$define DAQmx_PhysicalChanName                                           &H18F5 ' Indicates the name of the physical channel upon which this virtual channel is based.
$define DAQmx_ChanDescr                                                  &H1926 ' Specifies a user-defined description for the channel.
$define DAQmx_ChanIsGlobal                                               &H2304 ' Indicates whether the channel is a global channel.

'********** Export Signal Attributes **********
$define DAQmx_Exported_AIConvClk_OutputTerm                              &H1687 ' Specifies the terminal to which to route the AI Convert Clock.
$define DAQmx_Exported_AIConvClk_Pulse_Polarity                          &H1688 ' Indicates the polarity of the exported AI Convert Clock. The polarity is fixed and independent of the active edge of the source of the AI Convert Clock.
$define DAQmx_Exported_10MHzRefClk_OutputTerm                            &H226E ' Specifies the terminal to which to route the 10MHz Clock.
$define DAQmx_Exported_20MHzTimebase_OutputTerm                          &H1657 ' Specifies the terminal to which to route the 20MHz Timebase.
$define DAQmx_Exported_SampClk_OutputBehavior                            &H186B ' Specifies whether the exported Sample Clock issues a pulse at the beginning of a sample or changes to a high state for the duration of the sample.
$define DAQmx_Exported_SampClk_OutputTerm                                &H1663 ' Specifies the terminal to which to route the Sample Clock.
$define DAQmx_Exported_SampClk_Pulse_Polarity                            &H1664 ' Specifies the polarity of the exported Sample Clock if Output Behavior is DAQmx_Val_Pulse.
$define DAQmx_Exported_SampClkTimebase_OutputTerm                        &H18F9 ' Specifies the terminal to which to route the Sample Clock Timebase.
$define DAQmx_Exported_DividedSampClkTimebase_OutputTerm                 &H21A1 ' Specifies the terminal to which to route the Divided Sample Clock Timebase.
$define DAQmx_Exported_AdvTrig_OutputTerm                                &H1645 ' Specifies the terminal to which to route the Advance Trigger.
$define DAQmx_Exported_AdvTrig_Pulse_Polarity                            &H1646 ' Indicates the polarity of the exported Advance Trigger.
$define DAQmx_Exported_AdvTrig_Pulse_WidthUnits                          &H1647 ' Specifies the units of Width Value.
$define DAQmx_Exported_AdvTrig_Pulse_Width                               &H1648 ' Specifies the width of an exported Advance Trigger pulse. Specify this value in the units you specify with Width Units.
$define DAQmx_Exported_RefTrig_OutputTerm                                &H0590 ' Specifies the terminal to which to route the Reference Trigger.
$define DAQmx_Exported_StartTrig_OutputTerm                              &H0584 ' Specifies the terminal to which to route the Start Trigger.
$define DAQmx_Exported_AdvCmpltEvent_OutputTerm                          &H1651 ' Specifies the terminal to which to route the Advance Complete Event.
$define DAQmx_Exported_AdvCmpltEvent_Delay                               &H1757 ' Specifies the output signal delay in periods of the sample clock.
$define DAQmx_Exported_AdvCmpltEvent_Pulse_Polarity                      &H1652 ' Specifies the polarity of the exported Advance Complete Event.
$define DAQmx_Exported_AdvCmpltEvent_Pulse_Width                         &H1654 ' Specifies the width of the exported Advance Complete Event pulse.
$define DAQmx_Exported_AIHoldCmpltEvent_OutputTerm                       &H18ED ' Specifies the terminal to which to route the AI Hold Complete Event.
$define DAQmx_Exported_AIHoldCmpltEvent_PulsePolarity                    &H18EE ' Specifies the polarity of an exported AI Hold Complete Event pulse.
$define DAQmx_Exported_ChangeDetectEvent_OutputTerm                      &H2197 ' Specifies the terminal to which to route the Change Detection Event.
$define DAQmx_Exported_ChangeDetectEvent_Pulse_Polarity                  &H2303 ' Specifies the polarity of an exported Change Detection Event pulse.
$define DAQmx_Exported_CtrOutEvent_OutputTerm                            &H1717 ' Specifies the terminal to which to route the Counter Output Event.
$define DAQmx_Exported_CtrOutEvent_OutputBehavior                        &H174F ' Specifies whether the exported Counter Output Event pulses or changes from one state to the other when the counter reaches terminal count.
$define DAQmx_Exported_CtrOutEvent_Pulse_Polarity                        &H1718 ' Specifies the polarity of the pulses at the output terminal of the counter when Output Behavior is DAQmx_Val_Pulse. NI-DAQmx ignores this property if Output Behavior is DAQmx_Val_Toggle.
$define DAQmx_Exported_CtrOutEvent_Toggle_IdleState                      &H186A ' Specifies the initial state of the output terminal of the counter when Output Behavior is DAQmx_Val_Toggle. The terminal enters this state when NI-DAQmx commits the task.
$define DAQmx_Exported_HshkEvent_OutputTerm                              &H22BA ' Specifies the terminal to which to route the Handshake Event.
$define DAQmx_Exported_HshkEvent_OutputBehavior                          &H22BB ' Specifies the output behavior of the Handshake Event.
$define DAQmx_Exported_HshkEvent_Delay                                   &H22BC ' Specifies the number of seconds to delay after the Handshake Trigger deasserts before asserting the Handshake Event.
$define DAQmx_Exported_HshkEvent_Interlocked_AssertedLvl                 &H22BD ' Specifies the asserted level of the exported Handshake Event if Output Behavior is DAQmx_Val_Interlocked.
$define DAQmx_Exported_HshkEvent_Interlocked_AssertOnStart               &H22BE ' Specifies to assert the Handshake Event when the task starts if Output Behavior is DAQmx_Val_Interlocked.
$define DAQmx_Exported_HshkEvent_Interlocked_DeassertDelay               &H22BF ' Specifies in seconds the amount of time to wait after the Handshake Trigger asserts before deasserting the Handshake Event if Output Behavior is DAQmx_Val_Interlocked.
$define DAQmx_Exported_HshkEvent_Pulse_Polarity                          &H22C0 ' Specifies the polarity of the exported Handshake Event if Output Behavior is DAQmx_Val_Pulse.
$define DAQmx_Exported_HshkEvent_Pulse_Width                             &H22C1 ' Specifies in seconds the pulse width of the exported Handshake Event if Output Behavior is DAQmx_Val_Pulse.
$define DAQmx_Exported_RdyForXferEvent_OutputTerm                        &H22B5 ' Specifies the terminal to which to route the Ready for Transfer Event.
$define DAQmx_Exported_RdyForXferEvent_Lvl_ActiveLvl                     &H22B6 ' Specifies the polarity of the exported Ready for Transfer Event.
$define DAQmx_Exported_SyncPulseEvent_OutputTerm                         &H223C ' Specifies the terminal to which to route the Synchronization Pulse Event.
$define DAQmx_Exported_WatchdogExpiredEvent_OutputTerm                   &H21AA ' Specifies the terminal  to which to route the Watchdog Timer Expired Event.

'********** Device Attributes **********
$define DAQmx_Dev_IsSimulated                                            &H22CA ' Indicates if the device is a simulated device.
$define DAQmx_Dev_ProductType                                            &H0631 ' Indicates the product name of the device.
$define DAQmx_Dev_ProductNum                                             &H231D ' Indicates the unique hardware identification number for the device.
$define DAQmx_Dev_SerialNum                                              &H0632 ' Indicates the serial number of the device. This value is zero if the device does not have a serial number.
$define DAQmx_Dev_AI_PhysicalChans                                       &H231E ' Indicates an array containing the names of the analog input physical channels available on the device.
$define DAQmx_Dev_AO_PhysicalChans                                       &H231F ' Indicates an array containing the names of the analog output physical channels available on the device.
$define DAQmx_Dev_DI_Lines                                               &H2320 ' Indicates an array containing the names of the digital input lines available on the device.
$define DAQmx_Dev_DI_Ports                                               &H2321 ' Indicates an array containing the names of the digital input ports available on the device.
$define DAQmx_Dev_DO_Lines                                               &H2322 ' Indicates an array containing the names of the digital output lines available on the device.
$define DAQmx_Dev_DO_Ports                                               &H2323 ' Indicates an array containing the names of the digital output ports available on the device.
$define DAQmx_Dev_CI_PhysicalChans                                       &H2324 ' Indicates an array containing the names of the counter input physical channels available on the device.
$define DAQmx_Dev_CO_PhysicalChans                                       &H2325 ' Indicates an array containing the names of the counter output physical channels available on the device.
$define DAQmx_Dev_BusType                                                &H2326 ' Indicates the bus type of the device.
$define DAQmx_Dev_PCI_BusNum                                             &H2327 ' Indicates the PCI bus number of the device.
$define DAQmx_Dev_PCI_DevNum                                             &H2328 ' Indicates the PCI slot number of the device.
$define DAQmx_Dev_PXI_ChassisNum                                         &H2329 ' Indicates the PXI chassis number of the device, as identified in MAX.
$define DAQmx_Dev_PXI_SlotNum                                            &H232A ' Indicates the PXI slot number of the device.

'********** Read Attributes **********
$define DAQmx_Read_RelativeTo                                            &H190A ' Specifies the point in the buffer at which to begin a read operation. If you also specify an offset with Offset, the read operation begins at that offset relative to the point you select with this property. The default value is DAQmx_Val_CurrReadPos unless you configure a Reference Trigger for the task. If you configure a Reference Trigger, the default value is DAQmx_Val_FirstPretrigSamp.
$define DAQmx_Read_Offset                                                &H190B ' Specifies an offset in samples per channel at which to begin a read operation. This offset is relative to the location you specify with RelativeTo.
$define DAQmx_Read_ChannelsToRead                                        &H1823 ' Specifies a subset of channels in the task from which to read.
$define DAQmx_Read_ReadAllAvailSamp                                      &H1215 ' Specifies whether subsequent read operations read all samples currently available in the buffer or wait for the buffer to become full before reading. NI-DAQmx uses this setting for finite acquisitions and only when the number of samples to read is -1. For continuous acquisitions when the number of samples to read is -1, a read operation always reads all samples currently available in the buffer.
$define DAQmx_Read_AutoStart                                             &H1826 ' Specifies if an NI-DAQmx Read function automatically starts the task  if you did not start the task explicitly by using DAQmxStartTask(). The default value is TRUE. When  an NI-DAQmx Read function starts a finite acquisition task, it also stops the task after reading the last sample.
$define DAQmx_Read_OverWrite                                             &H1211 ' Specifies whether to overwrite samples in the buffer that you have not yet read.
$define DAQmx_Read_CurrReadPos                                           &H1221 ' Indicates in samples per channel the current position in the buffer.
$define DAQmx_Read_AvailSampPerChan                                      &H1223 ' Indicates the number of samples available to read per channel. This value is the same for all channels in the task.
$define DAQmx_Read_TotalSampPerChanAcquired                              &H192A ' Indicates the total number of samples acquired by each channel. NI-DAQmx returns a single value because this value is the same for all channels.
$define DAQmx_Read_OverloadedChansExist                                  &H2174 ' Indicates if the device detected an overload in any channel in the task. Reading this property clears the overload status for all channels in the task. You must read this property before you read Overloaded Channels. Otherwise, you will receive an error.
$define DAQmx_Read_OverloadedChans                                       &H2175 ' Indicates the names of any overloaded virtual channels in the task. You must read Overloaded Channels Exist before you read this property. Otherwise, you will receive an error.
$define DAQmx_Read_ChangeDetect_HasOverflowed                            &H2194 ' Indicates if samples were missed because change detection events occurred faster than the device could handle them. Some devices detect overflows differently than others.
$define DAQmx_Read_RawDataWidth                                          &H217A ' Indicates in bytes the size of a raw sample from the task.
$define DAQmx_Read_NumChans                                              &H217B ' Indicates the number of channels that an NI-DAQmx Read function reads from the task. This value is the number of channels in the task or the number of channels you specify with Channels to Read.
$define DAQmx_Read_DigitalLines_BytesPerChan                             &H217C ' Indicates the number of bytes per channel that NI-DAQmx returns in a sample for line-based reads. If a channel has fewer lines than this number, the extra bytes are FALSE.
$define DAQmx_Read_WaitMode                                              &H2232 ' Specifies how an NI-DAQmx Read function waits for samples to become available.
$define DAQmx_Read_SleepTime                                             &H22B0 ' Specifies in seconds the amount of time to sleep after checking for available samples if Wait Mode is DAQmx_Val_Sleep.

'********** Real-Time Attributes **********
$define DAQmx_RealTime_ConvLateErrorsToWarnings                          &H22EE ' Specifies if DAQmxWaitForNextSampleClock() and an NI-DAQmx Read function convert late errors to warnings. NI-DAQmx returns no late warnings or errors until the number of warmup iterations you specify with Number Of Warmup Iterations execute.
$define DAQmx_RealTime_NumOfWarmupIters                                  &H22ED ' Specifies the number of loop iterations that must occur before DAQmxWaitForNextSampleClock() and an NI-DAQmx Read function return any late warnings or errors. The system needs a number of iterations to stabilize. During this period, a large amount of jitter occurs, potentially causing reads and writes to be late. The default number of warmup iterations is 100. Specify a larger number if needed to stabilize the sys...
$define DAQmx_RealTime_WaitForNextSampClkWaitMode                        &H22EF ' Specifies how DAQmxWaitForNextSampleClock() waits for the next Sample Clock pulse.
$define DAQmx_RealTime_ReportMissedSamp                                  &H2319 ' Specifies whether an NI-DAQmx Read function returns late errors or warnings when it detects missed Sample Clock pulses. This setting does not affect DAQmxWaitForNextSampleClock(). Set this property to TRUE for applications that need to detect lateness without using DAQmxWaitForNextSampleClock().
$define DAQmx_RealTime_WriteRecoveryMode                                 &H231A ' Specifies how NI-DAQmx attempts to recover after missing a Sample Clock pulse when performing counter writes.

'********** Switch Channel Attributes **********
$define DAQmx_SwitchChan_Usage                                           &H18E4 ' Specifies how you can use the channel. Using this property acts as a safety mechanism to prevent you from connecting two source channels, for example.
$define DAQmx_SwitchChan_MaxACCarryCurrent                               &H0648 ' Indicates in amperes the maximum AC current that the device can carry.
$define DAQmx_SwitchChan_MaxACSwitchCurrent                              &H0646 ' Indicates in amperes the maximum AC current that the device can switch. This current is always against an RMS voltage level.
$define DAQmx_SwitchChan_MaxACCarryPwr                                   &H0642 ' Indicates in watts the maximum AC power that the device can carry.
$define DAQmx_SwitchChan_MaxACSwitchPwr                                  &H0644 ' Indicates in watts the maximum AC power that the device can switch.
$define DAQmx_SwitchChan_MaxDCCarryCurrent                               &H0647 ' Indicates in amperes the maximum DC current that the device can carry.
$define DAQmx_SwitchChan_MaxDCSwitchCurrent                              &H0645 ' Indicates in amperes the maximum DC current that the device can switch. This current is always against a DC voltage level.
$define DAQmx_SwitchChan_MaxDCCarryPwr                                   &H0643 ' Indicates in watts the maximum DC power that the device can carry.
$define DAQmx_SwitchChan_MaxDCSwitchPwr                                  &H0649 ' Indicates in watts the maximum DC power that the device can switch.
$define DAQmx_SwitchChan_MaxACVoltage                                    &H0651 ' Indicates in volts the maximum AC RMS voltage that the device can switch.
$define DAQmx_SwitchChan_MaxDCVoltage                                    &H0650 ' Indicates in volts the maximum DC voltage that the device can switch.
$define DAQmx_SwitchChan_WireMode                                        &H18E5 ' Indicates the number of wires that the channel switches.
$define DAQmx_SwitchChan_Bandwidth                                       &H0640 ' Indicates in Hertz the maximum frequency of a signal that can pass through the switch without significant deterioration.
$define DAQmx_SwitchChan_Impedance                                       &H0641 ' Indicates in ohms the switch impedance. This value is important in the RF domain and should match the impedance of the sources and loads.

'********** Switch Device Attributes **********
$define DAQmx_SwitchDev_SettlingTime                                     &H1244 ' Specifies in seconds the amount of time to wait for the switch to settle (or debounce). NI-DAQmx adds this time to the settling time of the motherboard. Modify this property only if the switch does not settle within the settling time of the motherboard. Refer to device documentation for supported settling times.
$define DAQmx_SwitchDev_AutoConnAnlgBus                                  &H17DA ' Specifies if NI-DAQmx routes multiplexed channels to the analog bus backplane. Only the SCXI-1127 and SCXI-1128 support this property.
$define DAQmx_SwitchDev_PwrDownLatchRelaysAfterSettling                  &H22DB ' Specifies if DAQmxSwitchWaitForSettling() powers down latching relays after waiting for the device to settle.
$define DAQmx_SwitchDev_Settled                                          &H1243 ' Indicates when Settling Time expires.
$define DAQmx_SwitchDev_RelayList                                        &H17DC ' Indicates a comma-delimited list of relay names.
$define DAQmx_SwitchDev_NumRelays                                        &H18E6 ' Indicates the number of relays on the device. This value matches the number of relay names in Relay List.
$define DAQmx_SwitchDev_SwitchChanList                                   &H18E7 ' Indicates a comma-delimited list of channel names for the current topology of the device.
$define DAQmx_SwitchDev_NumSwitchChans                                   &H18E8 ' Indicates the number of switch channels for the current topology of the device. This value matches the number of channel names in Switch Channel List.
$define DAQmx_SwitchDev_NumRows                                          &H18E9 ' Indicates the number of rows on a device in a matrix switch topology. Indicates the number of multiplexed channels on a device in a mux topology.
$define DAQmx_SwitchDev_NumColumns                                       &H18EA ' Indicates the number of columns on a device in a matrix switch topology. This value is always 1 if the device is in a mux topology.
$define DAQmx_SwitchDev_Topology                                         &H193D ' Indicates the current topology of the device. This value is one of the topology options in DAQmxSwitchSetTopologyAndReset().

'********** Switch Scan Attributes **********
$define DAQmx_SwitchScan_BreakMode                                       &H1247 ' Specifies the break mode between each entry in a scan list.
$define DAQmx_SwitchScan_RepeatMode                                      &H1248 ' Specifies if the task advances through the scan list multiple times.
$define DAQmx_SwitchScan_WaitingForAdv                                   &H17D9 ' Indicates if the switch hardware is waiting for an  Advance Trigger. If the hardware is waiting, it completed the previous entry in the scan list.

'********** Scale Attributes **********
$define DAQmx_Scale_Descr                                                &H1226 ' Specifies a description for the scale.
$define DAQmx_Scale_ScaledUnits                                          &H191B ' Specifies the units to use for scaled values. You can use an arbitrary string.
$define DAQmx_Scale_PreScaledUnits                                       &H18F7 ' Specifies the units of the values that you want to scale.
$define DAQmx_Scale_Type                                                 &H1929 ' Indicates the method or equation form that the custom scale uses.
$define DAQmx_Scale_Lin_Slope                                            &H1227 ' Specifies the slope, m, in the equation y=mx+b.
$define DAQmx_Scale_Lin_YIntercept                                       &H1228 ' Specifies the y-intercept, b, in the equation y=mx+b.
$define DAQmx_Scale_Map_ScaledMax                                        &H1229 ' Specifies the largest value in the range of scaled values. NI-DAQmx maps this value to Pre-Scaled Maximum Value. Reads clip samples that are larger than this value. Writes generate errors for samples that are larger than this value.
$define DAQmx_Scale_Map_PreScaledMax                                     &H1231 ' Specifies the largest value in the range of pre-scaled values. NI-DAQmx maps this value to Scaled Maximum Value.
$define DAQmx_Scale_Map_ScaledMin                                        &H1230 ' Specifies the smallest value in the range of scaled values. NI-DAQmx maps this value to Pre-Scaled Minimum Value. Reads clip samples that are smaller than this value. Writes generate errors for samples that are smaller than this value.
$define DAQmx_Scale_Map_PreScaledMin                                     &H1232 ' Specifies the smallest value in the range of pre-scaled values. NI-DAQmx maps this value to Scaled Minimum Value.
$define DAQmx_Scale_Poly_ForwardCoeff                                    &H1234 ' Specifies an array of coefficients for the polynomial that converts pre-scaled values to scaled values. Each element of the array corresponds to a term of the equation. For example, if index three of the array is 9, the fourth term of the equation is 9x^3.
$define DAQmx_Scale_Poly_ReverseCoeff                                    &H1235 ' Specifies an array of coefficients for the polynomial that converts scaled values to pre-scaled values. Each element of the array corresponds to a term of the equation. For example, if index three of the array is 9, the fourth term of the equation is 9y^3.
$define DAQmx_Scale_Table_ScaledVals                                     &H1236 ' Specifies an array of scaled values. These values map directly to the values in Pre-Scaled Values.
$define DAQmx_Scale_Table_PreScaledVals                                  &H1237 ' Specifies an array of pre-scaled values. These values map directly to the values in Scaled Values.

'********** System Attributes **********
$define DAQmx_Sys_GlobalChans                                            &H1265 ' Indicates an array that contains the names of all global channels saved on the system.
$define DAQmx_Sys_Scales                                                 &H1266 ' Indicates an array that contains the names of all custom scales saved on the system.
$define DAQmx_Sys_Tasks                                                  &H1267 ' Indicates an array that contains the names of all tasks saved on the system.
$define DAQmx_Sys_DevNames                                               &H193B ' Indicates the names of all devices installed in the system.
$define DAQmx_Sys_NIDAQMajorVersion                                      &H1272 ' Indicates the major portion of the installed version of NI-DAQ, such as 7 for version 7.0.
$define DAQmx_Sys_NIDAQMinorVersion                                      &H1923 ' Indicates the minor portion of the installed version of NI-DAQ, such as 0 for version 7.0.

'********** Task Attributes **********
$define DAQmx_Task_Name                                                  &H1276 ' Indicates the name of the task.
$define DAQmx_Task_Channels                                              &H1273 ' Indicates the names of all virtual channels in the task.
$define DAQmx_Task_NumChans                                              &H2181 ' Indicates the number of virtual channels in the task.
$define DAQmx_Task_Devices                                               &H230E ' Indicates an array containing the names of all devices in the task.
$define DAQmx_Task_Complete                                              &H1274 ' Indicates whether the task completed execution.

'********** Timing Attributes **********
$define DAQmx_SampQuant_SampMode                                         &H1300 ' Specifies if a task acquires or generates a finite number of samples or if it continuously acquires or generates samples.
$define DAQmx_SampQuant_SampPerChan                                      &H1310 ' Specifies the number of samples to acquire or generate for each channel if Sample Mode is DAQmx_Val_FiniteSamps. If Sample Mode is DAQmx_Val_ContSamps, NI-DAQmx uses this value to determine the buffer size.
$define DAQmx_SampTimingType                                             &H1347 ' Specifies the type of sample timing to use for the task.
$define DAQmx_SampClk_Rate                                               &H1344 ' Specifies the sampling rate in samples per channel per second. If you use an external source for the Sample Clock, set this input to the maximum expected rate of that clock.
$define DAQmx_SampClk_MaxRate                                            &H22C8 ' Indicates the maximum Sample Clock rate supported by the task, based on other timing settings. For output tasks, the maximum Sample Clock rate is the maximum rate of the DAC. For input tasks, NI-DAQmx calculates the maximum sampling rate differently for multiplexed devices than simultaneous sampling devices.
$define DAQmx_SampClk_Src                                                &H1852 ' Specifies the terminal of the signal to use as the Sample Clock.
$define DAQmx_SampClk_ActiveEdge                                         &H1301 ' Specifies on which edge of a clock pulse sampling takes place. This property is useful primarily when the signal you use as the Sample Clock is not a periodic clock.
$define DAQmx_SampClk_TimebaseDiv                                        &H18EB ' Specifies the number of Sample Clock Timebase pulses needed to produce a single Sample Clock pulse.
$define DAQmx_SampClk_Timebase_Rate                                      &H1303 ' Specifies the rate of the Sample Clock Timebase. Some applications require that you specify a rate when you use any signal other than the onboard Sample Clock Timebase. NI-DAQmx requires this rate to calculate other timing parameters.
$define DAQmx_SampClk_Timebase_Src                                       &H1308 ' Specifies the terminal of the signal to use as the Sample Clock Timebase.
$define DAQmx_SampClk_Timebase_ActiveEdge                                &H18EC ' Specifies on which edge to recognize a Sample Clock Timebase pulse. This property is useful primarily when the signal you use as the Sample Clock Timebase is not a periodic clock.
$define DAQmx_SampClk_Timebase_MasterTimebaseDiv                         &H1305 ' Specifies the number of pulses of the Master Timebase needed to produce a single pulse of the Sample Clock Timebase.
$define DAQmx_SampClk_DigFltr_Enable                                     &H221E ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_SampClk_DigFltr_MinPulseWidth                              &H221F ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_SampClk_DigFltr_TimebaseSrc                                &H2220 ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_SampClk_DigFltr_TimebaseRate                               &H2221 ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_SampClk_DigSync_Enable                                     &H2222 ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_Hshk_DelayAfterXfer                                        &H22C2 ' Specifies the number of seconds to wait after a handshake cycle before starting a new handshake cycle.
$define DAQmx_Hshk_StartCond                                             &H22C3 ' Specifies the point in the handshake cycle that the device is in when the task starts.
$define DAQmx_Hshk_SampleInputDataWhen                                   &H22C4 ' Specifies on which edge of the Handshake Trigger an input task latches the data from the peripheral device.
$define DAQmx_ChangeDetect_DI_RisingEdgePhysicalChans                    &H2195 ' Specifies the names of the digital lines or ports on which to detect rising edges. The lines or ports must be used by virtual channels in the task. You also can specify a string that contains a list or range of digital lines or ports.
$define DAQmx_ChangeDetect_DI_FallingEdgePhysicalChans                   &H2196 ' Specifies the names of the digital lines or ports on which to detect rising edges. The lines or ports must be used by virtual channels in the task. You also can specify a string that contains a list or range of digital lines or ports.
$define DAQmx_OnDemand_SimultaneousAOEnable                              &H21A0 ' Specifies whether to update all channels in the task simultaneously, rather than updating channels independently when you write a sample to that channel.
$define DAQmx_AIConv_Rate                                                &H1848 ' Specifies the rate at which to clock the analog-to-digital converter. This clock is specific to the analog input section of multiplexed devices.
$define DAQmx_AIConv_MaxRate                                             &H22C9 ' Indicates the maximum convert rate supported by the task, given the current devices and channel count.
$define DAQmx_AIConv_Src                                                 &H1502 ' Specifies the terminal of the signal to use as the AI Convert Clock.
$define DAQmx_AIConv_ActiveEdge                                          &H1853 ' Specifies on which edge of the clock pulse an analog-to-digital conversion takes place.
$define DAQmx_AIConv_TimebaseDiv                                         &H1335 ' Specifies the number of AI Convert Clock Timebase pulses needed to produce a single AI Convert Clock pulse.
$define DAQmx_AIConv_Timebase_Src                                        &H1339 ' Specifies the terminal  of the signal to use as the AI Convert Clock Timebase.
$define DAQmx_MasterTimebase_Rate                                        &H1495 ' Specifies the rate of the Master Timebase.
$define DAQmx_MasterTimebase_Src                                         &H1343 ' Specifies the terminal of the signal to use as the Master Timebase. On an E Series device, you can choose only between the onboard 20MHz Timebase or the RTSI7 terminal.
$define DAQmx_RefClk_Rate                                                &H1315 ' Specifies the frequency of the Reference Clock.
$define DAQmx_RefClk_Src                                                 &H1316 ' Specifies the terminal of the signal to use as the Reference Clock.
$define DAQmx_SyncPulse_Src                                              &H223D ' Specifies the terminal of the signal to use as the synchronization pulse. The synchronization pulse resets the clock dividers and the ADCs/DACs on the device.
$define DAQmx_SyncPulse_SyncTime                                         &H223E ' Indicates in seconds the delay required to reset the ADCs/DACs after the device receives the synchronization pulse.
$define DAQmx_SyncPulse_MinDelayToStart                                  &H223F ' Specifies in seconds the amount of time that elapses after the master device issues the synchronization pulse before the task starts.
$define DAQmx_DelayFromSampClk_DelayUnits                                &H1304 ' Specifies the units of Delay.
$define DAQmx_DelayFromSampClk_Delay                                     &H1317 ' Specifies the amount of time to wait after receiving a Sample Clock edge before beginning to acquire the sample. This value is in the units you specify with Delay Units.

'********** Trigger Attributes **********
$define DAQmx_StartTrig_Type                                             &H1393 ' Specifies the type of trigger to use to start a task.
$define DAQmx_DigEdge_StartTrig_Src                                      &H1407 ' Specifies the name of a terminal where there is a digital signal to use as the source of the Start Trigger.
$define DAQmx_DigEdge_StartTrig_Edge                                     &H1404 ' Specifies on which edge of a digital pulse to start acquiring or generating samples.
$define DAQmx_DigEdge_StartTrig_DigFltr_Enable                           &H2223 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_DigEdge_StartTrig_DigFltr_MinPulseWidth                    &H2224 ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_DigEdge_StartTrig_DigFltr_TimebaseSrc                      &H2225 ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_DigEdge_StartTrig_DigFltr_TimebaseRate                     &H2226 ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_DigEdge_StartTrig_DigSync_Enable                           &H2227 ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_DigPattern_StartTrig_Src                                   &H1410 ' Specifies the physical channels to use for pattern matching. The order of the physical channels determines the order of the pattern. If a port is included, the order of the physical channels within the port is in ascending order.
$define DAQmx_DigPattern_StartTrig_Pattern                               &H2186 ' Specifies the digital pattern that must be met for the Start Trigger to occur.
$define DAQmx_DigPattern_StartTrig_When                                  &H1411 ' Specifies whether the Start Trigger occurs when the physical channels specified with Source match or differ from the digital pattern specified with Pattern.
$define DAQmx_AnlgEdge_StartTrig_Src                                     &H1398 ' Specifies the name of a virtual channel or terminal where there is an analog signal to use as the source of the Start Trigger.
$define DAQmx_AnlgEdge_StartTrig_Slope                                   &H1397 ' Specifies on which slope of the trigger signal to start acquiring or generating samples.
$define DAQmx_AnlgEdge_StartTrig_Lvl                                     &H1396 ' Specifies at what threshold in the units of the measurement or generation to start acquiring or generating samples. Use Slope to specify on which slope to trigger on this threshold.
$define DAQmx_AnlgEdge_StartTrig_Hyst                                    &H1395 ' Specifies a hysteresis level in the units of the measurement or generation. If Slope is DAQmx_Val_RisingSlope, the trigger does not deassert until the source signal passes below  Level minus the hysteresis. If Slope is DAQmx_Val_FallingSlope, the trigger does not deassert until the source signal passes above Level plus the hysteresis.
$define DAQmx_AnlgEdge_StartTrig_Coupling                                &H2233 ' Specifies the coupling for the source signal of the trigger if the source is a terminal rather than a virtual channel.
$define DAQmx_AnlgWin_StartTrig_Src                                      &H1400 ' Specifies the name of a virtual channel or terminal where there is an analog signal to use as the source of the Start Trigger.
$define DAQmx_AnlgWin_StartTrig_When                                     &H1401 ' Specifies whether the task starts acquiring or generating samples when the signal enters or leaves the window you specify with Bottom and Top.
$define DAQmx_AnlgWin_StartTrig_Top                                      &H1403 ' Specifies the upper limit of the window. Specify this value in the units of the measurement or generation.
$define DAQmx_AnlgWin_StartTrig_Btm                                      &H1402 ' Specifies the lower limit of the window. Specify this value in the units of the measurement or generation.
$define DAQmx_AnlgWin_StartTrig_Coupling                                 &H2234 ' Specifies the coupling for the source signal of the trigger if the source is a terminal rather than a virtual channel.
$define DAQmx_StartTrig_Delay                                            &H1856 ' Specifies an amount of time to wait after the Start Trigger is received before acquiring or generating the first sample. This value is in the units you specify with Delay Units.
$define DAQmx_StartTrig_DelayUnits                                       &H18C8 ' Specifies the units of Delay.
$define DAQmx_StartTrig_Retriggerable                                    &H190F ' Specifies whether to enable retriggerable counter pulse generation. When you set this property to TRUE, the device generates pulses each time it receives a trigger. The device ignores a trigger if it is in the process of generating pulses.
$define DAQmx_RefTrig_Type                                               &H1419 ' Specifies the type of trigger to use to mark a reference point for the measurement.
$define DAQmx_RefTrig_PretrigSamples                                     &H1445 ' Specifies the minimum number of pretrigger samples to acquire from each channel before recognizing the reference trigger. Post-trigger samples per channel are equal to Samples Per Channel minus the number of pretrigger samples per channel.
$define DAQmx_DigEdge_RefTrig_Src                                        &H1434 ' Specifies the name of a terminal where there is a digital signal to use as the source of the Reference Trigger.
$define DAQmx_DigEdge_RefTrig_Edge                                       &H1430 ' Specifies on what edge of a digital pulse the Reference Trigger occurs.
$define DAQmx_DigPattern_RefTrig_Src                                     &H1437 ' Specifies the physical channels to use for pattern matching. The order of the physical channels determines the order of the pattern. If a port is included, the order of the physical channels within the port is in ascending order.
$define DAQmx_DigPattern_RefTrig_Pattern                                 &H2187 ' Specifies the digital pattern that must be met for the Reference Trigger to occur.
$define DAQmx_DigPattern_RefTrig_When                                    &H1438 ' Specifies whether the Start Trigger occurs when the physical channels specified with Source match or differ from the digital pattern specified with Pattern.
$define DAQmx_AnlgEdge_RefTrig_Src                                       &H1424 ' Specifies the name of a virtual channel or terminal where there is an analog signal to use as the source of the Reference Trigger.
$define DAQmx_AnlgEdge_RefTrig_Slope                                     &H1423 ' Specifies on which slope of the source signal the Reference Trigger occurs.
$define DAQmx_AnlgEdge_RefTrig_Lvl                                       &H1422 ' Specifies in the units of the measurement the threshold at which the Reference Trigger occurs.  Use Slope to specify on which slope to trigger at this threshold.
$define DAQmx_AnlgEdge_RefTrig_Hyst                                      &H1421 ' Specifies a hysteresis level in the units of the measurement. If Slope is DAQmx_Val_RisingSlope, the trigger does not deassert until the source signal passes below Level minus the hysteresis. If Slope is DAQmx_Val_FallingSlope, the trigger does not deassert until the source signal passes above Level plus the hysteresis.
$define DAQmx_AnlgEdge_RefTrig_Coupling                                  &H2235 ' Specifies the coupling for the source signal of the trigger if the source is a terminal rather than a virtual channel.
$define DAQmx_AnlgWin_RefTrig_Src                                        &H1426 ' Specifies the name of a virtual channel or terminal where there is an analog signal to use as the source of the Reference Trigger.
$define DAQmx_AnlgWin_RefTrig_When                                       &H1427 ' Specifies whether the Reference Trigger occurs when the source signal enters the window or when it leaves the window. Use Bottom and Top to specify the window.
$define DAQmx_AnlgWin_RefTrig_Top                                        &H1429 ' Specifies the upper limit of the window. Specify this value in the units of the measurement.
$define DAQmx_AnlgWin_RefTrig_Btm                                        &H1428 ' Specifies the lower limit of the window. Specify this value in the units of the measurement.
$define DAQmx_AnlgWin_RefTrig_Coupling                                   &H1857 ' Specifies the coupling for the source signal of the trigger if the source is a terminal rather than a virtual channel.
$define DAQmx_AdvTrig_Type                                               &H1365 ' Specifies the type of trigger to use to advance to the next entry in a switch scan list.
$define DAQmx_DigEdge_AdvTrig_Src                                        &H1362 ' Specifies the name of a terminal where there is a digital signal to use as the source of the Advance Trigger.
$define DAQmx_DigEdge_AdvTrig_Edge                                       &H1360 ' Specifies on which edge of a digital signal to advance to the next entry in a scan list.
$define DAQmx_DigEdge_AdvTrig_DigFltr_Enable                             &H2238 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_HshkTrig_Type                                              &H22B7 ' Specifies the type of Handshake Trigger to use.
$define DAQmx_Interlocked_HshkTrig_Src                                   &H22B8 ' Specifies the source terminal of the Handshake Trigger.
$define DAQmx_Interlocked_HshkTrig_AssertedLvl                           &H22B9 ' Specifies the asserted level of the Handshake Trigger.
$define DAQmx_PauseTrig_Type                                             &H1366 ' Specifies the type of trigger to use to pause a task.
$define DAQmx_AnlgLvl_PauseTrig_Src                                      &H1370 ' Specifies the name of a virtual channel or terminal where there is an analog signal to use as the source of the trigger.
$define DAQmx_AnlgLvl_PauseTrig_When                                     &H1371 ' Specifies whether the task pauses above or below the threshold you specify with Level.
$define DAQmx_AnlgLvl_PauseTrig_Lvl                                      &H1369 ' Specifies the threshold at which to pause the task. Specify this value in the units of the measurement or generation. Use Pause When to specify whether the task pauses above or below this threshold.
$define DAQmx_AnlgLvl_PauseTrig_Hyst                                     &H1368 ' Specifies a hysteresis level in the units of the measurement or generation. If Pause When is DAQmx_Val_AboveLvl, the trigger does not deassert until the source signal passes below Level minus the hysteresis. If Pause When is DAQmx_Val_BelowLvl, the trigger does not deassert until the source signal passes above Level plus the hysteresis.
$define DAQmx_AnlgLvl_PauseTrig_Coupling                                 &H2236 ' Specifies the coupling for the source signal of the trigger if the source is a terminal rather than a virtual channel.
$define DAQmx_AnlgWin_PauseTrig_Src                                      &H1373 ' Specifies the name of a virtual channel or terminal where there is an analog signal to use as the source of the trigger.
$define DAQmx_AnlgWin_PauseTrig_When                                     &H1374 ' Specifies whether the task pauses while the trigger signal is inside or outside the window you specify with Bottom and Top.
$define DAQmx_AnlgWin_PauseTrig_Top                                      &H1376 ' Specifies the upper limit of the window. Specify this value in the units of the measurement or generation.
$define DAQmx_AnlgWin_PauseTrig_Btm                                      &H1375 ' Specifies the lower limit of the window. Specify this value in the units of the measurement or generation.
$define DAQmx_AnlgWin_PauseTrig_Coupling                                 &H2237 ' Specifies the coupling for the source signal of the trigger if the source is a terminal rather than a virtual channel.
$define DAQmx_DigLvl_PauseTrig_Src                                       &H1379 ' Specifies the name of a terminal where there is a digital signal to use as the source of the Pause Trigger.
$define DAQmx_DigLvl_PauseTrig_When                                      &H1380 ' Specifies whether the task pauses while the signal is high or low.
$define DAQmx_DigLvl_PauseTrig_DigFltr_Enable                            &H2228 ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_DigLvl_PauseTrig_DigFltr_MinPulseWidth                     &H2229 ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_DigLvl_PauseTrig_DigFltr_TimebaseSrc                       &H222A ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_DigLvl_PauseTrig_DigFltr_TimebaseRate                      &H222B ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_DigLvl_PauseTrig_DigSync_Enable                            &H222C ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.
$define DAQmx_ArmStartTrig_Type                                          &H1414 ' Specifies the type of trigger to use to arm the task for a Start Trigger. If you configure an Arm Start Trigger, the task does not respond to a Start Trigger until the device receives the Arm Start Trigger.
$define DAQmx_DigEdge_ArmStartTrig_Src                                   &H1417 ' Specifies the name of a terminal where there is a digital signal to use as the source of the Arm Start Trigger.
$define DAQmx_DigEdge_ArmStartTrig_Edge                                  &H1415 ' Specifies on which edge of a digital signal to arm the task for a Start Trigger.
$define DAQmx_DigEdge_ArmStartTrig_DigFltr_Enable                        &H222D ' Specifies whether to apply the pulse width filter to the signal.
$define DAQmx_DigEdge_ArmStartTrig_DigFltr_MinPulseWidth                 &H222E ' Specifies in seconds the minimum pulse width the filter recognizes.
$define DAQmx_DigEdge_ArmStartTrig_DigFltr_TimebaseSrc                   &H222F ' Specifies the input terminal of the signal to use as the timebase of the pulse width filter.
$define DAQmx_DigEdge_ArmStartTrig_DigFltr_TimebaseRate                  &H2230 ' Specifies in hertz the rate of the pulse width filter timebase. NI-DAQmx uses this value to compute settings for the filter.
$define DAQmx_DigEdge_ArmStartTrig_DigSync_Enable                        &H2231 ' Specifies whether to synchronize recognition of transitions in the signal to the internal timebase of the device.

'********** Watchdog Attributes **********
$define DAQmx_Watchdog_Timeout                                           &H21A9 ' Specifies in seconds the amount of time until the watchdog timer expires. A value of -1 means the internal timer never expires. Set this input to -1 if you use an Expiration Trigger to expire the watchdog task.
$define DAQmx_WatchdogExpirTrig_Type                                     &H21A3 ' Specifies the type of trigger to use to expire a watchdog task.
$define DAQmx_DigEdge_WatchdogExpirTrig_Src                              &H21A4 ' Specifies the name of a terminal where a digital signal exists to use as the source of the Expiration Trigger.
$define DAQmx_DigEdge_WatchdogExpirTrig_Edge                             &H21A5 ' Specifies on which edge of a digital signal to expire the watchdog task.
$define DAQmx_Watchdog_DO_ExpirState                                     &H21A7 ' Specifies the state to which to set the digital physical channels when the watchdog task expires.  You cannot modify the expiration state of dedicated digital input physical channels.
$define DAQmx_Watchdog_HasExpired                                        &H21A8 ' Indicates if the watchdog timer expired. You can read this property only while the task is running.

'********** Write Attributes **********
$define DAQmx_Write_RelativeTo                                           &H190C ' Specifies the point in the buffer at which to write data. If you also specify an offset with Offset, the write operation begins at that offset relative to this point you select with this property.
$define DAQmx_Write_Offset                                               &H190D ' Specifies in samples per channel an offset at which a write operation begins. This offset is relative to the location you specify with Relative To.
$define DAQmx_Write_RegenMode                                            &H1453 ' Specifies whether to allow NI-DAQmx to generate the same data multiple times.
$define DAQmx_Write_CurrWritePos                                         &H1458 ' Indicates the number of the next sample for the device to generate. This value is identical for all channels in the task.
$define DAQmx_Write_SpaceAvail                                           &H1460 ' Indicates in samples per channel the amount of available space in the buffer.
$define DAQmx_Write_TotalSampPerChanGenerated                            &H192B ' Indicates the total number of samples generated by each channel in the task. This value is identical for all channels in the task.
$define DAQmx_Write_RawDataWidth                                         &H217D ' Indicates in bytes the required size of a raw sample to write to the task.
$define DAQmx_Write_NumChans                                             &H217E ' Indicates the number of channels that an NI-DAQmx Write function writes to the task. This value is the number of channels in the task.
$define DAQmx_Write_WaitMode                                             &H22B1 ' Specifies how an NI-DAQmx Write function waits for space to become available in the buffer.
$define DAQmx_Write_SleepTime                                            &H22B2 ' Specifies in seconds the amount of time to sleep after checking for available buffer space if Wait Mode is DAQmx_Val_Sleep.
$define DAQmx_Write_DigitalLines_BytesPerChan                            &H217F ' Indicates the number of bytes expected per channel in a sample for line-based writes. If a channel has fewer lines than this number, NI-DAQmx ignores the extra bytes.

'********** Physical Channel Attributes **********
$define DAQmx_PhysicalChan_TEDS_MfgID                                    &H21DA ' Indicates the manufacturer ID of the sensor.
$define DAQmx_PhysicalChan_TEDS_ModelNum                                 &H21DB ' Indicates the model number of the sensor.
$define DAQmx_PhysicalChan_TEDS_SerialNum                                &H21DC ' Indicates the serial number of the sensor.
$define DAQmx_PhysicalChan_TEDS_VersionNum                               &H21DD ' Indicates the version number of the sensor.
$define DAQmx_PhysicalChan_TEDS_VersionLetter                            &H21DE ' Indicates the version letter of the sensor.
$define DAQmx_PhysicalChan_TEDS_BitStream                                &H21DF ' Indicates the TEDS binary bitstream without checksums.
$define DAQmx_PhysicalChan_TEDS_TemplateIDs                              &H228F ' Indicates the IDs of the templates in the bitstream in BitStream.

'********** Persisted Task Attributes **********
$define DAQmx_PersistedTask_Author                                       &H22CC ' Indicates the author of the task.
$define DAQmx_PersistedTask_AllowInteractiveEditing                      &H22CD ' Indicates whether the task can be edited in the DAQ Assistant.
$define DAQmx_PersistedTask_AllowInteractiveDeletion                     &H22CE ' Indicates whether the task can be deleted through MAX.

'********** Persisted Channel Attributes **********
$define DAQmx_PersistedChan_Author                                       &H22D0 ' Indicates the author of the global channel.
$define DAQmx_PersistedChan_AllowInteractiveEditing                      &H22D1 ' Indicates whether the global channel can be edited in the DAQ Assistant.
$define DAQmx_PersistedChan_AllowInteractiveDeletion                     &H22D2 ' Indicates whether the global channel can be deleted through MAX.

'********** Persisted Scale Attributes **********
$define DAQmx_PersistedScale_Author                                      &H22D4 ' Indicates the author of the custom scale.
$define DAQmx_PersistedScale_AllowInteractiveEditing                     &H22D5 ' Indicates whether the custom scale can be edited in the DAQ Assistant.
$define DAQmx_PersistedScale_AllowInteractiveDeletion                    &H22D6 ' Indicates whether the custom scale can be deleted through MAX.


' For backwards compatibility, the DAQmx_ReadWaitMode has to be defined because this was the original spelling
' that has been later on corrected.
$define DAQmx_ReadWaitMode	DAQmx_Read_WaitMode

'*****************************************************************************
' *** NI-DAQmx Values **********************************************************
' ******************************************************************************/

'*****************************************************/
'**    Non-Attribute Function Parameter Values     ***/
'*****************************************************/

'*** Values for the Mode parameter of DAQmxTaskControl ***
$define DAQmx_Val_Task_Start                                              0   ' Start
$define DAQmx_Val_Task_Stop                                               1   ' Stop
$define DAQmx_Val_Task_Verify                                             2   ' Verify
$define DAQmx_Val_Task_Commit                                             3   ' Commit
$define DAQmx_Val_Task_Reserve                                            4   ' Reserve
$define DAQmx_Val_Task_Unreserve                                          5   ' Unreserve
$define DAQmx_Val_Task_Abort                                              6   ' Abort

'*** Values for the Options parameter of the event registration functions
$define DAQmx_Val_SynchronousEventCallbacks    1 ' (1<<0)     ' Synchronous callbacks

'*** Values for the everyNsamplesEventType parameter of DAQmxRegisterEveryNSamplesEvent ***
$define DAQmx_Val_Acquired_Into_Buffer          1     ' Acquired Into Buffer
$define DAQmx_Val_Transferred_From_Buffer       2     ' Transferred From Buffer


'*** Values for the Action parameter of DAQmxControlWatchdogTask ***
$define DAQmx_Val_ResetTimer                                              0   ' Reset Timer
$define DAQmx_Val_ClearExpiration                                         1   ' Clear Expiration

'*** Values for the Line Grouping parameter of DAQmxCreateDIChan and DAQmxCreateDOChan ***
$define DAQmx_Val_ChanPerLine                                             0   ' One Channel For Each Line
$define DAQmx_Val_ChanForAllLines                                         1   ' One Channel For All Lines

'*** Values for the Fill Mode parameter of DAQmxReadAnalogF64, DAQmxReadBinaryI16, DAQmxReadBinaryU16, DAQmxReadBinaryI32, DAQmxReadBinaryU32,
'    DAQmxReadDigitalU8, DAQmxReadDigitalU32, DAQmxReadDigitalLines ***
'*** Values for the Data Layout parameter of DAQmxWriteAnalogF64, DAQmxWriteBinaryI16, DAQmxWriteDigitalU8, DAQmxWriteDigitalU32, DAQmxWriteDigitalLines ***
$define DAQmx_Val_GroupByChannel                                          0   ' Group by Channel
$define DAQmx_Val_GroupByScanNumber                                       1   ' Group by Scan Number

'*** Values for the Signal Modifiers parameter of DAQmxConnectTerms ***/
$define DAQmx_Val_DoNotInvertPolarity                                     0   ' Do not invert polarity
$define DAQmx_Val_InvertPolarity                                          1   ' Invert polarity

'*** Values for the Action paramter of DAQmxCloseExtCal ***
$define DAQmx_Val_Action_Commit                                           0   ' Commit
$define DAQmx_Val_Action_Cancel                                           1   ' Cancel

'*** Values for the Trigger ID parameter of DAQmxSendSoftwareTrigger ***
$define DAQmx_Val_AdvanceTrigger                                          12488 ' Advance Trigger

'*** Value set for the ActiveEdge parameter of DAQmxCfgSampClkTiming ***
$define DAQmx_Val_Rising                                                  10280 ' Rising
$define DAQmx_Val_Falling                                                 10171 ' Falling

'*** Value set SwitchPathType ***
'*** Value set for the output Path Status parameter of DAQmxSwitchFindPath ***
$define DAQmx_Val_PathStatus_Available                                    10431 ' Path Available
$define DAQmx_Val_PathStatus_AlreadyExists                                10432 ' Path Already Exists
$define DAQmx_Val_PathStatus_Unsupported                                  10433 ' Path Unsupported
$define DAQmx_Val_PathStatus_ChannelInUse                                 10434 ' Channel In Use
$define DAQmx_Val_PathStatus_SourceChannelConflict                        10435 ' Channel Source Conflict
$define DAQmx_Val_PathStatus_ChannelReservedForRouting                    10436 ' Channel Reserved for Routing

'*** Value set for the Units parameter of DAQmxCreateAIThrmcplChan, DAQmxCreateAIRTDChan, DAQmxCreateAIThrmstrChanIex, DAQmxCreateAIThrmstrChanVex and DAQmxCreateAITempBuiltInSensorChan ***
$define DAQmx_Val_DegC                                                    10143 ' Deg C
$define DAQmx_Val_DegF                                                    10144 ' Deg F
$define DAQmx_Val_Kelvins                                                 10325 ' Kelvins
$define DAQmx_Val_DegR                                                    10145 ' Deg R

'*** Value set for the state parameter of DAQmxSetDigitalPowerUpStates ***
$define DAQmx_Val_High                                                    10192 ' High
$define DAQmx_Val_Low                                                     10214 ' Low
$define DAQmx_Val_Tristate                                                10310 ' Tristate

'*** Value set for the channelType parameter of DAQmxSetAnalogPowerUpStates ***
$define DAQmx_Val_ChannelVoltage                                          0     ' Voltage Channel
$define DAQmx_Val_ChannelCurrent                                          1     ' Current Channel

'*** Value set RelayPos ***
'*** Value set for the state parameter of DAQmxSwitchGetSingleRelayPos and DAQmxSwitchGetMultiRelayPos ***
$define DAQmx_Val_Open                                                    10437 ' Open
$define DAQmx_Val_Closed                                                  10438 ' Closed

'*** Value for the Terminal Config parameter of DAQmxCreateAIVoltageChan, DAQmxCreateAICurrentChan and DAQmxCreateAIVoltageChanWithExcit ***
$define DAQmx_Val_Cfg_Default                                             minus_1 ' Default

'*** Value for the Timeout parameter of DAQmxWaitUntilTaskDone
$define DAQmx_Val_WaitInfinitely                                          minus_1

'*** Value for the Number of Samples per Channel parameter of DAQmxReadAnalogF64, DAQmxReadBinaryI16, DAQmxReadBinaryU16,
'    DAQmxReadBinaryI32, DAQmxReadBinaryU32, DAQmxReadDigitalU8, DAQmxReadDigitalU32,
'    DAQmxReadDigitalLines, DAQmxReadCounterF64, DAQmxReadCounterU32 and DAQmxReadRaw ***
$define DAQmx_Val_Auto                                                    minus_1

' Value set for the Options parameter of DAQmxSaveTask, DAQmxSaveGlobalChan and DAQmxSaveScale
$define DAQmx_Val_Save_Overwrite                1 '(1<<0)
$define DAQmx_Val_Save_AllowInteractiveEditing  2 '(1<<1)
$define DAQmx_Val_Save_AllowInteractiveDeletion 4 '(1<<2)


'*****************************************************/
'**              Attribute Values                  ***/
'*****************************************************/

'*** Values for DAQmx_AI_ACExcit_WireMode ***
'*** Value set ACExcitWireMode ***
$define DAQmx_Val_4Wire                                                       4 ' 4-Wire
$define DAQmx_Val_5Wire                                                       5 ' 5-Wire

'*** Values for DAQmx_AI_MeasType ***
'*** Value set AIMeasurementType ***
$define DAQmx_Val_Voltage                                                 10322 ' Voltage
$define DAQmx_Val_Current                                                 10134 ' Current
$define DAQmx_Val_Voltage_CustomWithExcitation                            10323 ' More:Voltage:Custom with Excitation
$define DAQmx_Val_Freq_Voltage                                            10181 ' Frequency
$define DAQmx_Val_Resistance                                              10278 ' Resistance
$define DAQmx_Val_Temp_TC                                                 10303 ' Temperature:Thermocouple
$define DAQmx_Val_Temp_Thrmstr                                            10302 ' Temperature:Thermistor
$define DAQmx_Val_Temp_RTD                                                10301 ' Temperature:RTD
$define DAQmx_Val_Temp_BuiltInSensor                                      10311 ' Temperature:Built-in Sensor
$define DAQmx_Val_Strain_Gage                                             10300 ' Strain Gage
$define DAQmx_Val_Position_LVDT                                           10352 ' Position:LVDT
$define DAQmx_Val_Position_RVDT                                           10353 ' Position:RVDT
$define DAQmx_Val_Accelerometer                                           10356 ' Accelerometer
$define DAQmx_Val_SoundPressure_Microphone                                10354 ' Sound Pressure:Microphone
$define DAQmx_Val_TEDS_Sensor                                             12531 ' TEDS Sensor

'*** Values for DAQmx_AO_IdleOutputBehavior ***
'*** Value set AOIdleOutputBehavior ***
$define DAQmx_Val_ZeroVolts                                               12526 ' Zero Volts
$define DAQmx_Val_HighImpedance                                           12527 ' High Impedance
$define DAQmx_Val_MaintainExistingValue                                   12528 ' Maintain Existing Value

'*** Values for DAQmx_AO_OutputType ***
'*** Value set AOOutputChannelType ***
$define DAQmx_Val_Voltage                                                 10322 ' Voltage
$define DAQmx_Val_Current                                                 10134 ' Current

'*** Values for DAQmx_AI_Accel_SensitivityUnits ***
'*** Value set AccelSensitivityUnits1 ***
$define DAQmx_Val_mVoltsPerG                                              12509 ' mVolts/g
$define DAQmx_Val_VoltsPerG                                               12510 ' Volts/g

'*** Values for DAQmx_AI_Accel_Units ***
'*** Value set AccelUnits2 ***
$define DAQmx_Val_AccelUnit_g                                             10186 ' g
$define DAQmx_Val_MetersPerSecondSquared                                  12470 ' m/s^2
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_SampQuant_SampMode ***
'*** Value set AcquisitionType ***
$define DAQmx_Val_FiniteSamps                                             10178 ' Finite Samples
$define DAQmx_Val_ContSamps                                               10123 ' Continuous Samples
$define DAQmx_Val_HWTimedSinglePoint                                      12522 ' Hardware Timed Single Point

'*** Values for DAQmx_AnlgLvl_PauseTrig_When ***
'*** Value set ActiveLevel ***
$define DAQmx_Val_AboveLvl                                                10093 ' Above Level
$define DAQmx_Val_BelowLvl                                                10107 ' Below Level

'*** Values for DAQmx_AI_RVDT_Units ***
'*** Value set AngleUnits1 ***
$define DAQmx_Val_Degrees                                                 10146 ' Degrees
$define DAQmx_Val_Radians                                                 10273 ' Radians
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_CI_AngEncoder_Units ***
'*** Value set AngleUnits2 ***
$define DAQmx_Val_Degrees                                                 10146 ' Degrees
$define DAQmx_Val_Radians                                                 10273 ' Radians
$define DAQmx_Val_Ticks                                                   10304 ' Ticks
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_AI_AutoZeroMode ***
'*** Value set AutoZeroType1 ***
$define DAQmx_Val_None                                                    10230 ' None
$define DAQmx_Val_Once                                                    10244 ' Once
$define DAQmx_Val_EverySample                                             10164 ' Every Sample

'*** Values for DAQmx_SwitchScan_BreakMode ***
'*** Value set BreakMode ***
$define DAQmx_Val_NoAction                                                10227 ' No Action
$define DAQmx_Val_BreakBeforeMake                                         10110 ' Break Before Make

'*** Values for DAQmx_AI_Bridge_Cfg ***
'*** Value set BridgeConfiguration1 ***
$define DAQmx_Val_FullBridge                                              10182 ' Full Bridge
$define DAQmx_Val_HalfBridge                                              10187 ' Half Bridge
$define DAQmx_Val_QuarterBridge                                           10270 ' Quarter Bridge
$define DAQmx_Val_NoBridge                                                10228 ' No Bridge

'*** Values for DAQmx_Dev_BusType ***
'*** Value set BusType ***
$define DAQmx_Val_PCI                                                     12582 ' PCI
$define DAQmx_Val_PCIe                                                    13612 ' PCIe
$define DAQmx_Val_PXI                                                     12583 ' PXI
$define DAQmx_Val_SCXI                                                    12584 ' SCXI
$define DAQmx_Val_PCCard                                                  12585 ' PCCard
$define DAQmx_Val_USB                                                     12586 ' USB
$define DAQmx_Val_Unknown                                                 12588 ' Unknown

'*** Values for DAQmx_CI_MeasType ***
'*** Value set CIMeasurementType ***
$define DAQmx_Val_CountEdges                                              10125 ' Count Edges
$define DAQmx_Val_Freq                                                    10179 ' Frequency
$define DAQmx_Val_Period                                                  10256 ' Period
$define DAQmx_Val_PulseWidth                                              10359 ' Pulse Width
$define DAQmx_Val_SemiPeriod                                              10289 ' Semi Period
$define DAQmx_Val_Position_AngEncoder                                     10360 ' Position:Angular Encoder
$define DAQmx_Val_Position_LinEncoder                                     10361 ' Position:Linear Encoder
$define DAQmx_Val_TwoEdgeSep                                              10267 ' Two Edge Separation
$define DAQmx_Val_GPS_Timestamp                                           10362 ' GPS Timestamp

'*** Values for DAQmx_AI_Thrmcpl_CJCSrc ***
'*** Value set CJCSource1 ***
$define DAQmx_Val_BuiltIn                                                 10200 ' Built-In
$define DAQmx_Val_ConstVal                                                10116 ' Constant Value
$define DAQmx_Val_Chan                                                    10113 ' Channel

'*** Values for DAQmx_CO_OutputType ***
'*** Value set COOutputType ***
$define DAQmx_Val_Pulse_Time                                              10269 ' Pulse:Time
$define DAQmx_Val_Pulse_Freq                                              10119 ' Pulse:Frequency
$define DAQmx_Val_Pulse_Ticks                                             10268 ' Pulse:Ticks

'*** Values for DAQmx_ChanType ***
'*** Value set ChannelType ***
$define DAQmx_Val_AI                                                      10100 ' Analog Input
$define DAQmx_Val_AO                                                      10102 ' Analog Output
$define DAQmx_Val_DI                                                      10151 ' Digital Input
$define DAQmx_Val_DO                                                      10153 ' Digital Output
$define DAQmx_Val_CI                                                      10131 ' Counter Input
$define DAQmx_Val_CO                                                      10132 ' Counter Output

'*** Values for DAQmx_CI_CountEdges_Dir ***
'*** Value set CountDirection1 ***
$define DAQmx_Val_CountUp                                                 10128 ' Count Up
$define DAQmx_Val_CountDown                                               10124 ' Count Down
$define DAQmx_Val_ExtControlled                                           10326 ' Externally Controlled

'*** Values for DAQmx_CI_Freq_MeasMeth ***
'*** Values for DAQmx_CI_Period_MeasMeth ***
'*** Value set CounterFrequencyMethod ***
$define DAQmx_Val_LowFreq1Ctr                                             10105 ' Low Frequency with 1 Counter
$define DAQmx_Val_HighFreq2Ctr                                            10157 ' High Frequency with 2 Counters
$define DAQmx_Val_LargeRng2Ctr                                            10205 ' Large Range with 2 Counters

'*** Values for DAQmx_AI_Coupling ***
'*** Value set Coupling1 ***
$define DAQmx_Val_AC                                                      10045 ' AC
$define DAQmx_Val_DC                                                      10050 ' DC
$define DAQmx_Val_GND                                                     10066 ' GND

'*** Values for DAQmx_AnlgEdge_StartTrig_Coupling ***
'*** Values for DAQmx_AnlgWin_StartTrig_Coupling ***
'*** Values for DAQmx_AnlgEdge_RefTrig_Coupling ***
'*** Values for DAQmx_AnlgWin_RefTrig_Coupling ***
'*** Values for DAQmx_AnlgLvl_PauseTrig_Coupling ***
'*** Values for DAQmx_AnlgWin_PauseTrig_Coupling ***
'*** Value set Coupling2 ***
$define DAQmx_Val_AC                                                      10045 ' AC
$define DAQmx_Val_DC                                                      10050 ' DC

'*** Values for DAQmx_AI_CurrentShunt_Loc ***
'*** Value set CurrentShuntResistorLocation1 ***
$define DAQmx_Val_Internal                                                10200 ' Internal
$define DAQmx_Val_External                                                10167 ' External

'*** Values for DAQmx_AI_Current_Units ***
'*** Values for DAQmx_AO_Current_Units ***
'*** Value set CurrentUnits1 ***
$define DAQmx_Val_Amps                                                    10342 ' Amps
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale
$define DAQmx_Val_FromTEDS                                                12516 ' From TEDS

'*** Value set CurrentUnits2 ***
$define DAQmx_Val_Amps                                                    10342 ' Amps
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_AI_RawSampJustification ***
'*** Value set DataJustification1 ***
$define DAQmx_Val_RightJustified                                          10279 ' Right-Justified
$define DAQmx_Val_LeftJustified                                           10209 ' Left-Justified

'*** Values for DAQmx_AI_DataXferMech ***
'*** Values for DAQmx_AO_DataXferMech ***
'*** Values for DAQmx_DI_DataXferMech ***
'*** Values for DAQmx_DO_DataXferMech ***
'*** Values for DAQmx_CI_DataXferMech ***
'*** Value set DataTransferMechanism ***
$define DAQmx_Val_DMA                                                     10054 ' DMA
$define DAQmx_Val_Interrupts                                              10204 ' Interrupts
$define DAQmx_Val_ProgrammedIO                                            10264 ' Programmed I/O
$define DAQmx_Val_USBbulk                                                 12590 ' USB Bulk

'*** Values for DAQmx_DO_OutputDriveType ***
'*** Value set DigitalDriveType ***
$define DAQmx_Val_ActiveDrive                                             12573 ' Active Drive
$define DAQmx_Val_OpenCollector                                           12574 ' Open Collector

'*** Values for DAQmx_Watchdog_DO_ExpirState ***
'*** Value set DigitalLineState ***
$define DAQmx_Val_High                                                    10192 ' High
$define DAQmx_Val_Low                                                     10214 ' Low
$define DAQmx_Val_Tristate                                                10310 ' Tristate
$define DAQmx_Val_NoChange                                                10160 ' No Change

'*** Values for DAQmx_DigPattern_StartTrig_When ***
'*** Values for DAQmx_DigPattern_RefTrig_When ***
'*** Value set DigitalPatternCondition1 ***
$define DAQmx_Val_PatternMatches                                          10254 ' Pattern Matches
$define DAQmx_Val_PatternDoesNotMatch                                     10253 ' Pattern Does Not Match

'*** Values for DAQmx_StartTrig_DelayUnits ***
'*** Value set DigitalWidthUnits1 ***
$define DAQmx_Val_SampClkPeriods                                          10286 ' Sample Clock Periods
$define DAQmx_Val_Seconds                                                 10364 ' Seconds
$define DAQmx_Val_Ticks                                                   10304 ' Ticks

'*** Values for DAQmx_DelayFromSampClk_DelayUnits ***
'*** Value set DigitalWidthUnits2 ***
$define DAQmx_Val_Seconds                                                 10364 ' Seconds
$define DAQmx_Val_Ticks                                                   10304 ' Ticks

'*** Values for DAQmx_Exported_AdvTrig_Pulse_WidthUnits ***
'*** Value set DigitalWidthUnits3 ***
$define DAQmx_Val_Seconds                                                 10364 ' Seconds

'*** Values for DAQmx_CI_Freq_StartingEdge ***
'*** Values for DAQmx_CI_Period_StartingEdge ***
'*** Values for DAQmx_CI_CountEdges_ActiveEdge ***
'*** Values for DAQmx_CI_PulseWidth_StartingEdge ***
'*** Values for DAQmx_CI_TwoEdgeSep_FirstEdge ***
'*** Values for DAQmx_CI_TwoEdgeSep_SecondEdge ***
'*** Values for DAQmx_CI_SemiPeriod_StartingEdge ***
'*** Values for DAQmx_CI_CtrTimebaseActiveEdge ***
'*** Values for DAQmx_CO_CtrTimebaseActiveEdge ***
'*** Values for DAQmx_SampClk_ActiveEdge ***
'*** Values for DAQmx_SampClk_Timebase_ActiveEdge ***
'*** Values for DAQmx_AIConv_ActiveEdge ***
'*** Values for DAQmx_DigEdge_StartTrig_Edge ***
'*** Values for DAQmx_DigEdge_RefTrig_Edge ***
'*** Values for DAQmx_DigEdge_AdvTrig_Edge ***
'*** Values for DAQmx_DigEdge_ArmStartTrig_Edge ***
'*** Values for DAQmx_DigEdge_WatchdogExpirTrig_Edge ***
'*** Value set Edge1 ***
$define DAQmx_Val_Rising                                                  10280 ' Rising
$define DAQmx_Val_Falling                                                 10171 ' Falling

'*** Values for DAQmx_CI_Encoder_DecodingType ***
'*** Value set EncoderType2 ***
$define DAQmx_Val_X1                                                      10090 ' X1
$define DAQmx_Val_X2                                                      10091 ' X2
$define DAQmx_Val_X4                                                      10092 ' X4
$define DAQmx_Val_TwoPulseCounting                                        10313 ' Two Pulse Counting

'*** Values for DAQmx_CI_Encoder_ZIndexPhase ***
'*** Value set EncoderZIndexPhase1 ***
$define DAQmx_Val_AHighBHigh                                              10040 ' A High B High
$define DAQmx_Val_AHighBLow                                               10041 ' A High B Low
$define DAQmx_Val_ALowBHigh                                               10042 ' A Low B High
$define DAQmx_Val_ALowBLow                                                10043 ' A Low B Low

'*** Values for DAQmx_AI_Excit_DCorAC ***
'*** Value set ExcitationDCorAC ***
$define DAQmx_Val_DC                                                      10050 ' DC
$define DAQmx_Val_AC                                                      10045 ' AC

'*** Values for DAQmx_AI_Excit_Src ***
'*** Value set ExcitationSource ***
$define DAQmx_Val_Internal                                                10200 ' Internal
$define DAQmx_Val_External                                                10167 ' External
$define DAQmx_Val_None                                                    10230 ' None

'*** Values for DAQmx_AI_Excit_VoltageOrCurrent ***
'*** Value set ExcitationVoltageOrCurrent ***
$define DAQmx_Val_Voltage                                                 10322 ' Voltage
$define DAQmx_Val_Current                                                 10134 ' Current

'*** Values for DAQmx_Exported_CtrOutEvent_OutputBehavior ***
'*** Value set ExportActions2 ***
$define DAQmx_Val_Pulse                                                   10265 ' Pulse
$define DAQmx_Val_Toggle                                                  10307 ' Toggle

'*** Values for DAQmx_Exported_SampClk_OutputBehavior ***
'*** Value set ExportActions3 ***
$define DAQmx_Val_Pulse                                                   10265 ' Pulse
$define DAQmx_Val_Lvl                                                     10210 ' Level

'*** Values for DAQmx_Exported_HshkEvent_OutputBehavior ***
'*** Value set ExportActions5 ***
$define DAQmx_Val_Interlocked                                             12549 ' Interlocked
$define DAQmx_Val_Pulse                                                   10265 ' Pulse

'*** Values for DAQmx_AI_Freq_Units ***
'*** Value set FrequencyUnits ***
$define DAQmx_Val_Hz                                                      10373 ' Hz
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_CO_Pulse_Freq_Units ***
'*** Value set FrequencyUnits2 ***
$define DAQmx_Val_Hz                                                      10373 ' Hz

'*** Values for DAQmx_CI_Freq_Units ***
'*** Value set FrequencyUnits3 ***
$define DAQmx_Val_Hz                                                      10373 ' Hz
$define DAQmx_Val_Ticks                                                   10304 ' Ticks
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_CI_GPS_SyncMethod ***
'*** Value set GpsSignalType1 ***
$define DAQmx_Val_IRIGB                                                   10070 ' IRIG-B
$define DAQmx_Val_PPS                                                     10080 ' PPS
$define DAQmx_Val_None                                                    10230 ' None

'*** Values for DAQmx_Hshk_StartCond ***
'*** Value set HandshakeStartCondition ***
$define DAQmx_Val_Immediate                                               10198 ' Immediate
$define DAQmx_Val_WaitForHandshakeTriggerAssert                           12550 ' Wait For Handshake Trigger Assert
$define DAQmx_Val_WaitForHandshakeTriggerDeassert                         12551 ' Wait For Handshake Trigger Deassert


'*** Values for DAQmx_AI_DataXferReqCond ***
'*** Values for DAQmx_DI_DataXferReqCond ***
'*** Value set InputDataTransferCondition ***
$define DAQmx_Val_OnBrdMemMoreThanHalfFull                                10237 ' Onboard Memory More than Half Full
$define DAQmx_Val_OnBrdMemNotEmpty                                        10241 ' Onboard Memory Not Empty
$define DAQmx_Val_OnbrdMemCustomThreshold                                 12577 ' Onboard Memory Custom Threshold
$define DAQmx_Val_WhenAcqComplete                                         12546 ' When Acquisition Complete

'*** Values for DAQmx_AI_TermCfg ***
'*** Value set InputTermCfg ***
$define DAQmx_Val_RSE                                                     10083 ' RSE
$define DAQmx_Val_NRSE                                                    10078 ' NRSE
$define DAQmx_Val_Diff                                                    10106 ' Differential
$define DAQmx_Val_PseudoDiff                                              12529 ' Pseudodifferential

'*** Values for DAQmx_AI_LVDT_SensitivityUnits ***
'*** Value set LVDTSensitivityUnits1 ***
$define DAQmx_Val_mVoltsPerVoltPerMillimeter                              12506 ' mVolts/Volt/mMeter
$define DAQmx_Val_mVoltsPerVoltPerMilliInch                               12505 ' mVolts/Volt/0.001 Inch

'*** Values for DAQmx_AI_LVDT_Units ***
'*** Value set LengthUnits2 ***
$define DAQmx_Val_Meters                                                  10219 ' Meters
$define DAQmx_Val_Inches                                                  10379 ' Inches
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_CI_LinEncoder_Units ***
'*** Value set LengthUnits3 ***
$define DAQmx_Val_Meters                                                  10219 ' Meters
$define DAQmx_Val_Inches                                                  10379 ' Inches
$define DAQmx_Val_Ticks                                                   10304 ' Ticks
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_CI_OutputState ***
'*** Values for DAQmx_CO_Pulse_IdleState ***
'*** Values for DAQmx_CO_OutputState ***
'*** Values for DAQmx_Exported_CtrOutEvent_Toggle_IdleState ***
'*** Values for DAQmx_Exported_HshkEvent_Interlocked_AssertedLvl ***
'*** Values for DAQmx_Interlocked_HshkTrig_AssertedLvl ***
'*** Values for DAQmx_DigLvl_PauseTrig_When ***
'*** Value set Level1 ***
$define DAQmx_Val_High                                                    10192 ' High
$define DAQmx_Val_Low                                                     10214 ' Low

'*** Values for DAQmx_AIConv_Timebase_Src ***
'*** Value set MIOAIConvertTbSrc ***
$define DAQmx_Val_SameAsSampTimebase                                      10284 ' Same as Sample Timebase
$define DAQmx_Val_SameAsMasterTimebase                                    10282 ' Same as Master Timebase
$define DAQmx_Val_20MHzTimebase                                           12537 ' 20MHz Timebase

'*** Values for DAQmx_AO_DataXferReqCond ***
'*** Values for DAQmx_DO_DataXferReqCond ***
'*** Value set OutputDataTransferCondition ***
$define DAQmx_Val_OnBrdMemEmpty                                           10235 ' Onboard Memory Empty
$define DAQmx_Val_OnBrdMemHalfFullOrLess                                  10239 ' Onboard Memory Half Full or Less
$define DAQmx_Val_OnBrdMemNotFull                                         10242 ' Onboard Memory Less than Full

'*** Values for DAQmx_AO_TermCfg ***
'*** Value set OutputTermCfg ***
$define DAQmx_Val_RSE                                                     10083 ' RSE
$define DAQmx_Val_Diff                                                    10106 ' Differential
$define DAQmx_Val_PseudoDiff                                              12529 ' Pseudodifferential

'*** Values for DAQmx_Read_OverWrite ***
'*** Value set OverwriteMode1 ***
$define DAQmx_Val_OverwriteUnreadSamps                                    10252 ' Overwrite Unread Samples
$define DAQmx_Val_DoNotOverwriteUnreadSamps                               10159 ' Do Not Overwrite Unread Samples

'*** Values for DAQmx_Exported_AIConvClk_Pulse_Polarity ***
'*** Values for DAQmx_Exported_SampClk_Pulse_Polarity ***
'*** Values for DAQmx_Exported_AdvTrig_Pulse_Polarity ***
'*** Values for DAQmx_Exported_AdvCmpltEvent_Pulse_Polarity ***
'*** Values for DAQmx_Exported_AIHoldCmpltEvent_PulsePolarity ***
'*** Values for DAQmx_Exported_ChangeDetectEvent_Pulse_Polarity ***
'*** Values for DAQmx_Exported_CtrOutEvent_Pulse_Polarity ***
'*** Values for DAQmx_Exported_HshkEvent_Pulse_Polarity ***
'*** Values for DAQmx_Exported_RdyForXferEvent_Lvl_ActiveLvl ***
'*** Value set Polarity2 ***
$define DAQmx_Val_ActiveHigh                                              10095 ' Active High
$define DAQmx_Val_ActiveLow                                               10096 ' Active Low


'*** Values for DAQmx_AI_RTD_Type ***
'*** Value set RTDType1 ***
$define DAQmx_Val_Pt3750                                                  12481 ' Pt3750
$define DAQmx_Val_Pt3851                                                  10071 ' Pt3851
$define DAQmx_Val_Pt3911                                                  12482 ' Pt3911
$define DAQmx_Val_Pt3916                                                  10069 ' Pt3916
$define DAQmx_Val_Pt3920                                                  10053 ' Pt3920
$define DAQmx_Val_Pt3928                                                  12483 ' Pt3928
$define DAQmx_Val_Custom                                                  10137 ' Custom

'*** Values for DAQmx_AI_RVDT_SensitivityUnits ***
'*** Value set RVDTSensitivityUnits1 ***
$define DAQmx_Val_mVoltsPerVoltPerDegree                                  12507 ' mVolts/Volt/Degree
$define DAQmx_Val_mVoltsPerVoltPerRadian                                  12508 ' mVolts/Volt/Radian

'*** Values for DAQmx_AI_RawDataCompressionType ***
'*** Value set RawDataCompressionType ***
$define DAQmx_Val_None                                                    10230 ' None
$define DAQmx_Val_LosslessPacking                                         12555 ' Lossless Packing
$define DAQmx_Val_LossyLSBRemoval                                         12556 ' Lossy LSB Removal

'*** Values for DAQmx_Read_RelativeTo ***
'*** Value set ReadRelativeTo ***
$define DAQmx_Val_FirstSample                                             10424 ' First Sample
$define DAQmx_Val_CurrReadPos                                             10425 ' Current Read Position
$define DAQmx_Val_RefTrig                                                 10426 ' Reference Trigger
$define DAQmx_Val_FirstPretrigSamp                                        10427 ' First Pretrigger Sample
$define DAQmx_Val_MostRecentSamp                                          10428 ' Most Recent Sample


'*** Values for DAQmx_Write_RegenMode ***
'*** Value set RegenerationMode1 ***
$define DAQmx_Val_AllowRegen                                              10097 ' Allow Regeneration
$define DAQmx_Val_DoNotAllowRegen                                         10158 ' Do Not Allow Regeneration

'*** Values for DAQmx_AI_ResistanceCfg ***
'*** Value set ResistanceConfiguration ***
$define DAQmx_Val_2Wire                                                       2 ' 2-Wire
$define DAQmx_Val_3Wire                                                       3 ' 3-Wire
$define DAQmx_Val_4Wire                                                       4 ' 4-Wire

'*** Values for DAQmx_AI_Resistance_Units ***
'*** Value set ResistanceUnits1 ***
$define DAQmx_Val_Ohms                                                    10384 ' Ohms
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale
$define DAQmx_Val_FromTEDS                                                12516 ' From TEDS

'*** Value set ResistanceUnits2 ***
$define DAQmx_Val_Ohms                                                    10384 ' Ohms
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_AI_ResolutionUnits ***
'*** Values for DAQmx_AO_ResolutionUnits ***
'*** Value set ResolutionType1 ***
$define DAQmx_Val_Bits                                                    10109 ' Bits

'*** Values for DAQmx_Hshk_SampleInputDataWhen ***
'*** Value set SampleInputDataWhen ***
$define DAQmx_Val_HandshakeTriggerAsserts                                 12552 ' Handshake Trigger Asserts
$define DAQmx_Val_HandshakeTriggerDeasserts                               12553 ' Handshake Trigger Deasserts

'*** Values for DAQmx_SampTimingType ***
'*** Value set SampleTimingType ***
$define DAQmx_Val_SampClk                                                 10388 ' Sample Clock
$define DAQmx_Val_BurstHandshake                                          12548 ' Burst Handshake
$define DAQmx_Val_Handshake                                               10389 ' Handshake
$define DAQmx_Val_Implicit                                                10451 ' Implicit
$define DAQmx_Val_OnDemand                                                10390 ' On Demand
$define DAQmx_Val_ChangeDetection                                         12504 ' Change Detection

'*** Values for DAQmx_Scale_Type ***
'*** Value set ScaleType ***
$define DAQmx_Val_Linear                                                  10447 ' Linear
$define DAQmx_Val_MapRanges                                               10448 ' Map Ranges
$define DAQmx_Val_Polynomial                                              10449 ' Polynomial
$define DAQmx_Val_Table                                                   10450 ' Table

'*** Values for DAQmx_AI_ChanCal_ScaleType ***
'*** Value set ScaleType2 ***
$define DAQmx_Val_Polynomial                                              10449 ' Polynomial
$define DAQmx_Val_Table                                                   10450 ' Table

'*** Values for DAQmx_AI_Bridge_ShuntCal_Select ***
'*** Value set ShuntCalSelect ***
$define DAQmx_Val_A                                                       12513 ' A
$define DAQmx_Val_B                                                       12514 ' B
$define DAQmx_Val_AandB                                                   12515 ' A and B

'*** Value set Signal ***
$define DAQmx_Val_AIConvertClock                                          12484 ' AI Convert Clock
$define DAQmx_Val_10MHzRefClock                                           12536 ' 10MHz Reference Clock
$define DAQmx_Val_20MHzTimebaseClock                                      12486 ' 20MHz Timebase Clock
$define DAQmx_Val_SampleClock                                             12487 ' Sample Clock
$define DAQmx_Val_AdvanceTrigger                                          12488 ' Advance Trigger
$define DAQmx_Val_ReferenceTrigger                                        12490 ' Reference Trigger
$define DAQmx_Val_StartTrigger                                            12491 ' Start Trigger
$define DAQmx_Val_AdvCmpltEvent                                           12492 ' Advance Complete Event
$define DAQmx_Val_AIHoldCmpltEvent                                        12493 ' AI Hold Complete Event
$define DAQmx_Val_CounterOutputEvent                                      12494 ' Counter Output Event
$define DAQmx_Val_ChangeDetectionEvent                                    12511 ' Change Detection Event
$define DAQmx_Val_WDTExpiredEvent                                         12512 ' Watchdog Timer Expired Event

'*** Value set Signal2 ***
$define DAQmx_Val_SampleCompleteEvent                                     12530 ' Sample Complete Event
$define DAQmx_Val_CounterOutputEvent                                      12494 ' Counter Output Event
$define DAQmx_Val_ChangeDetectionEvent                                    12511 ' Change Detection Event
$define DAQmx_Val_SampleClock                                             12487 ' Sample Clock

'*** Values for DAQmx_AnlgEdge_StartTrig_Slope ***
'*** Values for DAQmx_AnlgEdge_RefTrig_Slope ***
'*** Value set Slope1 ***
$define DAQmx_Val_RisingSlope                                             10280 ' Rising
$define DAQmx_Val_FallingSlope                                            10171 ' Falling

'*** Values for DAQmx_AI_SoundPressure_Units ***
'*** Value set SoundPressureUnits1 ***
$define DAQmx_Val_Pascals                                                 10081 ' Pascals
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_AI_Lowpass_SwitchCap_ClkSrc ***
'*** Values for DAQmx_AO_DAC_Ref_Src ***
'*** Values for DAQmx_AO_DAC_Offset_Src ***
'*** Value set SourceSelection ***
$define DAQmx_Val_Internal                                                10200 ' Internal
$define DAQmx_Val_External                                                10167 ' External

'*** Values for DAQmx_AI_StrainGage_Cfg ***
'*** Value set StrainGageBridgeType1 ***
$define DAQmx_Val_FullBridgeI                                             10183 ' Full Bridge I
$define DAQmx_Val_FullBridgeII                                            10184 ' Full Bridge II
$define DAQmx_Val_FullBridgeIII                                           10185 ' Full Bridge III
$define DAQmx_Val_HalfBridgeI                                             10188 ' Half Bridge I
$define DAQmx_Val_HalfBridgeII                                            10189 ' Half Bridge II
$define DAQmx_Val_QuarterBridgeI                                          10271 ' Quarter Bridge I
$define DAQmx_Val_QuarterBridgeII                                         10272 ' Quarter Bridge II

'*** Values for DAQmx_AI_Strain_Units ***
'*** Value set StrainUnits1 ***
$define DAQmx_Val_Strain                                                  10299 ' Strain
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_SwitchScan_RepeatMode ***
'*** Value set SwitchScanRepeatMode ***
$define DAQmx_Val_Finite                                                  10172 ' Finite
$define DAQmx_Val_Cont                                                    10117 ' Continuous

'*** Values for DAQmx_SwitchChan_Usage ***
'*** Value set SwitchUsageTypes ***
$define DAQmx_Val_Source                                                  10439 ' Source
$define DAQmx_Val_Load                                                    10440 ' Load
$define DAQmx_Val_ReservedForRouting                                      10441 ' Reserved for Routing

'*** Value set TEDSUnits ***
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale
$define DAQmx_Val_FromTEDS                                                12516 ' From TEDS

'*** Values for DAQmx_AI_Temp_Units ***
'*** Value set TemperatureUnits1 ***
$define DAQmx_Val_DegC                                                    10143 ' Deg C
$define DAQmx_Val_DegF                                                    10144 ' Deg F
$define DAQmx_Val_Kelvins                                                 10325 ' Kelvins
$define DAQmx_Val_DegR                                                    10145 ' Deg R
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_AI_Thrmcpl_Type ***
'*** Value set ThermocoupleType1 ***
$define DAQmx_Val_J_Type_TC                                               10072 ' J
$define DAQmx_Val_K_Type_TC                                               10073 ' K
$define DAQmx_Val_N_Type_TC                                               10077 ' N
$define DAQmx_Val_R_Type_TC                                               10082 ' R
$define DAQmx_Val_S_Type_TC                                               10085 ' S
$define DAQmx_Val_T_Type_TC                                               10086 ' T
$define DAQmx_Val_B_Type_TC                                               10047 ' B
$define DAQmx_Val_E_Type_TC                                               10055 ' E

'*** Values for DAQmx_CI_Timestamp_Units ***
'*** Value set TimeUnits ***
$define DAQmx_Val_Seconds                                                 10364 ' Seconds
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_CO_Pulse_Time_Units ***
'*** Value set TimeUnits2 ***
$define DAQmx_Val_Seconds                                                 10364 ' Seconds

'*** Values for DAQmx_CI_Period_Units ***
'*** Values for DAQmx_CI_PulseWidth_Units ***
'*** Values for DAQmx_CI_TwoEdgeSep_Units ***
'*** Values for DAQmx_CI_SemiPeriod_Units ***
'*** Value set TimeUnits3 ***
$define DAQmx_Val_Seconds                                                 10364 ' Seconds
$define DAQmx_Val_Ticks                                                   10304 ' Ticks
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_ArmStartTrig_Type ***
'*** Values for DAQmx_WatchdogExpirTrig_Type ***
'*** Value set TriggerType4 ***
$define DAQmx_Val_DigEdge                                                 10150 ' Digital Edge
$define DAQmx_Val_None                                                    10230 ' None

'*** Values for DAQmx_AdvTrig_Type ***
'*** Value set TriggerType5 ***
$define DAQmx_Val_DigEdge                                                 10150 ' Digital Edge
$define DAQmx_Val_Software                                                10292 ' Software
$define DAQmx_Val_None                                                    10230 ' None

'*** Values for DAQmx_PauseTrig_Type ***
'*** Value set TriggerType6 ***
$define DAQmx_Val_AnlgLvl                                                 10101 ' Analog Level
$define DAQmx_Val_AnlgWin                                                 10103 ' Analog Window
$define DAQmx_Val_DigLvl                                                  10152 ' Digital Level
$define DAQmx_Val_None                                                    10230 ' None

'*** Values for DAQmx_StartTrig_Type ***
'*** Values for DAQmx_RefTrig_Type ***
'*** Value set TriggerType8 ***
$define DAQmx_Val_AnlgEdge                                                10099 ' Analog Edge
$define DAQmx_Val_DigEdge                                                 10150 ' Digital Edge
$define DAQmx_Val_DigPattern                                              10398 ' Digital Pattern
$define DAQmx_Val_AnlgWin                                                 10103 ' Analog Window
$define DAQmx_Val_None                                                    10230 ' None

'*** Values for DAQmx_HshkTrig_Type ***
'*** Value set TriggerType9 ***
$define DAQmx_Val_Interlocked                                             12549 ' Interlocked
$define DAQmx_Val_None                                                    10230 ' None

'*** Values for DAQmx_Scale_PreScaledUnits ***
'*** Value set UnitsPreScaled ***
$define DAQmx_Val_Volts                                                   10348 ' Volts
$define DAQmx_Val_Amps                                                    10342 ' Amps
$define DAQmx_Val_DegF                                                    10144 ' Deg F
$define DAQmx_Val_DegC                                                    10143 ' Deg C
$define DAQmx_Val_DegR                                                    10145 ' Deg R
$define DAQmx_Val_Kelvins                                                 10325 ' Kelvins
$define DAQmx_Val_Strain                                                  10299 ' Strain
$define DAQmx_Val_Ohms                                                    10384 ' Ohms
$define DAQmx_Val_Hz                                                      10373 ' Hz
$define DAQmx_Val_Seconds                                                 10364 ' Seconds
$define DAQmx_Val_Meters                                                  10219 ' Meters
$define DAQmx_Val_Inches                                                  10379 ' Inches
$define DAQmx_Val_Degrees                                                 10146 ' Degrees
$define DAQmx_Val_Radians                                                 10273 ' Radians
$define DAQmx_Val_g                                                       10186 ' g
$define DAQmx_Val_MetersPerSecondSquared                                  12470 ' m/s^2
$define DAQmx_Val_Pascals                                                 10081 ' Pascals
$define DAQmx_Val_FromTEDS                                                12516 ' From TEDS

'*** Values for DAQmx_AI_Voltage_Units ***
'*** Value set VoltageUnits1 ***
$define DAQmx_Val_Volts                                                   10348 ' Volts
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale
$define DAQmx_Val_FromTEDS                                                12516 ' From TEDS

'*** Values for DAQmx_AO_Voltage_Units ***
'*** Value set VoltageUnits2 ***
$define DAQmx_Val_Volts                                                   10348 ' Volts
$define DAQmx_Val_FromCustomScale                                         10065 ' From Custom Scale

'*** Values for DAQmx_Read_WaitMode ***
'*** Value set WaitMode ***
$define DAQmx_Val_WaitForInterrupt                                        12523 ' Wait For Interrupt
$define DAQmx_Val_Poll                                                    12524 ' Poll
$define DAQmx_Val_Yield                                                   12525 ' Yield
$define DAQmx_Val_Sleep                                                   12547 ' Sleep

'*** Values for DAQmx_Write_WaitMode ***
'*** Value set WaitMode2 ***
$define DAQmx_Val_Poll                                                    12524 ' Poll
$define DAQmx_Val_Yield                                                   12525 ' Yield
$define DAQmx_Val_Sleep                                                   12547 ' Sleep

'*** Values for DAQmx_RealTime_WaitForNextSampClkWaitMode ***
'*** Value set WaitMode3 ***
$define DAQmx_Val_WaitForInterrupt                                        12523 ' Wait For Interrupt
$define DAQmx_Val_Poll                                                    12524 ' Poll

'*** Values for DAQmx_RealTime_WriteRecoveryMode ***
'*** Value set WaitMode4 ***
$define DAQmx_Val_WaitForInterrupt                                        12523 ' Wait For Interrupt
$define DAQmx_Val_Poll                                                    12524 ' Poll

'*** Values for DAQmx_AnlgWin_StartTrig_When ***
'*** Values for DAQmx_AnlgWin_RefTrig_When ***
'*** Value set WindowTriggerCondition1 ***
$define DAQmx_Val_EnteringWin                                             10163 ' Entering Window
$define DAQmx_Val_LeavingWin                                              10208 ' Leaving Window

'*** Values for DAQmx_AnlgWin_PauseTrig_When ***
'*** Value set WindowTriggerCondition2 ***
$define DAQmx_Val_InsideWin                                               10199 ' Inside Window
$define DAQmx_Val_OutsideWin                                              10251 ' Outside Window

'*** Value set WriteBasicTEDSOptions ***
$define DAQmx_Val_WriteToEEPROM                                           12538 ' Write To EEPROM
$define DAQmx_Val_WriteToPROM                                             12539 ' Write To PROM Once
$define DAQmx_Val_DoNotWrite                                              12540 ' Do Not Write

'*** Values for DAQmx_Write_RelativeTo ***
'*** Value set WriteRelativeTo ***
$define DAQmx_Val_FirstSample                                             10424 ' First Sample
$define DAQmx_Val_CurrWritePos                                            10430 ' Current Write Position

