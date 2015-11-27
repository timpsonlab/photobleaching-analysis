Expected Structure
===================================================
Imaging Session 
 - FRAP000 *.roi         < Leica ROI files corresponding to all FRAP series
 - FRAP001 *.roi         
 - FRAPNNN *.roi 
 + Imaging Data          < Folder with all FRAP series
     + FRAP_000             < Folder with one FRAP series
         + FRAP Pre *          < Folder with tif stack of pre-bleach frames 
         + FRAP Pb1 *          < Folder with tif stack of photobleached frames
     + FRAP_001
     + FRAP_NNN

FRAP Data
===================================================
To process a series of FRAP data

 1. Run 
 