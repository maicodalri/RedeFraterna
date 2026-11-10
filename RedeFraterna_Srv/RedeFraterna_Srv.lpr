Program RedeFraterna_Srv;

{$mode objfpc}{$H+}
{$codepage UTF8}

Uses
{$IFDEF UNIX}{$IFDEF UseCThreads}
  CThreads,
{$ENDIF}{$ENDIF}
  Classes, SysUtils,
  DaemonApp, lazdaemonapp, zcomponent,
  DaeMapMain, DaeMain;

begin
  Application.Initialize;
  Application.Run;
end.
