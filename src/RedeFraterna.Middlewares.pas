unit RedeFraterna.Middlewares;

{$mode Delphi}{$H+}
{$codepage UTF8}

interface

uses
  Classes, SysUtils, twapi.Middlewares;

procedure RegisterAppMiddlewares;

implementation

procedure RegisterAppMiddlewares;
begin
  twapi.Middlewares.RegisterAppMiddlewares;
end;

end.
