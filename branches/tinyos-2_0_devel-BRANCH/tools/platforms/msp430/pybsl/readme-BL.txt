Below is the readme for the replacement BSL ROMS:
BL_150S_14x.txt and BL_150S_44x.txt

These BSL's are (C) by TI. They come with the application note slaa089a

----------------------------------------------------------------------------
 Loadable Bootstrap Loaders for MSP430Fxxx                            10/01
----------------------------------------------------------------------------

 For detailed description please have a look at the application reports
 
 1) Features of the MSP430 Bootstrap Loader
 2) Application of Bootstrap Loader in MSP430 w/Flash - Hardware,
    Software Proposal (SLAA096A) 

 This package consists of three loadable bootstrap loader object files:

 1) PATCH.txt
 2) BL_150S_14x.txt
 3) BL_150S_44x.txt 

 * PATCH.txt is a small loadable patch sequence for the first official
 version V1.10. It is absolutely mandatory for executing the "RX Block"
 command reliable.

 * BL_150S_14x.txt is a complete BSL for the F1xx family with all features
 of BSL version V1.50 plus "Change Baudrate" command. Since its code size
 is bigger than 1kByte it only can be used in F1x8 and F1x9 devices.
 The error address buffer address for "RX Block", "Erase Segment", and
 "Erase Check" commands is 021Eh.
 BL_150S_14x.txt could also be used as a replacement for PATCH.txt.

 * BL_150S_44x.txt is a complete BSL for the F4xx family with all features
 of BSL version V1.50 plus "Change Baudrate" command. Since its code size
 is bigger than 1kByte it only can be used in F4x8 and F4x9 devices.
 The error address buffer address for "RX Block", "Erase Segment", and
 "Erase Check" commands is 0200h.
 


 * End of Readme *