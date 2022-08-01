program Project2;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  WinApi.Windows,
  System.Math, System.SysUtils,
  UtilsUnit in 'UtilsUnit.pas',
  ThreadUnit_B in 'ThreadUnit_B.pas';

var
  i: cardinal;

  vThreadArray: array of TThread_B;
  vWorkDoneSignalHandle: array of THandle;

  vTmpDataToProcess: TDataToProcessArray;

  vRunningThreads, vMaxThreads, vWaitResult: cardinal;

begin
  try
    // Max number of array active at the same time
    vMaxThreads := 3;
    vRunningThreads := vMaxThreads;

    Assert(vMaxThreads > 0, 'Threads must be > 0'#13#10);

    // Generate some whatever dummy data
    SetLength(vTmpDataToProcess, 10);
    for i := Low(vTmpDataToProcess) to High(vTmpDataToProcess) do
    begin
      vTmpDataToProcess[i].SomeDoubleToMakeItTrouble := RandomRange(111, 999);
      vTmpDataToProcess[i].SomeBool := (trunc(vTmpDataToProcess[i].SomeDoubleToMakeItTrouble) mod 2) = 0;
      vTmpDataToProcess[i].SomeString := 'Y halo. This is loop n° ' + i.ToString;
    end;

    Assert(Length(vTmpDataToProcess) > vMaxThreads, 'Data to process must be > threads'#13#10);

    TThread_B.DataToProcess := vTmpDataToProcess;
    SetLength(vTmpDataToProcess, 0);

    // Create the threads
    SetLength(vThreadArray, vMaxThreads);
    SetLength(vWorkDoneSignalHandle, vMaxThreads);
    for i := Low(vThreadArray) to High(vThreadArray) do
    begin
      vThreadArray[i] := TThread_B.Create;
      vWorkDoneSignalHandle[i] := vThreadArray[i].DoneHandle;
    end;

    // loop that start the threads exit when all data is processed
    repeat
      // starting threads
      i := 0;
      if vRunningThreads > 0 then
        repeat
          if (not vThreadArray[i].Finished) and (not vThreadArray[i].isBusy) and (TThread_B.CurrentDataIndex < TThread_B.TotalDataToProcess - 1) then
            vThreadArray[i].Start();
          Inc(i);
        until i >= vMaxThreads;

      // if theres threads running wait for them, one at time
      repeat
        vWaitResult := WaitForMultipleObjects(1, @vWorkDoneSignalHandle[0], false, 0);
        if (vWaitResult >= WAIT_OBJECT_0) and (vWaitResult < (WAIT_OBJECT_0 + vMaxThreads)) then
        begin
          i := vWaitResult - WAIT_OBJECT_0;
          if vThreadArray[i].Finished then
          begin
            log('> Finish [%d]', [vThreadArray[i].ThreadID]);
            Dec(vRunningThreads);
            if vRunningThreads >= 0 then
            begin
              vThreadArray[i].Free;
              delete(vThreadArray, i, 1);
              delete(vWorkDoneSignalHandle, i, 1);
            end;
          end
          else
          begin
            if TThread_B.CurrentDataIndex >= TThread_B.TotalDataToProcess - 1 then
            begin
              i := vWaitResult - WAIT_OBJECT_0;
              log('> LAST DATA [%d]', [vThreadArray[i].ThreadID]);
              Dec(vRunningThreads);
              vThreadArray[i].Free;
              delete(vThreadArray, i, 1);
              delete(vWorkDoneSignalHandle, i, 1);
            end
            else
            begin
              log('> DATA [%d]', [vThreadArray[i].ThreadID]);
              vThreadArray[vWaitResult - WAIT_OBJECT_0].ResetDone;
            end;
          end;
        end
        else if (vWaitResult = WAIT_FAILED) then
        begin
          log('WAIT_FAILED, GetLastError > %d', [GetLastError()]);
        end;
      until (vWaitResult <> WAIT_TIMEOUT) or (vRunningThreads <= 0); // or (gCurrentDataIndex >= gTotalDataToProcess - 1);

    until (vRunningThreads <= 0); // or (gCurrentDataIndex >= gTotalDataToProcess - 1);

    // sleep(100); // to not get log mixed with the destroy n stuff of the threads
    log('All work done');

    for i := Low(TThread_B.DataResults) to High(TThread_B.DataResults) do
      if TThread_B.DataResults[i].HazData then
        log('Thread Worker [%d] Handle [%d] RESULT > %s', [TThread_B.DataResults[i].ThreadID, TThread_B.DataResults[i].ThreadHandle, TThread_B.DataResults[i].Result])
      else
        log('Thread Worker [%d] Handle [%d] ME NO RESULT > %s', [TThread_B.DataResults[i].ThreadID, TThread_B.DataResults[i].ThreadHandle, TThread_B.DataResults[i].Result]);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  PressEnterToExit();

end.
