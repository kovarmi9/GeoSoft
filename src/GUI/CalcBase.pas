unit CalcBase;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.ComCtrls;

type
  TCalcBaseForm = class(TForm)
    StatusBar1: TStatusBar;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  CalcBaseForm: TCalcBaseForm;

implementation

{$R *.dfm}

constructor TCalcBaseForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  if StatusBar1.Panels.Count > 0 then
    StatusBar1.Panels[0].Text := GetCurrentDir;
end;

end.
