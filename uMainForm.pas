﻿unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils,
  System.Variants, System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IniFiles, Pipes, Vcl.Samples.Spin,
  Vcl.ExtCtrls,

  uTools;

type
  TMainForm = class(TForm)
    btStart: TButton;
    lXDebugSessionStart: TLabel;
    lNgrokAppPath: TLabel;
    edNgrokAppPath: TEdit;
    btSelectNgrokAppPath: TButton;
    dlgNgrokPath: TOpenDialog;
    PipeConsole: TPipeConsole;
    btStop: TButton;
    lBotApiKey: TLabel;
    edBotApiKey: TEdit;
    seXDebugSessionStart: TSpinEdit;
    Timer: TTimer;
    chbShowNgrok: TCheckBox;
    gbLocalTelegramBotUrl: TGroupBox;
    edLocalTelBotHost: TEdit;
    lLocalTelBotHost: TLabel;
    seLocalTelBotPort: TSpinEdit;
    lLocalTelBotPort: TLabel;
    lLocalTelBotPath: TLabel;
    edLocalTelBotPath: TEdit;
    btGetWebhookInfo: TButton;
    chbUseXDebug: TCheckBox;
    gbLog: TGroupBox;
    pnBottom: TPanel;
    btClear: TButton;
    meLog: TMemo;
    lUrl: TLabel;
    procedure btStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btSelectNgrokAppPathClick(Sender: TObject);
    procedure PipeConsoleOutput(Sender: TObject; Stream: TStream);
    procedure PipeConsoleStop(Sender: TObject; ExitValue: Cardinal);
    procedure PipeConsoleError(Sender: TObject; Stream: TStream);
    procedure btStopClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure chbUseXDebugClick(Sender: TObject);
    procedure btGetWebhookInfoClick(Sender: TObject);
    procedure btClearClick(Sender: TObject);
    procedure lUrlClick(Sender: TObject);
    procedure lUrlMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure lUrlMouseLeave(Sender: TObject);
  private
    FAppPath: String;

    FIni: TIniFile;

    FNgrokApp: String;
    FNgrokAppPath: String;
    FRunCmdTemplate: String;
    FTelegramBotApiKey: String;
    FLocalTelegramBotHost: String;
    FLocalTelegramBotPort: Integer;
    FLocalTelegramBotPath: String;
    FUseXDebug: Boolean;
    FXDebugSessionStart: Integer;
    FVisibleShowNgrok: Boolean;
    FShowNgrok: Boolean;

    FStartCorrect: Boolean;

    procedure LoadParams;
    procedure GetCurrentParams;
    procedure SaveCurrentParams;
    procedure InitControls;

    function GetNgrokServerUrl: String;
  public
    { Public declarations }
  end;

  // Проверить соответствие кодов, тем кодам которые возвращаются вызываемыми программами
  TExitCodes = (ecSuccess              = 0,
                ecSignToolNotInPath    = 1,
                ecAssemblyDirectoryBad = 2,
                ecPFXFilePathBad       = 4,
                ecPasswordMissing      = 8,
                ecSignFailed           = 16,
                ecUnknownError         = 32);

  function GetExitCodes(AExitCode: Cardinal): String;

var
  LogSeparator: String;
  MainForm: TMainForm;

implementation

{$R *.dfm}

function GetExitCodes(AExitCode: Cardinal): String;
begin
  Result := 'ExitCodeNoRegistered';

  case TExitCodes(AExitCode) of
  ecSuccess             : Result := 'Success';
  ecSignToolNotInPath   : Result := 'SignToolNotInPath';
  ecAssemblyDirectoryBad: Result := 'AssemblyDirectoryBad';
  ecPFXFilePathBad      : Result := 'PFXFilePathBad';
  ecPasswordMissing     : Result := 'PasswordMissing';
  ecSignFailed          : Result := 'SignFailed';
  ecUnknownError        : Result := 'UnknownError';
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  LogSeparator := LogSeparator.PadLeft(100, '-');

  FAppPath := ExtractFilePath(ParamStr(0));

  FIni := TIniFile.Create(FAppPath + 'setting.ini');

  LoadParams;

  InitControls;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  btStopClick(Self);

  FreeAndNil(FIni);
end;

procedure TMainForm.btSelectNgrokAppPathClick(Sender: TObject);
begin
  if not dlgNgrokPath.Execute then Exit;

  FNgrokAppPath := dlgNgrokPath.FileName;

  edNgrokAppPath.Text := FNgrokAppPath;
end;

procedure TMainForm.LoadParams;
var
  i: Integer;
  FindPaths, TestPath: String;
  SL: TStringList;
begin
  FNgrokApp             := FIni.ReadString('MAIN', 'NGROK', 'ngrok.exe');
  FNgrokAppPath         := FIni.ReadString('MAIN', 'NGROK_PATH', '');
  FRunCmdTemplate       := FIni.ReadString('MAIN', 'RUN_CMD_TEMPLATE', '{NGROK} http {LOCAL_TELEGRAM_BOT_HOST}:{LOCAL_TELEGRAM_BOT_PORT}');
  FTelegramBotApiKey    := FIni.ReadString('MAIN', 'TELEGRAM_BOT_API_KEY', '');
  FLocalTelegramBotHost := FIni.ReadString('MAIN', 'LOCAL_TELEGRAM_BOT_HOST', '');
  FLocalTelegramBotPort := FIni.ReadInteger('MAIN', 'LOCAL_TELEGRAM_BOT_PORT', 80);
  FLocalTelegramBotPath := FIni.ReadString('MAIN', 'LOCAL_TELEGRAM_BOT_PATH', '');
  FUseXDebug            := FIni.ReadBool('MAIN', 'XDEBUG_USE', False);
  FXDebugSessionStart   := FIni.ReadInteger('MAIN', 'XDEBUG_SESSION_START', 0);
  FVisibleShowNgrok     := FIni.ReadBool('MAIN', 'VISIBLE_SHOW_CONSOLE_APP', False);
  FShowNgrok            := FIni.ReadBool('MAIN', 'SHOW_CONSOLE_APP', False);

  if FNgrokAppPath.Trim.IsEmpty then
    begin
      FindPaths := FAppPath + CRLF + StringReplace(GetEnvironmentVariable('PATH'), ';', #13#10, [rfReplaceAll]);

      SL := TStringList.Create;
      try
        SL.Text := FindPaths;

        SL.Insert(0, FAppPath);

        for i := 0 to SL.Count-1 do
          begin
            TestPath := SL[i];

            if System.SysUtils.DirectoryExists(TestPath) then
              begin
                TestPath := IncludeTrailingPathDelimiter(TestPath);

                if FileExists(TestPath + FNgrokApp) then
                  begin
                    FNgrokAppPath := TestPath + FNgrokApp;
                    Break;
                  end;
              end;
          end;
      finally
        FreeAndNil(SL);
      end;
    end;
end;

procedure TMainForm.lUrlMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  lUrl.Font.Style := lUrl.Font.Style + [fsUnderline];
end;

procedure TMainForm.lUrlMouseLeave(Sender: TObject);
begin
  lUrl.Font.Style := lUrl.Font.Style - [fsUnderline];
end;

procedure TMainForm.lUrlClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar('https://github.com/apronin83/one_way_debug'), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.InitControls;
begin
  edNgrokAppPath.Text := FNgrokAppPath;
  edBotApiKey.Text := FTelegramBotApiKey;
  edLocalTelBotHost.Text := FLocalTelegramBotHost;
  seLocalTelBotPort.Value := FLocalTelegramBotPort;
  edLocalTelBotPath.Text := FLocalTelegramBotPath;
  chbUseXDebug.Checked := FUseXDebug;
  seXDebugSessionStart.Value := FXDebugSessionStart;
  chbShowNgrok.Visible := FVisibleShowNgrok;
  chbShowNgrok.Checked := FVisibleShowNgrok and FShowNgrok;

  btStart.Enabled := False;
  btStop.Enabled := False;

  chbUseXDebugClick(Self);
end;

procedure TMainForm.GetCurrentParams;
begin
  FNgrokAppPath := edNgrokAppPath.Text;
  FTelegramBotApiKey := edBotApiKey.Text;
  FLocalTelegramBotHost := edLocalTelBotHost.Text;
  FLocalTelegramBotPort := seLocalTelBotPort.Value;
  FLocalTelegramBotPath := edLocalTelBotPath.Text;
  FUseXDebug := chbUseXDebug.Checked;
  FXDebugSessionStart := seXDebugSessionStart.Value;
  FShowNgrok := chbShowNgrok.Checked;
end;

procedure TMainForm.SaveCurrentParams;
begin
  FIni.WriteString('MAIN', 'NGROK', FNgrokApp);
  FIni.WriteString('MAIN', 'NGROK_PATH', FNgrokAppPath);
  FIni.WriteString('MAIN', 'RUN_CMD_TEMPLATE', FRunCmdTemplate);
  FIni.WriteString('MAIN', 'TELEGRAM_BOT_API_KEY', FTelegramBotApiKey);
  FIni.WriteString('MAIN', 'LOCAL_TELEGRAM_BOT_HOST', FLocalTelegramBotHost);
  FIni.WriteInteger('MAIN','LOCAL_TELEGRAM_BOT_PORT', FLocalTelegramBotPort);
  FIni.WriteString('MAIN', 'LOCAL_TELEGRAM_BOT_PATH', FLocalTelegramBotPath);
  FIni.WriteBool('MAIN', 'XDEBUG_USE', FUseXDebug);
  FIni.WriteInteger('MAIN', 'XDEBUG_SESSION_START', FXDebugSessionStart);
  FIni.WriteBool('MAIN', 'SHOW_CONSOLE_APP', FShowNgrok);

  FIni.UpdateFile;
end;

function TMainForm.GetNgrokServerUrl: String;
var
  Content: String;
begin
  Content := GetWebBrowserHTML('http://localhost:4040/status');

  Result := CutTextBetween(Content, '\"command_line\":{\"URL\":\"', '\",\"Proto\":\"https');
end;

procedure TMainForm.btStartClick(Sender: TObject);
var
  Res: Boolean;
  RunCmdString: String;
  CommandList: TStringList;
  NgrokServerUrl: String;
  RegisterHookUrl: String;
  PostParams: TStringList;
  TelBotApiRegUrl: String;
  Response: String;
begin
  FStartCorrect := False;

  GetCurrentParams;

  FLocalTelegramBotHost := DeleteText(DeleteText(FLocalTelegramBotHost, 'http://'), 'https://');
  FLocalTelegramBotHost := FLocalTelegramBotHost.Trim(['/']);
  FLocalTelegramBotPath := FLocalTelegramBotPath.Trim(['/']);

  if not FileExists(FNgrokAppPath) then
    begin
      ShowMessageFmt('Specify the location of the file "%s"', [FNgrokApp]);
      Exit;
    end;

  PipeConsole.Visible := FShowNgrok;

  RunCmdString := SubstituteText(FRunCmdTemplate, '{NGROK}', FNgrokApp);
  RunCmdString := SubstituteText(RunCmdString, '{LOCAL_TELEGRAM_BOT_HOST}', FLocalTelegramBotHost);
  RunCmdString := SubstituteText(RunCmdString, '{LOCAL_TELEGRAM_BOT_PORT}', IntToStr(FLocalTelegramBotPort));
  RunCmdString := SubstituteText(RunCmdString, '{LOCAL_TELEGRAM_BOT_PATH}', FLocalTelegramBotPath);
  RunCmdString := SubstituteText(RunCmdString, '{XDEBUG_SESSION_START}', IntToStr(FXDebugSessionStart));

  meLog.Lines.Add(LogSeparator);
  meLog.Lines.Add('Run commands:');
  meLog.Lines.Add(RunCmdString);
  meLog.Lines.Add('Wait...');

  CommandList := ParseCommandParameters(RunCmdString);
  try
    CommandList.LineBreak := ' ';

    Res := PipeConsole.Start(FNgrokAppPath, CommandList.Text);

    if Res then
      begin
        Sleep(3000); // NGROK server initialization timeout

        NgrokServerUrl := GetNgrokServerUrl;

        meLog.Lines.Add('Generate server:');
        meLog.Lines.Add(NgrokServerUrl);

        // POST Register NgrokServerUrl in Bot API
        RegisterHookUrl := Format('%s/%s', [NgrokServerUrl, FLocalTelegramBotHost]);

        // Add Path
        if not FLocalTelegramBotPath.Trim.IsEmpty then
          RegisterHookUrl := Format('%s/%s', [RegisterHookUrl, FLocalTelegramBotPath]);

        // Add XDebug info
        if FUseXDebug then
          RegisterHookUrl := Format('%s?XDEBUG_SESSION_START=%d', [RegisterHookUrl, FXDebugSessionStart]);

        //https://xxxxxxxx.ngrok.io/yourdomain.loc/webhookhandler.php?XDEBUG_SESSION_START=XXXXX
        meLog.Lines.Add('Param "url" for setWebhook (Telegram Bot API):');
        meLog.Lines.Add(RegisterHookUrl);

        PostParams := GetStringList('');
        try
          TelBotApiRegUrl := Format('https://api.telegram.org/bot%s/setwebhook?url=%s', [FTelegramBotApiKey, RegisterHookUrl]);

          meLog.Lines.Add('Registration request:');
          meLog.Lines.Add(TelBotApiRegUrl);
          meLog.Lines.Add('Wait... (max 30 sec)');

          Res := HttpPostMultiPart(TelBotApiRegUrl, PostParams, Response);

          if Res then
            begin
              meLog.Lines.Add('Registration response:');
              meLog.Lines.Add(Response);
              meLog.Lines.Add('Status: Registration Successful');

              FStartCorrect := True;
            end;
        finally
          FreeAndNil(PostParams);
        end;
      end;

    if not Res then
      begin
        PipeConsole.Stop(0);

        meLog.Lines.Add('Status: Registration failed');

        ShowMessageFmt('Application error.' + #13#10 + '"%s"', [FNgrokApp]);
        Exit;
      end;
  finally
    FreeAndNil(CommandList);
  end;

  SaveCurrentParams;
end;

procedure TMainForm.btStopClick(Sender: TObject);
begin
  PipeConsole.Stop(0);
end;

procedure TMainForm.btClearClick(Sender: TObject);
begin
  meLog.Clear;
end;

procedure TMainForm.btGetWebhookInfoClick(Sender: TObject);
var
  ResponseCode: Integer;
  CheckUrl, Response, ErrorMessage: String;
begin
  GetCurrentParams;

   if FTelegramBotApiKey.Trim.IsEmpty then
    begin
      ShowMessage('Input Tekegram Bot API Key');
      Exit;
    end;

  CheckUrl := Format('https://api.telegram.org/bot%s/getWebhookInfo', [FTelegramBotApiKey]);

  meLog.Lines.Add(LogSeparator);
  meLog.Lines.Add('Check request:');
  meLog.Lines.Add(CheckUrl);
  meLog.Lines.Add('Wait... (max 30 sec)');

  if HttpGet(CheckUrl, ResponseCode, Response, ErrorMessage) then
    begin
      meLog.Lines.Add('Check response code: 200 (OK)');
      meLog.Lines.Add('Check response:');
      meLog.Lines.Add(Response);
    end
  else
    begin
      meLog.Lines.Add(Format('Check response code: %d (BAD)', [ResponseCode]));
      meLog.Lines.Add('Check response:');
      meLog.Lines.Add(Response);
      meLog.Lines.Add('Check response error:');
      meLog.Lines.Add(ErrorMessage);
    end;

  SaveCurrentParams;
end;

procedure TMainForm.chbUseXDebugClick(Sender: TObject);
begin
  lXDebugSessionStart.Enabled := chbUseXDebug.Checked;
  seXDebugSessionStart.Enabled := chbUseXDebug.Checked;
end;

procedure TMainForm.TimerTimer(Sender: TObject);
begin
  btStart.Enabled := not PipeConsole.Running;

  btStop.Enabled := FStartCorrect and (not btStart.Enabled);
end;

procedure TMainForm.PipeConsoleError(Sender: TObject; Stream: TStream);
begin
  meLog.Lines.Add(LogSeparator);
  meLog.Lines.Add(Format('Error application "%s":', [FNgrokApp]));
  meLog.Lines.Add(GetStringFromStream(Stream, TEncoding.Default));
end;

procedure TMainForm.PipeConsoleOutput(Sender: TObject; Stream: TStream);
begin
  meLog.Lines.Add(LogSeparator);
  meLog.Lines.Add(Format('Output application "%s":', [FNgrokApp]));
  meLog.Lines.Add(GetStringFromStream(Stream, TEncoding.Default));
end;

procedure TMainForm.PipeConsoleStop(Sender: TObject; ExitValue: Cardinal);
begin
  meLog.Lines.Add(LogSeparator);
  meLog.Lines.Add(Format('Stop application "%s"', [FNgrokApp]));
  meLog.Lines.Add(Format('Exit code: %d (%s)', [Trunc(ExitValue), GetExitCodes(ExitValue)]));
end;

end.
