function FRAPInterface

    buttons = {
               {'Process FRAP Folders', @ProcessFRAPFolders}
               {'Process FLIP Folders', @ProcessFLIPStack}
              };
           
    Interface('GarvanFrap', 'Garvan FRAP', buttons);