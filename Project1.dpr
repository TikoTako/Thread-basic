program Project1;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  WinApi.Windows,
  System.SysUtils,
  ThreadUnit_A in 'ThreadUnit_A.pas',
  UtilsUnit in 'UtilsUnit.pas';

var
  i, vLoopCount, vTmpValue, vCurrentThreadsRunningCount, vMaxThreads, vMaxThreadsAtTheSameTime: integer;
  vThreadsArray: array of TTestThread_A;
  vCurrentRunningThreadsHandlesArray: array of THandle;
  vWaitResult, vTmpThreadID: Cardinal;
  vTmpHandle: THandle;

begin
  try
    vMaxThreads := 100;
    vMaxThreadsAtTheSameTime := System.CPUCount;

    // Just in case some derp
    Assert(vMaxThreads > 0, 'vMaxThreads must > 0'#13#10);
    Assert(vMaxThreadsAtTheSameTime > 0, 'vMaxThreadsAtTheSameTime must > 0'#13#10);

    // Creating the threads and populating the array
    log('Creating %d threads...', [vMaxThreads]);
    SetLength(vThreadsArray, vMaxThreads);
    for i := 0 to vMaxThreads - 1 do
      vThreadsArray[i] := TTestThread_A.Create(i, 10);
    logSpace();

    // Executing the threads but only 3 at time

    log('Executing %d threads %d at time.', [vMaxThreads, vMaxThreadsAtTheSameTime]);
    vCurrentThreadsRunningCount := -1;
    vLoopCount := 0;
    repeat
      Inc(vLoopCount);
      log('Staring batch %d', [vLoopCount]);
      i := 0;
      SetLength(vCurrentRunningThreadsHandlesArray, vMaxThreadsAtTheSameTime);
      repeat
        Inc(i);
        Inc(vCurrentThreadsRunningCount);
        Sleep(50); // Some pause for the log
        vThreadsArray[vCurrentThreadsRunningCount].Start;
        Sleep(50); // Some pause for the log
        vCurrentRunningThreadsHandlesArray[i - 1] := vThreadsArray[vCurrentThreadsRunningCount].Handle;
        // log('%d-%d | %d-%d', [i, vMaxThreadsAtTheSameTime, vCurrentThreadsRunningCount, vMaxThreads - 1]);
      until (i = vMaxThreadsAtTheSameTime) or (vCurrentThreadsRunningCount = vMaxThreads - 1);
      SetLength(vCurrentRunningThreadsHandlesArray, i);

      logSpace();
      log('Waiting batch %d', [vLoopCount]);
      // This wait for all the currently running threads, locks the main thread
      // WaitForMultipleObjects(i, @vCurrentRunningThreadsHandlesArray[0], True, INFINITE);

      // This wait for the thread one by one in case need to do stuff meanwhile
      repeat
        vWaitResult := WaitForMultipleObjects(i, @vCurrentRunningThreadsHandlesArray[0], false, INFINITE);
        if (vWaitResult >= WAIT_OBJECT_0) and (vWaitResult < (WAIT_OBJECT_0 + i)) then
        begin
          vTmpValue := vWaitResult - WAIT_OBJECT_0;
          vTmpHandle := vCurrentRunningThreadsHandlesArray[vTmpValue];
          vTmpThreadID := GetThreadId(vCurrentRunningThreadsHandlesArray[vTmpValue]);
          log('WaitForMultipleObjects > end of thread ID [%d] Handle %d', [vTmpThreadID, vTmpHandle]);

          // if Length(vCurrentRunningThreadsHandlesArray) > 1 then
          Delete(vCurrentRunningThreadsHandlesArray, vTmpValue, 1);
          dec(i);
        end
        else if (vWaitResult <= WAIT_ABANDONED_0) and (vWaitResult > (WAIT_ABANDONED_0 + i)) then
        begin
          // vCurrentRunningThreadsHandlesArray[vWaitResult - WAIT_ABANDONED_0] <-
          log('WAIT_ABANDONED_0');
        end
        else if (vWaitResult = WAIT_TIMEOUT) then
        begin
          // timeout
          log('WAIT_TIMEOUT');
        end
        else if (vWaitResult = WAIT_FAILED) then
        begin
          // GetLastError
          log('WAIT_FAILED, GetLastError > %d', [GetLastError()]);
        end;
      until i = 0;

      log('Waiting done.');
      logSpace();
    until vCurrentThreadsRunningCount = vMaxThreads - 1;
    {
      // Executing all the threads at the same time
      log('Executing %d threads at the same time.', [vMaxThreads]);
      for i := 0 to vMaxThreads - 1 do
      vThreadsArray[i].Start;

      // wait until 2 are done, this lock the main thread
      // WaitForMultipleObjects(2, @vThreadsHandlesArray[0], True, INFINITE);
      // or wait until all the threads are done, this lock the main thread
      WaitForMultipleObjects(vMaxThreads, @vThreadsHandlesArray[0], True, INFINITE);
    }

    // Freeing the threads and the array
    log('Getting results...');
    for i := 0 to vMaxThreads - 1 do
      if vThreadsArray[i].Finished then
        log(vThreadsArray[i].SomeResult);
    logSpace();

    // Freeing the threads and the array
    log('Freeing %d threads...', [vMaxThreads]);
    for i := 0 to vMaxThreads - 1 do
    begin
      if vThreadsArray[i].Started and not vThreadsArray[i].Finished then
      begin
        TerminateThread(vThreadsArray[i].Handle, 0);
        log('Thread [%d] has been terminated because was still running.', [vThreadsArray[i].ThreadID]);
      end;
      vThreadsArray[i].Free;
    end;

    SetLength(vCurrentRunningThreadsHandlesArray, 0);
    SetLength(vThreadsArray, 0);
    logSpace();
  except
    on E: Exception do
      log('Exception%s%s %s %s', [#13#10, E.ClassName, #13#10, E.Message]);
  end;
  PressEnterToExit();

end.
