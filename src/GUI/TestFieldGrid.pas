unit TestFieldGrid;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.CheckLst, Vcl.ExtCtrls, Vcl.StdCtrls,
  MyStringGrid, MyFieldsStringGrid, GeoFieldColumn, GeoRow;

type
  TForm2 = class(TForm)
    PanelLeft: TPanel;
    LabelFields: TLabel;
    CheckListFields: TCheckListBox;
    SplitterLeft: TSplitter;
    MyFieldsStringGrid1: TMyFieldsStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure CheckListFieldsClickCheck(Sender: TObject);
  private
    function BuildGeoFields: TGeoFields;
  public
  end;

var
  Form2: TForm2;

implementation

{$R *.dfm}

procedure TForm2.FormCreate(Sender: TObject);
var
  F: TGeoField;
begin
  for F := Low(TGeoField) to High(TGeoField) do
    CheckListFields.Items.Add(GeoFieldColumnData[F].DisplayName);

  MyFieldsStringGrid1.RowCount := 10;
  MyFieldsStringGrid1.EnterEndBehavior := ebAddRow;
  MyFieldsStringGrid1.GeoFields := [];
end;

function TForm2.BuildGeoFields: TGeoFields;
var
  I: Integer;
begin
  Result := [];
  for I := 0 to CheckListFields.Items.Count - 1 do
    if CheckListFields.Checked[I] then
      Include(Result, TGeoField(I));
end;

procedure TForm2.CheckListFieldsClickCheck(Sender: TObject);
begin
  MyFieldsStringGrid1.GeoFields := BuildGeoFields;
end;

end.
