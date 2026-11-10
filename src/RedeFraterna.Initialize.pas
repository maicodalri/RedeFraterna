unit RedeFraterna.Initialize;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, twapi.Types, RedeFraterna.Constants;

implementation

initialization
  GConfigEnv.ConfigFileName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + REDEFRATERNA_CONFIG_FILE_NAME;
  GConfigEnv.SystemID := REDEFRATERNA_ID;

end.
