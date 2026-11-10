unit RedeFraterna.Core;

{$mode Delphi}{$H+}
{$codepage UTF8}

interface

uses
  Classes, SysUtils, IniFiles, Horse, ZConnection,
  twapi.Types, twapi.TextFileLog, twapi.Controller, twapi.Controller.PoolConn,
  twapi.Auth, twapi.Middlewares,
  RedeFraterna.Constants, RedeFraterna.Database.Schema,
  RedeFraterna.Controllers, RedeFraterna.ClassServer;

procedure EnsureDefaultConfFile;
procedure ServerListen;
procedure IndexPage(Req: THorseRequest; Res: THorseResponse);

// Inicializa middlewares, controllers e rotas REST (compartilhado entre App Console e Windows Service)
procedure InitializeServer;
// Finaliza recursos do servidor
procedure FinalizeServer;

procedure StartServer;
procedure StopServer;

implementation

procedure ServerListen;
begin
  WriteLogFmt('Servidor [UP] na porta [%d]. Horse Version [%s]', [THorse.Port, THorse.Version]);
end;

procedure EnsureDefaultConfFile;
var
  LConfFile: string;
  LIni: TIniFile;
  LSqliteDll: string;
begin
  LConfFile := GConfigEnv.ConfigFileName;
  if Trim(LConfFile) = '' then
    LConfFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + REDEFRATERNA_CONFIG_FILE_NAME;

  LIni := TIniFile.Create(LConfFile);
  try
    if not FileExists(LConfFile) then
    begin
      LSqliteDll := ExtractFilePath(ParamStr(0)) + 'sqlite3.dll';
      if not FileExists(LSqliteDll) then
        LSqliteDll := 'D:\Desenv\Output\RedeFraterna\sqlite3.dll';
      if not FileExists(LSqliteDll) then
        LSqliteDll := 'D:\Desenv\lazarus\EXE\sqlite3.dll';
      if not FileExists(LSqliteDll) then
        LSqliteDll := 'sqlite3.dll';

      LIni.WriteString(SECT_DB_NAME, 'Protocol', 'sqlite');
      LIni.WriteInteger(SECT_DB_NAME, 'Port', 5432);
      LIni.WriteString(SECT_DB_NAME, 'Host', 'localhost');
      LIni.WriteString(SECT_DB_NAME, 'DataBase', 'masterdb.db');
      LIni.WriteString(SECT_DB_NAME, 'User', '');
      LIni.WriteString(SECT_DB_NAME, 'Paswd', '');
      LIni.WriteString(SECT_DB_NAME, 'Lib', LSqliteDll);

      LIni.WriteInteger(SECT_BASE_NAME, SERVER_PORT, 9095);
      LIni.WriteBool(SECT_BASE_NAME, 'Debug', True);
      LIni.WriteInteger(SECT_BASE_NAME, 'LogLevel', 2);
      LIni.WriteString(SECT_BASE_NAME, WEB_FOLDER, 'D:\Desenv\repos\redefraterna\web');
      LIni.WriteString(SECT_BASE_NAME, LICMAN_URL, 'http://localhost:9050');
      LIni.WriteInteger(SECT_BASE_NAME, 'SystemID', REDEFRATERNA_ID);

      LIni.UpdateFile;
    end;
  finally
    LIni.Free;
  end;
end;

procedure IndexPage(Req: THorseRequest; Res: THorseResponse);
var
  LHtmlContent: TStringList;
  LIndexPath: string;
begin
  LIndexPath := IncludeTrailingPathDelimiter(GConfigEnv.WebFolder) + 'index.html';
  if not FileExists(LIndexPath) then
    LIndexPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'web' + PathDelim + 'index.html';

  LHtmlContent := TStringList.Create;
  try
    if FileExists(LIndexPath) then
      LHtmlContent.LoadFromFile(LIndexPath);
    Res.ContentType('text/html; charset=utf-8');
    Res.Send(LHtmlContent.Text);
  finally
    LHtmlContent.Free;
  end;
end;

procedure InitializeServer;
begin
  GConfigEnv.ConfigFileName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + REDEFRATERNA_CONFIG_FILE_NAME;
  GConfigEnv.SystemID := REDEFRATERNA_ID;

  EnsureDefaultConfFile;

  // Registro centralizado dos middlewares (CORS, Servidor Estático Dinâmico, Permissões e Ping)
  RegisterAppMiddlewares;

  WriteLog('Inicializando rotas e controllers do RedeFraterna...');

  // Registra todas as rotas e CRUDs do RedeFraterna
  TRedeFraternaControllers.RegisterAllRoutes;
end;

procedure FinalizeServer;
begin
  TRedeFraternaControllers.FinalizeControllers;
end;

procedure StartServer;
begin
  InitializeServer;
  WriteLog('Iniciando servidor...');
  THorse.Listen(GConfigEnv.ServerPort, ServerListen);
end;

procedure StopServer;
begin
  if THorse.IsRunning then
    THorse.StopListen;
  FinalizeServer;
end;

end.
