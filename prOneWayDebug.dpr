program prOneWayDebug;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {MainForm},
  uTools in 'uTools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
