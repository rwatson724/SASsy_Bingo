/****************************************************************************************
Program:          bingo_card.sas
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

/**************************************************************************/
/*** BEGIN SECTION TO INITIALIZE ALL MACRO VARIABLES AND DEFINE FORMATS ***/
/**************************************************************************/
%let path = C:\Users\gonza\Desktop\GitHub\SASsy_Bingo;
%let hdrimg = bbb_resized_v2.png;
%let bingo_file = Conference Call Bingo.xlsx;
%let bingo_sheet = Bingo;
%let font = 'AMT Albany';

%let bingo_card = MyBingoCard_checkerboard;  /*** prefix used to name the bingo card ***/
%let textlen = 15;
%let splitchr = ^;

options validvarname = v7;
ods path(prepend) work.TEMPLAT (update);
libname BINGO 'C:\Users\gonza\Desktop\GitHub\SASsy_Bingo\Data';
/************************************************************************/
/*** END SECTION TO INITIALIZE ALL MACRO VARIABLES AND DEFINE FORMATS ***/
/************************************************************************/

/**************************************************************************/
/*** BEGIN SECTION TO READ IN AND RANDOMLY SELECT TEXT FOR BINGO CARDS  ***/
/**************************************************************************/
/* read in the list of bingo text options */
libname bingoxls xlsx "&path.\Data\&bingo_file";
data bingo (drop = things_you_hear_or_see_on_a_call);
   set bingoxls."&bingo_sheet"n;

   /* format the text so it will display accurately */
   bingo_text = strip(things_you_hear_or_see_on_a_call);

   bt_len = length(bingo_text);
run;
libname bingoxls clear;

/* determine the number of possible splits based on the max length of all values */
proc sql noprint;
   select ceil(max(length(bingo_text)) / &textlen) + 5 into :numsplit
   from bingo;
quit;
/************************************************************************/
/*** END SECTION TO READ IN AND RANDOMLY SELECT TEXT FOR BINGO CARDS  ***/
/************************************************************************/

/***************************************************************************/
/*** BEGIN SECTION TO DEFINE GRAPH TEMPLATE FOR CHECKERBOARD BINGO CARDS ***/
/***************************************************************************/
proc template;
   define statgraph bingo_ck;
      begingraph / border = false backgroundcolor = bgr;

         layout datalattice columnvar = colnum rowvar = rownum / shrinkfonts = true
                                         headerlabeldisplay = NONE
                                         rowaxisopts = (display = NONE)
                                         columnaxisopts = (display = NONE);
             
              layout prototype;
                 blockplot x = xval block = grp / display = (fill);
                 textplot x = xval y = yval 
                          text = b_text / textattrs = (family = "&font"
                                                       weight = bold
                                                       size = 6pt)
                                          splitpolicy = split
                                          splitchar = "^"
                                          group = grp;  
              endlayout;

         endlayout;
      endgraph;
   end;
run;
/*************************************************************************/
/*** END SECTION TO DEFINE GRAPH TEMPLATE FOR CHECKERBOARD BINGO CARDS ***/
/*************************************************************************/

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

         /* these are defaulted to one so that they can be used on the textplot statement */
         xval = 1;
         yval = 1;

         /*************************************************************/
         /*** BEGIN SECTION TO ADD SPLIT CHARACTERS TO BINGO VALUES ***/
         /*************************************************************/
         /* insert split characters */
         array __split(&numsplit) $ &textlen;
         __var = bingo_text;
         __len = length(__var);
         __i = 0;
         /* if text will not fit then split otherwise get out of loop */
         /* check character (_chr) needs to be initialized to some non-delimiter/split value just to get into loop */
         do while (__len > &textlen);
            __chk = &textlen + 1;
            __chr = '+';
            /* look for the split character within the first _chk characters and if it exists then reset _chk to location + 1 */
            if find(substr(__var, 1, __chk), "&splitchr") then __chk = find(substr(__var, 1, __chk), "&splitchr") + 1;

            /* need to look for a delimiter or natural split - if there is a natural split want to keep it */
            /* get out of loop once a delimiter or split character is found or until there are no more charcaters to check */
            do until (__chr in (' ' '/' '-' "&splitchr") or __chk = 0);
               __chk = __chk - 1;
               if __chk ne 0 then __chr = substr(__var, __chk, 1);
            end;

            __i + 1;
            /* if existed loop because of a split or delimiter then create a split */
            if __chk > 0 then do;
               if substr(__var, __chk, 1) = "&splitchr" then __split(__i) = substr(__var, 1, __chk - 1);
               else __split(__i) = substr(__var, 1, __chk);
               __var = substr(__var, __chk + 1);
            end;
            /* no logical delimiter or split character found within specified length so split at specified length */
            else do;
               __split(__i) = substr(__var, 1, &textlen);
               __var = substr(__var, &textlen + 1);
            end;

            /* __var has been reset so need to reset the __len as well */
            __len = length(__var);
         end;
         /* once out of the loop need to assign the remainder of the text to the next array variable */
         __split(__i + 1) = __var;
         
         /* combine all the variables into one separated by the split character */
         length b_text $1000;
         b_text = catx("&splitchr", of __split:);
         /***********************************************************/
         /*** END SECTION TO ADD SPLIT CHARACTERS TO BINGO VALUES ***/
         /***********************************************************/
      run;
      
      /* have text be different colors - 2 different colors */
      %if &multiclr = Y %then %do;
         data bingo&i.;
            set bingo&i.;
            grp = mod(_n_, 2) + 1;
         run;
      %end;

      /* render each bingo card */
      options nodate nonumber;
      ods graphics on / width = 6.5in height = 7in;
      ods &ext file = "&path.\cards\&bingo_card._&i._m7.&ext"
              %if &ext = pdf %then dpi ; %else image_dpi; = 300;

      ods escapechar = "^";
      title "^S = {preimage=""&path.\images\&hdrimg"" }";

      proc sgrender data = bingo&i. template = bingo_ck
                dattrmap = BINGO.BINGOATTR;
         dattrvar grp = 'TXTCLRC';
      run;
      ods &ext close;
   %end;

%mend bingo;

options mprint mlogic;
%bingo(maxcards = 1, ext = rtf)
%bingo(maxcards = 1, ext = pdf)
