program GeoSoft;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {Form1},
  PointsManagement in 'PointsManagement.pas' {Form3},
  PolarMethod in 'PolarMethod.pas' {Form2},
  StringGridValidationUtils in 'StringGridValidationUtils.pas' {$R *.res};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
