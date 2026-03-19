unit Test_FieldGrid;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.CheckLst, Vcl.StdCtrls, Vcl.ExtCtrls,
  GeoRow, GeoDataFrame,
  MyStringGrid, ColumnValidation,
  GeoFieldMeta, GeoFieldsStringGrid;

type
  TForm1 = class(TForm)
    PanelLeft: TPanel;
    LabelFields: TLabel;
    CheckListFields: TCheckListBox;
    SplitterLeft: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure CheckListFieldsClickCheck(Sender: TObject);
  private
    FGrid: TGeoFieldsStringGrid;
    function BuildGeoFields: TGeoFields;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  F: TGeoField;
begin
  // Naplnit CheckListBox vsemi poli v poradi enumu
  for F := Low(TGeoField) to High(TGeoField) do
    CheckListFields.Items.Add(GeoFieldMetaData[F].DisplayName);

  // Grid - programaticky, protoze neni registrovany v IDE
  FGrid := TGeoFieldsStringGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.RowCount := 10;
  FGrid.EnterEndBehavior := ebAddRow;
  FGrid.GeoFields := [];
end;

function TForm1.BuildGeoFields: TGeoFields;
var
  I: Integer;
begin
  Result := [];
  for I := 0 to CheckListFields.Items.Count - 1 do
    if CheckListFields.Checked[I] then
      Include(Result, TGeoField(I));
end;

procedure TForm1.CheckListFieldsClickCheck(Sender: TObject);
begin
  FGrid.GeoFields := BuildGeoFields;
end;

end.
