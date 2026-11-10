unit RedeFraterna_Console.Write;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, twapi.TextFileLog;

procedure LogTela(const ALog: string);

implementation

procedure LogTela(const ALog: string);
begin
  WriteLn(ALog);
end;

initialization
  TFileTextLog.OnLog := @LogTela;

end.
