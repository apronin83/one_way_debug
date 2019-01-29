object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'One way to debug a Telegram Bot API (Ngrok)'
  ClientHeight = 468
  ClientWidth = 497
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  Scaled = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    497
    468)
  PixelsPerInch = 96
  TextHeight = 13
  object lXDebugSessionStart: TLabel
    Left = 121
    Top = 147
    Width = 126
    Height = 13
    Caption = 'XDEBUG_SESSION_START'
  end
  object lNgrokAppPath: TLabel
    Left = 8
    Top = 10
    Width = 53
    Height = 13
    Caption = 'Ngrok path'
  end
  object lBotApiKey: TLabel
    Left = 8
    Top = 37
    Width = 57
    Height = 13
    Caption = 'Bot API Key'
  end
  object btStart: TButton
    Left = 8
    Top = 171
    Width = 121
    Height = 32
    Caption = 'Start Ngrok'
    TabOrder = 0
    OnClick = btStartClick
  end
  object edNgrokAppPath: TEdit
    Left = 72
    Top = 6
    Width = 220
    Height = 21
    TabOrder = 1
  end
  object btSelectNgrokAppPath: TButton
    Left = 292
    Top = 6
    Width = 21
    Height = 21
    Caption = '...'
    TabOrder = 2
    OnClick = btSelectNgrokAppPathClick
  end
  object btStop: TButton
    Left = 135
    Top = 171
    Width = 105
    Height = 32
    Caption = 'Stop Ngrok'
    TabOrder = 3
    OnClick = btStopClick
  end
  object edBotApiKey: TEdit
    Left = 72
    Top = 33
    Width = 241
    Height = 21
    TabOrder = 4
  end
  object seXDebugSessionStart: TSpinEdit
    Left = 252
    Top = 143
    Width = 61
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 5
    Value = 99999
  end
  object chbShowNgrok: TCheckBox
    Left = 320
    Top = 8
    Width = 73
    Height = 17
    Caption = 'Show Ngrok'
    TabOrder = 6
  end
  object gbLocalTelegramBotUrl: TGroupBox
    Left = 8
    Top = 60
    Width = 305
    Height = 77
    Caption = 'Local Telegram Bot Url'
    TabOrder = 7
    object lLocalTelBotHost: TLabel
      Left = 8
      Top = 23
      Width = 22
      Height = 13
      Caption = 'Host'
    end
    object lLocalTelBotPort: TLabel
      Left = 207
      Top = 23
      Width = 20
      Height = 13
      Caption = 'Port'
    end
    object lLocalTelBotPath: TLabel
      Left = 8
      Top = 50
      Width = 22
      Height = 13
      Caption = 'Path'
    end
    object edLocalTelBotHost: TEdit
      Left = 36
      Top = 19
      Width = 165
      Height = 21
      TabOrder = 0
    end
    object seLocalTelBotPort: TSpinEdit
      Left = 233
      Top = 19
      Width = 61
      Height = 22
      MaxValue = 0
      MinValue = 0
      TabOrder = 1
      Value = 99999
    end
    object edLocalTelBotPath: TEdit
      Left = 36
      Top = 46
      Width = 166
      Height = 21
      TabOrder = 2
    end
  end
  object btGetWebhookInfo: TButton
    Left = 320
    Top = 171
    Width = 164
    Height = 32
    Caption = 'Telegram Bot GetWebhookInfo'
    TabOrder = 8
    OnClick = btGetWebhookInfoClick
  end
  object chbUseXDebug: TCheckBox
    Left = 8
    Top = 145
    Width = 81
    Height = 17
    Caption = 'Use XDebug'
    TabOrder = 9
    OnClick = chbUseXDebugClick
  end
  object gbLog: TGroupBox
    Left = 8
    Top = 207
    Width = 481
    Height = 253
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Log'
    TabOrder = 10
    object pnBottom: TPanel
      Left = 2
      Top = 216
      Width = 477
      Height = 35
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
      DesignSize = (
        477
        35)
      object btClear: TButton
        Left = 400
        Top = 4
        Width = 74
        Height = 26
        Anchors = [akTop, akRight]
        Caption = 'Clear'
        TabOrder = 0
        OnClick = btClearClick
      end
    end
    object meLog: TMemo
      AlignWithMargins = True
      Left = 5
      Top = 18
      Width = 471
      Height = 195
      Align = alClient
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 1
    end
  end
  object dlgNgrokPath: TOpenDialog
    FileName = 'C:\SOFT\ngrok\ngrok.exe'
    Filter = 'NGROK|ngrok.exe'
    Left = 136
    Top = 256
  end
  object PipeConsole1: TPipeConsole
    LastError = 0
    OnError = PipeConsole1Error
    OnOutput = PipeConsole1Output
    OnStop = PipeConsole1Stop
    Priority = tpNormal
    Visible = False
    Left = 56
    Top = 256
  end
  object Timer: TTimer
    Interval = 200
    OnTimer = TimerTimer
    Left = 208
    Top = 256
  end
end
