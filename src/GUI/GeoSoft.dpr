program GeoSoft;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Form1},
  PointsManagement in 'PointsManagement.pas' {Form2},
  PointsManagement2 in 'PointsManagement2.pas' {Form3},
  StringGridValidationUtils in 'StringGridValidationUtils.pas' {$R *.res},
  PointsManagement3 in 'PointsManagement3.pas' {Form4};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TForm4, Form4);
  Application.Run;
end.
