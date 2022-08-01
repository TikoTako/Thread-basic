unit ThreadUnit_B;

interface

uses
  System.Math, System.SyncObjs, System.Classes, System.SysUtils,
  UtilsUnit;

type
  TWut = (iCurrentData = 1, iTotalData);

  TThread_B = class(TThread)
    { --- --- --- }
  strict private
  class var
    fgCurrentDataIndex: integer;
    fgTotalDataToProcess: integer;
    fgDataResults: TResultDataArray;
    fgDataToProcess: TDataToProcessArray;
    fgCriticalSection: TCriticalSection;
  strict private
    class constructor Create();
    class destructor Destroy();
    class procedure SetDataToProcess(DataTPA: TDataToProcessArray); static;
    class function GetStuff(index: TWut): integer; static;
    class function GetDataToProcessArray(): TDataToProcessArray; static;
    class function GetResultsArray(): TResultDataArray; static;
  public
    class property DataToProcess: TDataToProcessArray read GetDataToProcessArray write SetDataToProcess;
    class property DataResults: TResultDataArray read GetResultsArray;
    class property CurrentDataIndex: integer index iCurrentData read GetStuff;
    class property TotalDataToProcess: integer index iTotalData read GetStuff;
    { --- --- --- }
  strict private
    fBusy: boolean;
    fEvent: TEvent;
    fStarted: boolean;
    fDoneSignal: TEvent;
    { function GetBusy(): boolean; }
    function GetDoneHandle(): THandle;
  public
    constructor Create();
    destructor Destroy(); override;
    function Start(): boolean; reintroduce;
    procedure ResetDone();
  protected
    procedure Execute(); override;
  public
    property isBusy: boolean read fBusy { GetBusy };
    property DoneHandle: THandle read GetDoneHandle;
  end;

implementation

{ function TThread_B.GetBusy(): boolean;
  begin
  Exit(fDoneSignal.WaitFor(0) = wrSignaled);
  end; }

class constructor TThread_B.Create();
begin
  log('Y HALO THAR');
  fgCurrentDataIndex := -1;
  fgTotalDataToProcess := 0;
  SetLength(fgDataResults, 0);
  SetLength(fgDataToProcess, 0);
  fgCriticalSection := TCriticalSection.Create; // this call InitializeCriticalSection
end;

class destructor TThread_B.Destroy();
begin
  log('Y GOODBYE THAR');
  fgCriticalSection.Free; // and this just call the destructor that call DeleteCriticalSection
end;

class function TThread_B.GetStuff(index: TWut): integer;
begin
  fgCriticalSection.Acquire;
  case index of
    iCurrentData:
      result := fgCurrentDataIndex;
    iTotalData:
      result := fgTotalDataToProcess;
  end;
  fgCriticalSection.Release;
end;

class function TThread_B.GetDataToProcessArray(): TDataToProcessArray;
begin
  fgCriticalSection.Acquire;
  result := fgDataToProcess;
  fgCriticalSection.Release;
end;

class function TThread_B.GetResultsArray(): TResultDataArray;
begin
  fgCriticalSection.Acquire;
  result := fgDataResults;
  fgCriticalSection.Release;
end;

class procedure TThread_B.SetDataToProcess(DataTPA: TDataToProcessArray);
begin
  fgCurrentDataIndex := -1;
  fgDataToProcess := DataTPA;
  fgTotalDataToProcess := Length(fgDataToProcess);
  SetLength(fgDataResults, fgTotalDataToProcess);
end;

/// /////////

function TThread_B.GetDoneHandle(): THandle;
begin
  Exit(fDoneSignal.Handle);
end;

constructor TThread_B.Create();
begin
  //
  fStarted := false;
  FreeOnTerminate := false;
  log('constructor TThread_B.Create();');
  fEvent := TEvent.Create(nil, true, false, 'Gionatan Gioestar');
  fDoneSignal := TEvent.Create(nil, true, false, 'im done bruh > ' + ThreadID.ToString);
  inherited Create(true);
end;

destructor TThread_B.Destroy();
begin
  log('destructor TThread_B.Destroy(%d);', [ThreadID]);
  if not Terminated then
  begin
    Terminate;
    fEvent.SetEvent;
  end;
  inherited;
end;

function TThread_B.Start(): boolean;
begin
  // I think this is set too late because if i try to start 2 times in a row theres an error if i check with it
  // if not Started then
  if not fStarted then
  begin
    log('procedure TThread_B.Start(%d); - FIRST', [ThreadID]);
    fStarted := true;
    inherited Start();
  end
  else
  begin
    if not fBusy { GetBusy } then
    begin
      log('procedure TThread_B.Start(%d); - NOT BUSY', [ThreadID]);
      fEvent.SetEvent;
    end
    else
    begin
      log('procedure TThread_B.Start(%d); - BUSY', [ThreadID]);
      Exit(false);
    end;
  end;
  result := true;
end;

procedure TThread_B.ResetDone();
begin
  fDoneSignal.ResetEvent;
end;

procedure TThread_B.Execute();
var
  vWR: TWaitResult;
  vTickTock: Cardinal;
  i, vCurrentDataIndex: integer;
  vTmpDataResults: TResultData;
  vTmpDataToProcess: TDataToProcess;
begin
  //
  log('procedure TThread_B.Execute(%d);', [ThreadID]);
  try
    repeat
      fBusy := true;
      fgCriticalSection.Acquire;
      vCurrentDataIndex := fgCurrentDataIndex + 1;
      // check if current is over or equal max count and instant exit the thread if it is
      if vCurrentDataIndex >= fgTotalDataToProcess then
        break;
      log('critical section [%d] processing > %d', [ThreadID, vCurrentDataIndex]);
      fgCurrentDataIndex := vCurrentDataIndex; // inc global
      fgCriticalSection.Release;

      // outside the critical section cuz no one is writing gDataToProcess
      // log('normal section [%d] processing > %d', [ThreadID, vCurrentDataIndex]);
      vTmpDataToProcess := fgDataToProcess[vCurrentDataIndex];

      // Do some work on the data
      vTmpDataResults.ThreadID := ThreadID;
      vTmpDataResults.ThreadHandle := Handle;
      vTickTock := GetTickCount;
      i := Trunc(vTmpDataToProcess.SomeDoubleToMakeItTrouble);
      vTmpDataToProcess.SomeDoubleToMakeItTrouble := 0;
      repeat
        vTmpDataToProcess.SomeDoubleToMakeItTrouble := vTmpDataToProcess.SomeDoubleToMakeItTrouble + ArcTan(i) * Tan(i);
        Dec(i);
        if i < 1 then
          i := 999;
      until GetTickCount - vTickTock > (1000 + Cardinal(RandomRange(500, 1000)));
      if (vTickTock mod 2) = 0 then
      begin
        vTmpDataResults.HazData := true;
        vTmpDataResults.result := Format('[%d] (%d) <%f> "%s"', [ThreadID, Handle, vTmpDataToProcess.SomeDoubleToMakeItTrouble, vTmpDataToProcess.SomeString]);
      end
      else
      begin
        vTmpDataResults.result := 'Yare yare Daze';
      end;
      /// ///////

      // gCriticalSection.Acquire;
      // this is a write but is using vCurrentDataIndex that is local with the value that had when the loop started
      // so this is the only thread that can access to that specific TResultData, also no one read until the whole data is processed
      // so i think theres no need for critical section
      fgDataResults[vCurrentDataIndex] := vTmpDataResults;
      // gCriticalSection.Release;

      fBusy := false;
      fDoneSignal.SetEvent;
      log('Execute waiting [%d]', [ThreadID]);
      repeat
        // feels kinda derp
        vWR := fEvent.WaitFor(10);
        // TWaitResult = (wrSignaled, wrTimeout, wrAbandoned, wrError, wrIOCompletion);
      until (vWR <> wrTimeout) or Terminated or (fgCurrentDataIndex >= fgTotalDataToProcess - 1);
      fEvent.ResetEvent;
    until Terminated or (fgCurrentDataIndex >= fgTotalDataToProcess - 1);
  except
    on E: Exception do
      log('%s%s%s'#13#10, [E.ClassName, ': ', E.Message]);
  end;
  log('Execute done [%d]', [ThreadID]);
  fDoneSignal.SetEvent; // signal to the wait in the main or get locked
end;

end.
