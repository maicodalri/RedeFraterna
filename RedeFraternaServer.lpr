program RedeFraternaServer;

{$mode Delphi}{$H+}
{$codepage UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  Horse,
  RedeFraterna.Initialize,
  twapi.Types,
  RedeFraterna_Console.Write,
  twapi.TextFileLog,
  RedeFraterna.Core,
  twapi.Auth,
  twapi.Controller,
  twapi.Controller.PoolConn,
  RedeFraterna.Controllers,
  RedeFraterna.ClassServer,
  RedeFraterna.Database.Schema,
  RedeFraterna.Database.Seeds,
  RedeFraterna.Middlewares,
  RedeFraterna.Constants;

begin
  // Garante que o diretório de trabalho seja a pasta do executável
  SetCurrentDir(ExtractFilePath(ParamStr(0)));

  // Força CP_UTF8 globalmente para que strings, JSONs e HTMLs trafeguem em UTF-8 puro
  SetMultiByteConversionCodePage(CP_UTF8);
  SetMultiByteRTLFileSystemCodePage(CP_UTF8);

  InitializeServer;

  WriteLn('============================================================');
  WriteLn('  RedeFraterna - Gestao Integrada de Centros Espiritas [Console/Debug]');
  WriteLn('  Servidor ativo em:    http://localhost:' + IntToStr(GConfigEnv.ServerPort));
  WriteLn('  Login padrao:         admin / admin123');
  if GConfigEnv.Debug then
    WriteLn('  Debug:                On')
  else
    WriteLn('  Debug:                Off');
  WriteLn('  LogLevel:             ' + IntToStr(GConfigEnv.LogLevel));
  WriteLn('  WebFolder:            ' + GConfigEnv.WebFolder);
  WriteLn('  Arq de Configuracao:  ' + GConfigEnv.ConfigFileName);
  WriteLn('  SysID:                ' + IntToStr(GConfigEnv.SystemID));
  WriteLn('============================================================');

  try
    THorse.Listen(GConfigEnv.ServerPort, ServerListen);
  finally
    FinalizeServer;
  end;
end.
