* =======================PROGRAM: MHI_CONTROL.SAS==============================;
*  VERSION: SAS Beta version of Maternal Health Indicators v2024
*  RELEASE DATE: SEPTEMBER 2024
* =============================================================================;
 * The Maternal Health Indicators (MHI) module of the AHRQ Quality
   Indicators software includes the following programs:
   
   1. MHI_CONTROL.SAS   Assigns user inputs required by other programs
                        and optional output features.  
                             
   2. MHI_FORMATS.SAS   Creates SAS format library used by other programs.
                             
   3. MHI_MEASURES.SAS  Assigns numerator, denominator, and severity flags for
                        Maternal Health Indicators.
                        Refer to technical specification documents for details. 
                             
   4. MHI_OBSERVED.SAS  Calculates observed rates by stratum.

 * The software also requires the following files (all included except discharges):
 
  1. discharges.sas7bdat  User supplied discharge level file organized according 
                          to the software instructions.
                          The file name is up to the user but must be listed below.
                     
  2. MHI_Dx_Pr_Macros_v2024.sas  Standard processes used by the other SAS programs.
                                 The user does not need to open.


***************************************************************************** ;
******************************* PLEASE READ ********************************* ;
***************************************************************************** ;

  * The AHRQ Quality Indicator software is intended for use with discharges
   coded according to the standards in place on the date of the discharge. 
   Discharges should be classified under the ICD-10-CM/PCS specifications 
   effective on or after 10/1/2015. All diagnosis codes require a corresponding 
   Present on Admission, POA, value coded according to UB04 standards. 
   Although results can be generated with inputs coded under ICD9 and 
   converted to ICD10 with General Equivalence Mappings, the mapping process
   may produce unrepresentative results. ICD10 observed rate calculations
   should not be used to produce ICD9 risk adjusted outputs.
 
 * The USER MUST modify portions of the following code in order to
   run this software.  The only changes necessary to run
   this software are changes in this program (MHI_CONTROL.SAS). 
   The modifications include such items as specifying the name and location
   of the input data set, the year of population data to be used, and the 
   name and location of output data sets.
 
* NOTE:  MHI_CONTROL.SAS provides the option to read data in and write 
         data out to different locations.  For example, "libname INMSR" points
         to the location of the input data set for the MHI_MEASURES program
         and "libname OUTMSR" points to the location of the output data set
         created by the MHI_MEASURES program. The location and file name of 
         each input and output can be assigned separately below. The default 
         values will place output in a SASData folder with standard names for
         each file based on the location of the MHI folder listed in the 
         PATHNAME variable.
         
*   See the AHRQ_MHI_SAS_v2024_ICD10_Release_Notes.txt file for version change details.

 Generally speaking, a first-time user of this software would proceed 
 as outlined below:

    1.  Modify and save all required user inputs in MHI_CONTROL.SAS. (This program - MUST be done.)

    2.  Select the programs to run by updating the flags (EXE_FMT,EXE_MSR, EXE_AOBS).
        The default option will run all programs. Programs must be run in order and 
        will not execute if the required input is not available. See log for details. 

    3.  Run (submit) the MHI_CONTROL.SAS. (MUST be done.) 
        
 * ------------------------------------------------------------------ ;
 * ---                 INPUTS FOR ALL PROGRAMS                    --- ;
 * ------------------------------------------------------------------ ;

*PATHNAME specifies the location of the MHI folder which includes the
          Programs, Macros, and SASData subfolders;
%LET PATHNAME=C:\Pathname\MHI;                   *<===USER MUST modify;

*DISFOLDER specifies the folder that contains the discharge data;
%LET DISFOLDER=C:\Pathname;                      *<===USER MUST modify;

*DISCHARGE specifies the name of the discharge data file;
%LET DISCHARGE=discharges;                       *<===USER MUST modify;

*SUFX specifies an identifier suffix to be placed on output datasets;
%LET SUFX =v2024;                                 *<===USER may modify;

*LIBRARY is where formats generated by MHI_FORMATS will be saved;
libname LIBRARY  "&PATHNAME.\SASData";            *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- INDICATE IF RECORDS SHOULD BE PRINTED IN SAS OUTPUT AT     --- ;
 * --- END OF EACH PROGRAM.  0 = NO, 1 = YES                      --- ;
 * ------------------------------------------------------------------ ;
%LET PRINT = 0;                                   *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- ADD OPTION TO COMPRESS OUTPUT. RECOMMENDED WITH            --- ;
 * --- LARGE FILES. TO RESTORE RUN:                               --- ;
 * ---   options compress = no                                    --- ;
 * ------------------------------------------------------------------ ;
options compress = YES 
        nocenter ls=255 formchar="|--+|-/\<>*";   *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET LOCATION OF SAS MACRO LIBRARY                          --- ;
 * ------------------------------------------------------------------ ;
filename MacLib "&PATHNAME.\Macros";              *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * ---              PROGRAM: MHI_MEASURES.SAS                     --- ;
 * ------------------------------------------------------------------ ;
 
 * ------------------------------------------------------------------ ;
 * --- SET LOCATION OF MHI_MEASURES.SAS INPUT DATA                --- ;
 * ------------------------------------------------------------------ ;
libname INMSR  "&DISFOLDER.";                      *<==USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET LOCATION OF MHI_MEASURES.SAS OUTPUT DATA               --- ;
 * ------------------------------------------------------------------ ;
libname OUTMSR "&PATHNAME.\SASData";               *<==USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET NAME OF OUTPUT FILE FROM MHI_MEASURES.SAS              --- ;
 * ------------------------------------------------------------------ ;
%LET OUTFILE_MEAS = MHMSR_&SUFX.;                 *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- INDICATE ADDITIONAL INPUT VARIABLES TO KEEP ON OUTPUT      --- ;
 * --- DATA FILE FROM MHI_MEASURES.SAS.                           --- ;
 * --- INPUT VARIABLES ALWAYS INCLUDED ON THE OUTPUT FILE ARE:    --- ;
 * --- KEY HOSPST HOSPID SEX AGE YEAR DQTR                        --- ;
 * ------------------------------------------------------------------ ;
%LET OUTFILE_KEEP = ;                             *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- MODIFY INPUT AND OUTPUT FILE                               --- ;
 * ------------------------------------------------------------------ ;
 * --- PROGRAM DEFAULT ASSUMES THERE ARE                          --- ;
 * ---     35 DIAGNOSES (DX1-DX35)                                --- ;
 * ---     30 PROCEDURES (PR1-PR30)                               --- ;
 * ------------------------------------------------------------------ ;
 * --- MODIFY NUMBER OF DIAGNOSIS AND PROCEDURE VARIABLES TO      --- ;
 * --- MATCH USER DISCHARGE INPUT DATA                            --- ;
 * ------------------------------------------------------------------ ;
%LET NDX = 35;                                    *<===USER may modify;
%LET NPR = 30;                                    *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * - CREATE PERMANENT SAS DATASET TO STORE RECORDS THAT WILL      --- ;
 * - NOT BE INCLUDED IN CALCULATIONS BECAUSE KEY VARIABLE         --- ;
 * - VALUES ARE MISSING.  THIS DATASET SHOULD BE REVIEWED AFTER   --- ;
 * - RUNNING MHI_MEASURES.SAS.                                    --- ;
 * ------------------------------------------------------------------ ;
%LET DELFILE  = MHI_DELETED_&SUFX.;               *<===USER may modify;
 
 * ------------------------------------------------------------------ ;
 * ---       PROGRAM: MHI_OBSERVED.SAS - OBSERVED RATES           --- ;
 * ------------------------------------------------------------------ ;
 
 * ------------------------------------------------------------------ ;
 * --- USER DEFINED STRATUM VARIABLE NAME. THE DEFAULT IS BLANK.  --- ;
 * --- THE SOFTWARE BY DEFAULT GENERATES NUMERATORS,              --- ;
 * --- DENOMINATORS, AND OBSERVED RATES BY RACE, PAYER, POVCAT,   --- ;
 * --- STATE, AND YEAR. USERS CAN ADD ONE MORE VARIABLE, SUCH AS  --- ;
 * --- HOSPID, FOR THE SOFTWARE TO GENERATE OUTPUT BY THE USER    --- ;
 * --- DEFINED STRATUM.                                           --- ;
 * ------------------------------------------------------------------ ;
%LET CUSTOM_STRATUM = ;                           *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- SET LOCATION OF MHI_OBSERVED.SAS OUTPUT DATA               --- ;
 * ------------------------------------------------------------------ ;
libname OUTAOBS "&PATHNAME.\SASData";             *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- NAME OF SAS DATASET OUTPUT FROM MHI_OBSERVED.SAS           --- ;
 * --- SUMMARY OUTPUT FILE OF OBSERVED RATES.                     --- ;
 * ------------------------------------------------------------------ ;
%LET  OUTFILE_AREAOBS  = MHAO_&SUFX.;             *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- INDICATE IF A COMMA-DELIMITED FILE OF OUTFILE_AREAOBS      --- ;
 * --- SHOULD BE GENERATED FOR EXPORT INTO A SPREADSHEET.         --- ;
 * ---    0 = NO, 1 = YES.                                        --- ;
 * ------------------------------------------------------------------ ;
%LET TXTAOBS=0;                                   *<===USER may modify;

 * ------------------------------------------------------------------ ;
 * --- IF YOU CREATE A COMMA-DELIMITED FILE, SPECIFY THE LOCATION --- ;
 * --- OF THE FILE.                                               --- ;
 * ------------------------------------------------------------------ ;
filename MHTXTAOB "&PATHNAME.\SASData\MHAO_&SUFX..TXT";    *<===USER may modify;


************************* Programs to execute ********************************* ;
 * ---------------------------------------------------------------------------- ;
 * --- SET FLAGS TO RUN INDIVIDUAL PROGRAMS WHEN CONTROL PROGRAM RUNS.      --- ;
 * --- 0 = NO, 1 = YES                                                      --- ;
 * ---------------------------------------------------------------------------- ;
%LET EXE_FMT  = 0;  * Format Library created if not present. Set to 1 if replacing existing library;
%LET EXE_MSR  = 1;  * Execute MHI_MEASURES program; 
%LET EXE_AOBS = 1;  * Execute MHI_OBSERVED program; 


************************* END USER INPUT ***************************************;
* --- Include standard diagnosis and procedure macros.                      --- ;
%include MacLib(MHI_Dx_Pr_Macros_v2024.sas);

* --- Execute Control Program to run flagged programs.                      --- ;
%PROG_EXE(&PATHNAME.,&EXE_FMT.,&EXE_MSR.,&EXE_AOBS.);