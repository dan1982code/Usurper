{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
(********************************)
(*   Programming:  Bob Dalton   *)
(*   ERROR LOG UNIT - Vers 1.00 *)
(*   Utility Module             *)
(********************************)

UNIT Elog;

INTERFACE


VAR
 SaveExitProc: POINTER;

PROCEDURE Terminate (N:Byte);
PROCEDURE TrapExit;
PROCEDURE MyExit1;

IMPLEMENTATION   (********************************)

Uses Crt, Dos, DDPlus,
     Netfilep, Jakob, File_Io; {jakob}

{$IFDEF MSDOS}
Procedure GetDate1(VAR Month:Word;
                   VAR day:Word;
                   VAR year:Word);
 VAR MyRegs:Registers;

 Begin
  MyRegs.AH:=$2A;
  MSDOS(MyRegs);
  Month:=MyRegs.DH;
  Day:=MyRegs.DL;
  Year:=MyRegs.CX;
 End;
{$ENDIF}
{$IFDEF WIN32}
Procedure GetDate1(VAR Month:Word;
                   VAR day:Word;
                   VAR year:Word);
var
  DOW: Word;
begin
  GetDate(Year, Month, Day, DOW);
end;
{$ENDIF}

PROCEDURE Terminate (N:Byte);
 Begin
   CASE N OF
     0:Begin {} End;{SWriteln('Normal Termination'); jakob remmar bort}
     1:Begin SWriteln('Carrier lost'); End;
     2:Begin SWriteln('*** TIME LIMIT HAS EXPIRED ***'); End;
     3:Begin SWriteln('User Inactive for 5+ minutes'); End;
   End
 End;

{$F+}

(* This exit procedure may be used to trap HALT codes.  If defined in the
   main body of your program (DoorExit := TrapExit), this procedure will be
   called whenever your program encounters a HALT code or runtime error.

   As shown below, if ErrorAddr <> NIL (no runtime error has occurred) the
   runtime error information is displayed to the local console and is also
   written to a file called PROG_ERR.LOG.  You may wish to change the name
   of this error log file to something more fitting to your program.
   If ErrorAddr = NIL then this code assumes that no runtime error has
   occurred but rather that a HALT code has been encountered.  You could
   conceivably handle all your HALT functions within the TRAPEXIT procedure.
   However, in this demonstration, we can see that we are passing the HALT
   code onto the TERMINATE procedure which is located within your program's
   code.
*)


PROCEDURE TrapExit;

CONST
   {Replace GodFather with the name of your program}

   ProductName='Usurper'; {jakob}
   logname    ='ERROR.LOG'; {jakob}

VAR
   ErrFile    : TEXT ;
   A1: Byte;
   YE: Boolean;
   OpenAttempts: Integer;
   GoAhead:Boolean;
   Year,Month,Day: Word;


   FUNCTION Exit_message(Code: Integer): STRING;
      {return message text for a given exit code}
   VAR
      Msg:    STRING;
   BEGIN
      CASE Code OF
           0: Msg := ''; {'Normal Termination'; jaokb tar bort}
           1: Msg := 'Carrier Lost';
           2: Msg := 'Time Limit Exceeded';
           3: Msg := 'User Inactivity Timeout';
           4: Msg := 'Cannot Find Dorinfo1.def';
           5: Msg := 'Cannot Find ExitInfo.Bbs';
           6: Msg := 'Directory Change/Read Error';
           7: Msg := 'CTS Timeout';
           8: Msg := 'Forced Exit via RAXIT Semaphore';
           9: Msg := 'Cannot Find Door.Sys';
         ELSE STR(Code,Msg);
      END;
      Exit_Message := Msg;
   END;


   FUNCTION Itoh(W: Integer): STRING;
      {hex conversion}
   CONST
      Hex: ARRAY[0..15] OF CHAR = '0123456789ABCDEF';
   VAR
      H: STRING[4];
   BEGIN
      H[0] := CHR(4);
      H[1] := Hex[(W SHR 12) AND $0f];
      H[2] := Hex[(W SHR  8) AND $0f];
      H[3] := Hex[(W SHR  4) AND $0f];
      H[4] := Hex[W          AND $0f];
      Itoh := H;
   END;

BEGIN
   A1:=18;
   YE:=False;
   GetDate1(Month,day,year);
   IF ErrorAddr = NIL THEN
    Begin
     If ExitCode = 0 then
      Begin
       Terminate(0) ;
       Exit;
      End;
     
     {Replace the next line with the name of YOUR save procedure}
     {This ones save my game information should something go wrong}
     {I have left it so you see what I did, although it IS commented out}

     {SaveGame(Player,PlayerFile,TempP,Country,CountryFile,Map1,MapFile);}
     
     IF ShareInst=False then FileMode:=64;
{$IFDEF WIN32}
     FileModeReadWrite := FileMode;
{$ENDIF}
     YE:=False;
     ASSIGN(ErrFile,logname);
     IF F_EXISTS(logname) THEN
      Begin
       OpenAttempts:=1;
       Repeat
        {$I-}
        Append(ErrFile);
        {$I+}
        GoAhead:= (IOResult = 0);
        If Not GoAhead then begin
         OpenAttempts :=OpenAttempts+1;
         releasetimeslice; {jakob}
        end;
       Until (GoAhead) or (OpenAttempts>15);
      End;
     IF NOT F_EXISTS(logname) THEN
      Begin
       OpenAttempts:=1;
       Repeat
        {$I-}Rewrite(ErrFile);{$I+}
        GoAhead:= (IOResult = 0);
        If Not GoAhead then begin
         OpenAttempts :=OpenAttempts+1;
         releasetimeslice; {jakob}
        end;
       Until (GoAhead) or (OpenAttempts>15);
      End;
     If ProductName <> '' then
      Begin
       Writeln_to_text(ErrFile,' ');
       Writeln_to_text(ErrFile,'Error Log Generated by '+ProductName);
      End;
     WRITELN('Date : ',Month,'/',Day,'/',Year);
     WRITELN(' ');
     WRITELN('Program Termination');
     WRITELN(Exit_Message(Exitcode));
     WRITELN_to_text(ErrFile,'Date : '+commastr(Month)+'/'+commastr(Day)+'/'+commastr(Year)); {jakob}
     WRITELN_to_text(ErrFile,'Program Termination');
     WRITELN_to_text(ErrFile,Exit_Message(Exitcode));
     Close_text(ErrFile); {jakob}
     IF ShareInst=False then FileMode:=66;
{$IFDEF WIN32}
     FileModeReadWrite := FileMode;
{$ENDIF}
     {be sure to uncomment this if using RipLink}
     {if RIP <> nil then
      Dispose(RIP, Done);}
     Terminate(ExitCode);
     Delay2(1000);
     End ELSE
      BEGIN

     {Replace the next line with the name of YOUR save procedure}
     {This ones save my game information should something go wrong}
     {I have left it so you see what I did, although it IS commented out}

       {SaveGame(Player,PlayerFile,TempP,Country,CountryFile,Map1,MapFile);}

       ASSIGN(ErrFile,logname);
       IF F_EXISTS(logname) THEN
        Begin
         OpenAttempts:=1;
         Repeat
          {$I-}
          Append(ErrFile);
          {$I+}
          GoAhead:= (IOResult = 0);
          If Not GoAhead then begin
           OpenAttempts :=OpenAttempts+1;
           releasetimeslice; {jakob}
          end;
         Until (GoAhead) or (OpenAttempts>15);
        End;
       IF NOT F_EXISTS(logname) THEN
        Begin
         OpenAttempts:=1;
         Repeat
          {$I-}Rewrite(ErrFile);{$I+}
          GoAhead:= (IOResult = 0);
          If Not GoAhead then begin
           OpenAttempts :=OpenAttempts+1;
           releasetimeslice; {jakob}
          end;
         Until (GoAhead) or (OpenAttempts>15);
        End;
      If ProductName <> '' then
       Begin
        Writeln_to_text(ErrFile,' ');
        Writeln_to_text(ErrFile,'Error Log Generated by '+ProductName);
       End;
       WRITELN('Date : ',Month,'/',Day,'/',Year);
       WRITELN('Run-time error occurred');
       WRITELN('Exitcode = ', exitcode);
       WRITELN(Error_Message(Exitcode));
       WRITELN('Address of error:');
       WRITELN('  Segment: ', ItoH(seg(erroraddr^)));
       WRITELN('  Offset:  ', ItoH(ofs(erroraddr^))) ;
       WRITELN_to_text(ErrFile,'Date : '+commastr(Month)+'/'+commastr(Day)+'/'+commastr(Year));
       WRITELN_to_text(ErrFile,'Run-time error occurred');
       WRITELN_to_text(ErrFile,'Exitcode = '+commastr(exitcode));
       WRITELN_to_text(ErrFile,Error_Message(Exitcode));
       WRITELN_to_text(ErrFile,'Address of error:');
       WRITELN(ErrFile,'  Segment: ', ItoH(seg(erroraddr^)));
       WRITELN(ErrFile,'  Offset:  ', ItoH(ofs(erroraddr^))) ;
       WRITELN_to_text(ErrFile,'------------------------------------------------');
       Close_text(ErrFile);
       IF ShareInst=False then FileMode:=66;
{$IFDEF WIN32}
       FileModeReadWrite := FileMode;
{$ENDIF}
      END ;
   ErrorAddr := NIL ;
   {be sure to uncomment this if using RipLink}
   {if RIP <> nil then
     Dispose(RIP, Done);}
  END;
{$F-}

{$F+} Procedure MyExit1; {$F-}
VAR SaveExitProc: POINTER;
Begin;
 TrapExit;
 SaveExitProc:=Exitproc;
End;

END.

