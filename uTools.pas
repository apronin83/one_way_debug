unit uTools;

interface

uses
  System.Classes, System.SysUtils, Winapi.ActiveX, Vcl.Forms, SHDocVw,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  IdMultipartFormData, IdSSLOpenSSL;

function SubstituteText(AString, AFindText, AInsertText: String): String;
function DeleteText(AString: String; ADeleteString: String): String;
function GetStringList(AString: String): TStringList;
function CutTextBetween(AString: String; const ADelimit1, ADelimit2: String): String;
function ParseCommandParameters(ACommandText: String): TStringList;
function GetStringFromStream(AStream: TStream; AEncoding: TEncoding): String;

function GetWebBrowserHTML(AUrl: String): String;
procedure WaitForBrowser(WB: TWebBrowser);
function HttpGet(AUrl: String; out AResponseCode: Integer; out AResponse: String; out AErrorMessage: String): Boolean;
function HttpPostMultiPart(AUrl: String; AParams: TStringList): String;

implementation

function SubstituteText(AString, AFindText, AInsertText: String): String;
begin
  Result := StringReplace(AString, AFindText, AInsertText, [rfReplaceAll, rfIgnoreCase]);
end;

function DeleteText(AString: String; ADeleteString: String): String;
begin
  Result := SubstituteText(AString, ADeleteString, '');
end;

function GetStringList(AString: String): TStringList;
begin
  Result := TStringList.Create;
  Result.Text := AString;
end;

function CutTextBetween(AString: String; const ADelimit1, ADelimit2: String): String;
var
  PD1, PD2: Integer;
begin
  PD1 := Pos(ADelimit1, AString) + Length(ADelimit1);
  PD2 := Pos(ADelimit2, AString);

  Result := Copy(AString, PD1, PD2 - PD1);
end;

function ParseCommandParam(P: PChar; var Param: string): PChar;
var
  i, Len: Integer;
  Start, S: PChar;
begin
  // U-OK
  while True do
  begin
    while (P[0] <> #0) and (P[0] <= ' ') do
      Inc(P);
    if (P[0] = '"') and (P[1] = '"') then Inc(P, 2) else Break;
  end;
  Len := 0;
  Start := P;
  while P[0] > ' ' do
  begin
    if P[0] = '"' then
    begin
      Inc(P);
      while (P[0] <> #0) and (P[0] <> '"') do
      begin
        Inc(Len);
        Inc(P);
      end;
      if P[0] <> #0 then
        Inc(P);
    end
    else
    begin
      Inc(Len);
      Inc(P);
    end;
  end;

  SetLength(Param, Len);

  P := Start;
  S := Pointer(Param);
  i := 0;
  while P[0] > ' ' do
  begin
    if P[0] = '"' then
    begin
      Inc(P);
      while (P[0] <> #0) and (P[0] <> '"') do
      begin
        S[i] := P^;
        Inc(P);
        Inc(i);
      end;
      if P[0] <> #0 then Inc(P);
    end
    else
    begin
      S[i] := P^;
      Inc(P);
      Inc(i);
    end;
  end;

  Result := P;
end;

function ParseCommandParameters(ACommandText: String): TStringList;
var
  Parameters: PWideChar;
  Param: String;
begin
  Parameters := PWideChar(ACommandText);

  Result := TStringList.Create;

  while True do
    begin
      Parameters := ParseCommandParam(Parameters, Param);

      if Param = '' then Break;

      Result.Add(Param);
    end;
end;

function GetStringFromStream(AStream: TStream; AEncoding: TEncoding): String;
var
  SS: TStringStream;
begin
  SS := TStringStream.Create('', AEncoding); // TEncoding.Default
  try
    AStream.Seek(0, soBeginning);
    SS.CopyFrom(AStream, AStream.Size);
    SS.Seek(0, soBeginning);
    Result := SS.DataString;
  finally
    FreeAndNil(SS);
  end;
end;

function GetWebBrowserHTML(AUrl: String): String;
var
  LStream: TStringStream;
  Stream: IStream;
  LPersistStreamInit: IPersistStreamInit;
  WB: TWebBrowser;
begin
  WB := TWebBrowser.Create(nil);
  try
    WB.Silent := True;

    WB.Navigate(AUrl);

    WaitForBrowser(WB);

    if Assigned(WB.Document) then
      begin
        LStream := TStringStream.Create('');
        try
          LPersistStreamInit := WB.Document as IPersistStreamInit;
          Stream := TStreamAdapter.Create(LStream, soReference);
          LPersistStreamInit.Save(Stream, True);
          Result := LStream.DataString;
        finally
          LStream.Free;
        end;
      end;
  finally
    FreeAndNil(WB);
  end;
end;

procedure WaitForBrowser(WB: TWebBrowser);
begin
  while WB.Busy and not Application.Terminated do
  begin
    Application.ProcessMessages;
    Sleep(100);
  end;
end;

function HttpGet(AUrl: String; out AResponseCode: Integer; out AResponse: String; out AErrorMessage: String): Boolean;
var
  i: Integer;
  data: TIdMultiPartFormDataStream;
  http: TIdHttp;
begin
  AResponse := '';
  AErrorMessage := '';

  http := TIdHttp.Create(nil);
  try
    http.ReadTimeout := 60000; // 60000 ms = 1 min

    http.Request.CacheControl := 'no-cache';

    http.HTTPOptions := [hoKeepOrigProtocol,
                         hoNoProtocolErrorException,
                         hoWantProtocolErrorContent];

    AResponse := http.Get(AUrl);

    AResponseCode := http.Response.ResponseCode;

    Result := (AResponseCode = 200);

    if not Result then
      AErrorMessage := http.Response.ResponseText;
  finally
    FreeAndNil(http);
  end;
end;

function HttpPostMultiPart(AUrl: String; AParams: TStringList): String;
var
  i: Integer;
  data: TIdMultiPartFormDataStream;
  http: TIdHttp;
begin
  http := TIdHttp.Create(nil);
  try
    data := TIdMultiPartFormDataStream.Create;
    try
      for i := 0 to AParams.Count-1 do
        data.AddFormField(AParams.KeyNames[i], AParams.Values[AParams.KeyNames[i]]);

      http.ReadTimeout := 60000; // 60000 ms = 1 min

      http.Request.CacheControl := 'no-cache';

      http.HTTPOptions := [hoKeepOrigProtocol,
                           hoNoProtocolErrorException,
                           hoWantProtocolErrorContent];

      Result := http.Post(AUrl, data);
    finally
      FreeAndNil(data);
    end;
  finally
    FreeAndNil(http);
  end;
end;

end.
