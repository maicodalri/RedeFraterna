unit DaeMain;

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses
  Classes, SysUtils, DaemonApp, Horse,
  twapi.Types, RedeFraterna.Core, RedeFraterna.Constants;

type

  { TDaemonMain }

  TDaemonMain = class(TDaemon)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleShutDown(Sender: TCustomDaemon);
    procedure DataModuleStart(Sender: TCustomDaemon; var OK: Boolean);
    procedure DataModuleStop(Sender: TCustomDaemon; var OK: Boolean);
  private

  public

  end;

var
  DaemonMain: TDaemonMain;

implementation

procedure LogService(const AMsg: string);
var
  LFile: string;
  LList: TStringList;
begin
  try
    LFile := ExtractFilePath(ParamStr(0)) + 'RedeFraterna_Srv.log';
    LList := TStringList.Create;
    try
      if FileExists(LFile) then
        LList.LoadFromFile(LFile);
      LList.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' ' + AMsg);
      LList.SaveToFile(LFile);
    finally
      LList.Free;
    end;
  except
  end;
end;

procedure RegisterDaemon;
begin
  RegisterDaemonClass(TDaemonMain);
end;

procedure RunHorse;
begin
  try
    LogService('Iniciando THorse.Listen na porta ' + IntToStr(GConfigEnv.ServerPort) + '...');
    THorse.Listen(GConfigEnv.ServerPort);
    LogService('THorse.Listen iniciado.');
  except
    on E: Exception do
      LogService('ERRO em RunHorse: ' + E.ClassName + ' - ' + E.Message);
  end;
end;

{$R *.lfm}

{ TDaemonMain }

procedure TDaemonMain.DataModuleCreate(Sender: TObject);
begin
  try
    // Garante que o diretório de trabalho seja a pasta do executável,
    // evitando que o Windows Service execute a partir de C:\Windows\System32
    SetCurrentDir(ExtractFilePath(ParamStr(0)));

    // Força UTF-8 para que respostas JSON e templates web trafeguem sem truncamento ANSI
    SetMultiByteConversionCodePage(CP_UTF8);
    SetMultiByteRTLFileSystemCodePage(CP_UTF8);

    LogService('Iniciando RedeFraterna.Core.InitializeServer...');
    InitializeServer;
    LogService('RedeFraterna.Core.InitializeServer concluido com sucesso.');
  except
    on E: Exception do
    begin
      LogService('ERRO FATAL em DataModuleCreate: ' + E.ClassName + ' - ' + E.Message);
      raise;
    end;
  end;
end;

procedure TDaemonMain.DataModuleStart(Sender: TCustomDaemon; var OK: Boolean);
begin
  GConfigEnv.ConfigFileName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + REDEFRATERNA_CONFIG_FILE_NAME;
  GConfigEnv.SystemID       := REDEFRATERNA_ID;

  try
    LogService('Executando DataModuleStart...');
    TThread.CreateAnonymousThread(@RunHorse).Start;
    OK := True;
    LogService('DataModuleStart finalizado com OK=True.');
  except
    on E: Exception do
    begin
      OK := False;
      LogService('ERRO em DataModuleStart: ' + E.ClassName + ' - ' + E.Message);
    end;
  end;
end;

procedure TDaemonMain.DataModuleStop(Sender: TCustomDaemon; var OK: Boolean);
begin
  try
    LogService('Executando DataModuleStop...');
    if THorse.IsRunning then
      THorse.StopListen;
    FinalizeServer;
    OK := True;
    LogService('DataModuleStop finalizado.');
  except
    on E: Exception do
      LogService('ERRO em DataModuleStop: ' + E.ClassName + ' - ' + E.Message);
  end;
end;

procedure TDaemonMain.DataModuleShutDown(Sender: TCustomDaemon);
begin
  try
    LogService('Executando DataModuleShutDown...');
    if THorse.IsRunning then
      THorse.StopListen;
    FinalizeServer;
    LogService('DataModuleShutDown finalizado.');
  except
    on E: Exception do
      LogService('ERRO em DataModuleShutDown: ' + E.ClassName + ' - ' + E.Message);
  end;
end;

initialization
  RegisterDaemon;
end.
