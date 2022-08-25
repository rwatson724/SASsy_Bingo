/****************************************************************************************
Program:          PROCREPORTBingoCheckerboard.sas
SAS Version:      SAS 9.4m7
Developer:        Louise Hadden 
Date:             2022 
Operating Sys:    AWS Windows Server
----------------------------------------------------------------------------------------- 

Revision History:
Date: 
Requestor: 
Modification: 
Modifier: 
----------------------------------------------------------------------------------------- 
****************************************************************************************/

/**************************************************************************/
/*** BEGIN SECTION TO INITIALIZE ALL MACRO VARIABLES AND DEFINE FORMATS ***/
/**************************************************************************/
%let path = C:\Users\gonza\Desktop\GitHub\SASsy_Bingo;
*%let hdrimg = bbb_resized_v2.png;
%let bingo_file = Conference Call Bingo.xlsx;
%let bingo_sheet = Bingo;
%let font = 'AMT Albany';

%let bingo_card = MyBingoCard;  /*** prefix used to name the bingo card ***/
%let textlen = 15;
%let splitchr = ^;

options validvarname = v7;
ods path(prepend) work.TEMPLAT (update);
/************************************************************************/
/*** END SECTION TO INITIALIZE ALL MACRO VARIABLES AND DEFINE FORMATS ***/
/************************************************************************/

/**************************************************************************/
/*** BEGIN SECTION TO READ IN DATA USED FOR RANDOM SELECTION FOR CARDS  ***/
/**************************************************************************/

proc import dbms=xlsx out = bingo0
    datafile = "&path.\Data\Conference Call Bingo.xlsx" replace;
run;

/* read in the list of bingo text options */
data bingo (drop = things_you_hear_or_see_on_a_call);
   set bingo0;

   /* format the text so it will display accurately */
   bingo_text = strip(things_you_hear_or_see_on_a_call);

   bt_len = length(bingo_text);
run;

/* determine the number of possible splits based on the max length of all values */
proc sql noprint;
   select ceil(max(length(bingo_text)) / &textlen) + 5 into :numsplit
   from bingo;
quit;
/************************************************************************/
/*** END SECTION TO READ IN DATA USED FOR RANDOM SELECTION FOR CARDS  ***/
/************************************************************************/

/**************************************************************************/
/*** BEGIN SECTION TO SELECT TEXT FOR BINGO CARDS AND RENDER BINGO CARDS***/
/**************************************************************************/
%macro bingo(maxcards = 5, multiclr = Y, ext = pdf);
   %do i = 1 %to &maxcards;

      data bingo&i._a;
         set bingo;
         call streaminit('PCG', 0); /* auto-generate seed */
         __run = rand('uniform'); 
      run;

      proc sort data = bingo&i._a;
         by __run;
      run;

      data bingo&i.;
         set bingo&i._a;
         by __run;
         if _n_ le 25;
          
         retain rownum 0 colnum;
         if mod(_n_, 5) = 1 then do;
           rownum + 1;
           colnum = 0;
         end;
         colnum + 1;
      /* have text be different colors - 5 different colors */
      %if &multiclr = Y %then %do;
         data bingo&i.;
            set bingo&i.;
            if mod(_n_,2)=0 then checker=1;
            else checker=2;
         run;
      %end;
   
      ******************************************;
      ** transpose                            **;
      ******************************************;
      data col1 (keep=rownum grp1 col1) 
           col2 (keep=rownum grp2 col2)
           col3 (keep=rownum grp3 col3)
           col4 (keep=rownum grp4 col4)
           col5 (keep=rownum grp5 col5);
          set bingo&i;
          if colnum=1 then do;
              grp1=checker;
              col1=bingo_text;
              output col1;
          end;
          if colnum=2 then do;
              grp2=checker;
              col2=bingo_text;
              output col2;
          end;
          if colnum=3 then do;
              grp3=checker;
              col3=bingo_text;
              output col3;
          end;
          if colnum=4 then do;
              grp4=checker;
              col4=bingo_text;
              output col4;
          end;
          if colnum=5 then do;
              grp5=checker;
              col5=bingo_text;
              output col5;
          end;
      run;

      data bingo&i._2;
          merge col1-col5;
          by rownum;
      run;

      options nonumber nodate;

      title1 ;
      run;
      ods escapechar='^';

      ods listing close;

      options topmargin=.5in leftmargin=.8in rightmargin=.8in papersize=letter ;

      ods pdf file="&path.\cards\PROCREPORTbingoCheckerboard_&i..pdf" style=styles.pearl dpi=600 notoc
          author='Louise Hadden' bookmarklist = hide compress = 9;

      title1 '^{newline 2}';

      ods text='^S={just=c preimage="&path.\images\bbb_resized.png"}';

      ods text='^{newline 5}';

      proc report nowd data=bingo&i._2 noheader
          style(report)=[cellpadding=5pt vjust=b]
          style(header)=[just=center font_face="Helvetica" font_weight=bold font_size=8pt]
          style(lines)=[just=left font_face="Helvetica"] split='|';
        
          columns rownum grp1 grp2 grp3 grp4 grp5 col1 col2 col3 col4 col5 ;
          define rownum / display ' ' noprint;
          define grp1 / display ' ' noprint;  
          define grp2 / display ' ' noprint;   
          define grp3 / display ' ' noprint;   
          define grp4 / display ' ' noprint;   
          define grp5 / display ' ' noprint;      
          define col1 / style(COLUMN)={just=c vjust=c font_face="Helvetica" 
                 font_size=8pt cellwidth=195 cellheight=195 borderwidth=4pt};
          define col2 / style(COLUMN)={just=c vjust=c font_face="Helvetica" 
                 font_size=8pt cellwidth=195 cellheight=195 borderwidth=4pt };
          define col3 / style(COLUMN)={just=c vjust=c font_face="Helvetica" 
                 font_size=8pt cellwidth=195 cellheight=195 borderwidth=4pt };
          define col4 / style(COLUMN)={just=c vjust=c font_face="Helvetica" 
                 font_size=8pt cellwidth=195 cellheight=195 borderwidth=4pt };
          define col5 / style(COLUMN)={just=c vjust=c font_face="Helvetica" 
                 font_size=8pt cellwidth=195 cellheight=195 borderwidth=4pt };

          compute col1;
                if grp1=1 then do; color='pink'; rcolor='black'; end;
                else do;  color='black'; rcolor='pink'; end;
                call define ('col1','style','style=[foreground='||color||' background='||rcolor||']');
          endcomp;

          compute col2;
                if grp2=1 then do; color='pink'; rcolor='black'; end;
                else do;  color='black'; rcolor='pink'; end;
                call define ('col2','style','style=[foreground='||color||' background='||rcolor||']');
          endcomp;

          compute col3;
                if grp3=1 then do; color='pink'; rcolor='black'; end;
                else do;  color='black'; rcolor='pink'; end;
                call define ('col3','style','style=[foreground='||color||' background='||rcolor||']');
          endcomp;

          compute col4;
                if grp4=1 then do; color='pink'; rcolor='black'; end;
                else do;  color='black'; rcolor='pink'; end;
                call define ('col4','style','style=[foreground='||color||' background='||rcolor||']');
          endcomp;

          compute col5;
                if grp5=1 then do; color='pink'; rcolor='black'; end;
                else do;  color='black'; rcolor='pink'; end;
                call define ('col5','style','style=[foreground='||color||' background='||rcolor||']');
          endcomp;
      run;

      ods pdf close;

   %end;
%mend bingo;

%bingo(maxcards = 1);