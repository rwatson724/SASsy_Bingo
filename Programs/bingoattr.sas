/****************************************************************************************
Program:          bingoattr.sas
SAS Version:      SAS 9.4m7
Developer:        Richann Watson 
Date:             2021 
Operating Sys:    Windows 10
----------------------------------------------------------------------------------------- 

Revision History:
Date: 
Requestor: 
Modification: 
Modifier: 
----------------------------------------------------------------------------------------- 
****************************************************************************************/
libname BINGO 'C:\Users\gonza\Desktop\GitHub\SASsy_Bingo\Data';

/******************************************************************************/
/*** BEGIN SECTION TO CREATE AN ATTRIBUTE MAP TO MAKE TEXT DIFFERENT COLORS ***/
/******************************************************************************/
data BINGO.BINGOATTR (drop = i);
   ID = 'TXTCLRB';
   array bclrs(5) $20 _TEMPORARY_ ('deeppink' 'lightseagreen' 'blueviolet' 'darkturquoise' 'mediumvioletred');
   do i = 1 to 5;
      VALUE = cats(i);
      TEXTCOLOR = bclrs(i);
      output;
   end;

   ID = 'TXTCLRC';
   array cclrs(2) $20 _TEMPORARY_ ('lightpink' 'black');
   do i = 1 to 2;
      VALUE = cats(i);
      TEXTCOLOR = cclrs(i);
      if i = 1 then FILLCOLOR = cclrs(i+1);
      else if i = 2 then FILLCOLOR = cclrs(1);
      output;
   end;
run;
/****************************************************************************/
/*** END SECTION TO CREATE AN ATTRIBUTE MAP TO MAKE TEXT DIFFERENT COLORS ***/
/****************************************************************************/