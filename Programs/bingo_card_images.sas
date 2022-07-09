/****************************************************************************************
Program:          bingo_card.sas
SAS Version:      SAS 9.4m5
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
%let hdrimg = loteria_banner.png;
%let bingo_file = Loteria Words for Bingo.xlsx;
%let bingo_sheet = items;
%let font = 'Arial';

%let bingo_card = Loteria;

options validvarname = v7;
ods path(prepend) work.TEMPLAT (update);
/************************************************************************/
/*** END SECTION TO INITIALIZE ALL MACRO VARIABLES AND DEFINE FORMATS ***/
/************************************************************************/

/**************************************************************************/
/*** BEGIN SECTION TO READ IN AND RANDOMLY SELECT TEXT FOR BINGO CARDS  ***/
/**************************************************************************/
/* read in the list of bingo text options */
libname bingo xlsx "&path.\Programs\&bingo_file";
data bingo (drop = items);
   set bingo."&bingo_sheet"n;
   where status = 'done';

   /* create the full file name including path and extension */
   bingo_item = cats("&path.\Images\Final\", english, ".png");
run;
libname bingo clear;
/************************************************************************/
/*** END SECTION TO READ IN AND RANDOMLY SELECT TEXT FOR BINGO CARDS  ***/
/************************************************************************/

/**************************************************************************/
/*** BEGIN SECTION TO DEFINE GRAPH TEMPLATE AND GENERATE BINGO CARDS    ***/
/**************************************************************************/
%macro crtcard;
   proc template;
      define statgraph bingo_img;
         begingraph / border = false backgroundcolor = CXC00000;
            layout lattice / rows = 5 rowweights = uniform rowgutter = 0 rowdatarange = union
                             columns = 5 columnweights = uniform columngutter = 0 columndatarange = union;

               %do row = 1 %to 5;
                  %do col = 1 %to 5;
                     layout overlay / xaxisopts = (display = NONE griddisplay = OFF)
                                      yaxisopts = (display = NONE griddisplay = OFF);
                        textplot x = xval y = yval
                                 text = english    / display = (fill) pad = 0
                                                     fillattrs = (color = white)
                                                     textattrs = (family = "&font"
                                                                  weight = bold
                                                                  color = white
                                                                  size = 6pt);

                        annotate / id = "IMG_&row._&col";
                     endlayout;
                  %end;
               %end;
            endlayout;
         endgraph;
      end;
   run;
%mend crtcard;

%crtcard
/************************************************************************/
/*** END SECTION TO DEFINE GRAPH TEMPLATE AND GENERATE BINGO CARDS    ***/
/************************************************************************/

/**************************************************************************/
/*** BEGIN SECTION TO SELECT TEXT FOR BINGO CARDS AND RENDER BINGO CARDS***/
/**************************************************************************/
%macro bingo(maxcards = 5, ext = pdf);
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
      run;

      /**** https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatug/p1qlqpavhh0e1pn10oon6blo7dt6.htm#p1gxn84cjw5z80n1i9tyqlm2dnzd ****/
      /**** https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatproc/p1pwlltro89q1sn1mfvpcc5kc23j.htm ****/
      /**** https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatproc/p1cdsjhbc8dk20n1jp3xsozin5pe.htm ****/
      data anno (keep = id drawspace function image layer height: image:);
          set bingo&i.;
          id = catx('_', 'IMG', rownum, colnum);
          drawspace = 'dataspace';
          function = 'image';
          image = bingo_item;
          layer = 'front';
          height = 80;
          heightunit = "PIXEL";
          imagescale = 'FIT';
      run;

      /* render each bingo card */
      options nodate nonumber;
      ods graphics on / width = 6.5in height = 7in;
      ods &ext file = "&path.\cards\&bingo_card._&i..&ext"
              %if &ext = pdf %then dpi ; %else image_dpi; = 150;

      ods escapechar = "^";
      title "^S = {preimage=""&path.\images\&hdrimg"" }";

      proc sgrender data = bingo&i. template = bingo_img sganno = anno;
      run;
      ods &ext close;
   %end;

%mend bingo;

options mprint mlogic;
%bingo(maxcards = 1, ext = rtf)
%bingo(maxcards = 1, ext = pdf)
