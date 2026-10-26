unit Levelling;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CalcBase, Vcl.Menus, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.Grids, GeoGrid, GeoFieldsGrid;

type
  TLevellingForm = class(TCalcBaseForm)
    Grid: TGeoFieldsGrid;
    Splitter1: TSplitter;
    Memo1: TMemo;
  protected
    procedure ApplyDecimals; override;
  end;

var
  LevellingForm: TLevellingForm;

implementation

{$R *.dfm}

uses
  GeoRow;

// Levelling is kept in millimetres, whatever the settings say
procedure TLevellingForm.ApplyDecimals;
begin
  inherited;
  Grid.SetFieldDecimals([Xm, Ym, Zm, SH, Vz, Vy, Z], 3);
end;

end.
