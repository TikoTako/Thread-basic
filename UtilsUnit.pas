unit UtilsUnit;

interface

uses
  System.SysUtils, System.SyncObjs;

type

  PDataToProcess = ^TDataToProcess;

  TDataToProcess = packed record
    SomeDoubleToMakeItTrouble: double;
    SomeBool: boolean;
    SomeString: string;
  end;

  PDataToProcessArray = ^TDataToProcessArray;
  TDataToProcessArray = array of TDataToProcess;

  PResultData = ^TResultData;

  TResultData = packed record
    ThreadID: Cardinal;
    ThreadHandle: THandle;
    Result: string;
    HazData: boolean;
    class operator Initialize(out Dest: TResultData);
  end;

  PResultDataArray = ^TResultDataArray;
  TResultDataArray = array of TResultData;

procedure logSpace();
procedure log(s: string); overload;
procedure log(s: string; const c: array of const); overload;
procedure PressEnterToExit();

implementation

var
  fLock: TCriticalSection;

  { TResultData }

class operator TResultData.Initialize(out Dest: TResultData);
begin
  Dest.ThreadID := 0;
  Dest.ThreadHandle := 0;
  Dest.Result := '';
  Dest.HazData := false;
end;

{ Other stuff }

procedure logSpace();
begin
  log(#0);
end;

procedure log(s: string);
begin
  // Need a lock or the writeln get mixed with other threads
  fLock.Acquire;
  sleep(10);
  case ord(s[1]) of
    0:
      writeln(s);
    1:
      writeln('Press [enter] to exit.');
    2 .. $FF:
      writeln(Format('<%s> %s', [FormatDateTime('HH:nn:ss.zzz', now), s]))
  end;
  sleep(10);
  fLock.Release;
end;

procedure log(s: string; const c: array of const);
begin
  log(Format(s, c));
end;

procedure PressEnterToExit();
var
  vPotato: string;
begin
  log(#1);
  readln(vPotato);
end;

initialization

fLock := TCriticalSection.Create;

finalization

fLock.Free;

end.
