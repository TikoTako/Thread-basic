unit ThreadUnit;

interface

uses
  System.Math, System.Diagnostics, System.SysUtils, System.Classes;

type
  TTestThread = class(TThread)
  private
    fWaitForMe: integer;
    fSomeResult: string;
    fThreadNumerInArray: integer;
    fSomethingAllocated: Pointer;
  public
    constructor Create(PositionInArray, FakeWorkTime: integer); overload;
    destructor Destroy; override;
  protected
    procedure Execute(); override;
  public
    property SomeResult: string read fSomeResult;
  end;

implementation

uses
  UtilsUnit;

constructor TTestThread.Create(PositionInArray, FakeWorkTime: integer);
begin
  inherited Create(true); // Created suspended
  // do some setup stuff
  log('Thread creation - ID [%d] Handle [%d] ArrayPos [%d]', [ThreadID, Handle, PositionInArray]);
  fWaitForMe := FakeWorkTime * RandomRange(50, 500);
  fThreadNumerInArray := PositionInArray;
  fSomethingAllocated := AllocMem(1024);
  FreeOnTerminate := false;
end;

destructor TTestThread.Destroy;
begin
  log('Thread Destroy - ID [%d] Handle [%d] ArrayPos [%d]', [ThreadID, Handle, fThreadNumerInArray]);
  // Calling the base destructor before cleaning stuff,
  // in case the thread is still running, not sure if correct
  inherited;
  // removing stuff allocated
  if Assigned(fSomethingAllocated) then
    FreeMem(fSomethingAllocated);
end;

procedure TTestThread.Execute();
var
  i: integer;
  vTrouble: double;
  vStopwatch: TStopwatch;
begin
  log('Thread [%d] Execution Start - Handle [%d] ArrayPos [%d] FakeWorkTime [%d]', [ThreadID, Handle, fThreadNumerInArray, fWaitForMe]);
  vTrouble := 0;
  i := 999999;
  vStopwatch := TStopwatch.StartNew;
  repeat
    vTrouble := vTrouble + ArcTan(i) * Tan(i);
    dec(i);
    if i < 0 then
      i := 999999;
  until vStopwatch.ElapsedMilliseconds > fWaitForMe;
  log('Thread [%d] Execution End - Handle [%d] ArrayPos [%d] FakeWorkTime [%d]', [ThreadID, Handle, fThreadNumerInArray, fWaitForMe]);
  fSomeResult := Format('Work done ID [%d] Handle [%d] <%g>', [ThreadID, Handle, vTrouble]);
end;

end.
