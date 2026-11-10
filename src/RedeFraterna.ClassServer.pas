unit RedeFraterna.ClassServer;

{$mode Delphi}{$H+}
{$codepage UTF8}

interface

uses
  Classes, SysUtils, ZConnection, ZDataset,
  twapi.Types, twapi.TextFileLog, twapi.SQLBuilder,
  twapi.Controller.PoolConn, twapi.Auth, sha1,
  RedeFraterna.Database.Schema, RedeFraterna.Constants;

type

  { TClassRedeFraternaServer }

  TClassRedeFraternaServer = class
  strict private
    class var FInstance: TClassRedeFraternaServer;
  public
    // Método que servirá como callback da autenticação customizada (compatível com TAuthenticationEvent do twapi.Auth)
    function MeuSegundoModoAuth(const AUser: string;
                                const APass: string;
                                const ATenantAlias: string;
                                const AIdSystem: Integer;
                                const ADataBase: string;
                                  out AUserId: Integer;
                                  out AErrorMsg: string;
                                  out ATipoUser: string): Boolean;
    class function GetInstance: TClassRedeFraternaServer;
    class destructor ClassDestroy;
  end;

implementation

{ TClassRedeFraternaServer }

function TClassRedeFraternaServer.MeuSegundoModoAuth(const AUser: string;
                                                     const APass: string;
                                                     const ATenantAlias: string;
                                                     const AIdSystem: Integer;
                                                     const ADataBase: string;
                                                       out AUserId: Integer;
                                                       out AErrorMsg: string;
                                                       out ATipoUser: string): Boolean;
var
  LQryTenant: TZQuery;
  LTargetDB: string;
  LTenantConn: TZConnection;
  LSenhaHash: string;
begin
  Result := False;
  AUserId := 0;
  AErrorMsg := '';
  ATipoUser := 'F';
  LTargetDB := Trim(ADataBase);

  if GConfigEnv.SystemID <> AIdSystem then
  begin
    AErrorMsg := 'Erro de inconsistência';
    Exit(False);
  end;

  if LTargetDB = '' then
  begin
    AErrorMsg := 'TenantAlias desconhecido.';
    Exit(False);
  end;

  try
    // Conecta no banco de dados do cliente/tenant validado pelo LicMan
    LTenantConn := TZeosConnectionPool.GetInstance.Acquire(LTargetDB);
    try
      // Garante que o schema operacional do tenant exista
      TRedeFraternaSchema.EnsureTenantSchema(LTenantConn);

      LSenhaHash := SHA1Print(SHA1String(APass));

      LQryTenant := TZQuery.Create(nil);
      try
        LQryTenant.Connection := LTenantConn;
        LQryTenant.SQL.Text := SQLSelectFrom('usuarios', LTenantConn.Protocol)
          .Fields(['id', 'nome', 'senha_hash', 'tipo', 'ativo', 'centro_id'])
          .Where('UPPER(login) = :login')
          .Build;
        LQryTenant.ParamByName('login').AsString := UpperCase(Trim(AUser));
        LQryTenant.Open;

        if LQryTenant.IsEmpty then
        begin
          AErrorMsg := 'Usuário não encontrado.';
          Exit(False);
        end;

        if not SameText(LQryTenant.FieldByName('ativo').AsString, 'S') then
        begin
          AErrorMsg := 'Usuário inativo no sistema.';
          Exit(False);
        end;

        // Aceita comparação pelo hash SHA1 ou texto plano caso tenha sido inserido manualmente no banco
        if (not SameText(LQryTenant.FieldByName('senha_hash').AsString, LSenhaHash)) and
           (LQryTenant.FieldByName('senha_hash').AsString <> APass) then
        begin
          AErrorMsg := 'Senha incorreta.';
          Exit(False);
        end;

        AUserId   := LQryTenant.FieldByName('id').AsInteger;
        ATipoUser := UpperCase(Trim(LQryTenant.FieldByName('tipo').AsString));
        if (ATipoUser <> 'A') and (ATipoUser <> 'O') and (ATipoUser <> 'F') then
          ATipoUser := 'F';

        if (ATipoUser <> 'A') and (LQryTenant.FieldByName('centro_id').AsInteger <= 0) then
        begin
          AErrorMsg := 'Este usuário não está vinculado a nenhum Centro Espírita. Solicite ao Administrador da UME a vinculação do seu cadastro.';
          Exit(False);
        end;

        Result := True;
      finally
        LQryTenant.Free;
      end;
    finally
      TZeosConnectionPool.GetInstance.Release(LTenantConn);
    end;
  except
    on E: Exception do
    begin
      AErrorMsg := 'Erro ao autenticar no banco de dados: ' + E.Message;
      Result := False;
    end;
  end;
end;

class function TClassRedeFraternaServer.GetInstance: TClassRedeFraternaServer;
begin
  if not Assigned(TClassRedeFraternaServer.FInstance) then
    TClassRedeFraternaServer.FInstance := TClassRedeFraternaServer.Create;
  Result := TClassRedeFraternaServer.FInstance;
end;

class destructor TClassRedeFraternaServer.ClassDestroy;
begin
  if Assigned(TClassRedeFraternaServer.FInstance) then
    FreeAndNil(TClassRedeFraternaServer.FInstance);
end;

end.
