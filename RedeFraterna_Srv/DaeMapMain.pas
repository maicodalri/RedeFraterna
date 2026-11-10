unit DaeMapMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DaemonApp;

type
  TDaemonMapperMain = class(TDaemonMapper)
  private

  public

  end;

var
  DaemonMapperMain: TDaemonMapperMain;

implementation

procedure RegisterMapper;
begin
  RegisterDaemonMapper(TDaemonMapperMain);
end;

{$R *.lfm}

initialization
  RegisterMapper;
end.
