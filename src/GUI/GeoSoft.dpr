program GeoSoft;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Form1},
  PointsManagement2 in 'PointsManagement2.pas' {Form3},
  StringGridValidationUtils in 'StringGridValidationUtils.pas' {$R *.res};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
