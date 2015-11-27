# FRAP and FLIP analysis on moving cell junctions
This MATLAB code is associated with a forthcoming Cell Reports paper *Intravital FRAP imaging using an E-cadherin-GFP mouse reveals disease and drug-dependent dynamic regulation of cell-cell junctions in live tissue*.

The code allows FRAP, FLIP and GLCM analysis of moving junctions. Please see the paper methods and supplimentary methods for a detailed description of the functionality provided.

## Preparing data
This code has been designed and tested with FRAP data acquired on a Leica SP8 microscope where the data has been exported in the structure described below. It is expected that data acquired from other microscope platforms will be relatively easy to process, however some modifications will be required to read in the FRAP 'regions of interest' files produced by different platforms. 


### Data organisation
The code is designed to process many FRAP sequences at once. To do so, the data must be organised in the following folder structure. 
```
Experimental Condition   < Top level folder
  - FRAP000 *.roi           <--- Leica region of interest files describing bleach region
  - FRAP001 *.roi           <----|
  - FRAPNNN *.roi           <----|
    + Imaging Data          < Folder containing all FRAP series
        + FRAP_000             < Sub folder containing a single FRAP series
         + FRAP Pre *             < Folder containing pre-bleach frames saved as numbered tifs  
         + FRAP Pb1 *             < Folder containing pre-bleach frames saved as numbered tifs
     + FRAP_001                < Next FRAP series
     + FRAP_NNN                < Last FRAP series
```
## Running photobleaching analysis 
Required software
*  MATLAB is required to use this tool. We have tested with versions R2015a and R2015b although it should work with any relatively recent version. 
*  To use the (semi-)graphical interface, the Matlab GUI tools plugin should be installed from: http://www.mathworks.com/matlabcentral/fileexchange/47982-gui-layout-toolbox
 
