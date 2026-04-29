//unit Unit5;
//
//// Testing playground for TGeoFieldsGrid (Komponenty package).
//// Mirrors TestFieldGrid (TMyFieldsStringGrid + GeoFieldColumn) layout
//// but uses the new TGeoFieldsGrid + GeoFieldsDef.
//
//interface
//
//uses
//  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
//  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
//  Vcl.Grids, Vcl.CheckLst, Vcl.ExtCtrls, Vcl.StdCtrls,
//  GeoGrid,
//  GeoFieldsGrid,
//  GeoFieldsDef;
//
//type
//  TForm5 = class(TForm)
//    PanelLeft: TPanel;
//    LabelFields: TLabel;
//    CheckListFields: TCheckListBox;
//    SplitterLeft: TSplitter;
//    GeoFieldsGrid1: TGeoFieldsGrid;
//    procedure FormCreate(Sender: TObject);
//    procedure CheckListFieldsClickCheck(Sender: TObject);
//  private
//    function BuildGeoFields: TGeoFields;
//  public
//  end;
//
//var
//  Form5: TForm5;
//
//implementation
//
//{$R *.dfm}
//
//procedure TForm5.FormCreate(Sender: TObject);
//var
//  F: TGeoField;
//begin
//  // Fill checklist with display names from global GeoFieldColumnData
//  for F := Low(TGeoField) to High(TGeoField) do
//    CheckListFields.Items.Add(GeoFieldColumnData[F].DisplayName);
//
//  GeoFieldsGrid1.RowCount          := 10;
//  GeoFieldsGrid1.EnterEndBehavior  := ebAddRow;
//  GeoFieldsGrid1.GeoFields         := [];
//end;
//
//function TForm5.BuildGeoFields: TGeoFields;
//var
//  I: Integer;
//begin
//  Result := [];
//  for I := 0 to CheckListFields.Items.Count - 1 do
//    if CheckListFields.Checked[I] then
//      Include(Result, TGeoField(I));
//end;
//
//procedure TForm5.CheckListFieldsClickCheck(Sender: TObject);
//begin
//  GeoFieldsGrid1.GeoFields := BuildGeoFields;
//end;
//
//end.

unit Unit5;

// Testing playground for TGeoFieldsGrid.
// Mirrors the old field-grid test form, but uses
// TGeoFieldsGrid + GeoFieldsDef.

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Grids, Vcl.CheckLst, Vcl.ExtCtrls, Vcl.StdCtrls,
  GeoGrid,
  GeoFieldsGrid,
  GeoFieldsDef;

type
  TForm5 = class(TForm)
    PanelLeft: TPanel;
    LabelFields: TLabel;
    CheckListFields: TCheckListBox;
    SplitterLeft: TSplitter;
    GeoFieldsGrid1: TGeoFieldsGrid;
    procedure FormCreate(Sender: TObject);
    procedure CheckListFieldsClickCheck(Sender: TObject);
  private
    function BuildGeoFields: TGeoFields;
  public
  end;

var
  Form5: TForm5;

implementation

{$R *.dfm}

procedure TForm5.FormCreate(Sender: TObject);
var
  F: TGeoField;
begin
  // Fill checklist with display names from global field definitions
  for F := Low(TGeoField) to High(TGeoField) do
    CheckListFields.Items.Add(GeoFieldColumns[F].DisplayName);

  GeoFieldsGrid1.RowCount := 10;
  GeoFieldsGrid1.EnterEndBehavior := ebAddRow;
  GeoFieldsGrid1.GeoFields := [];
end;

function TForm5.BuildGeoFields: TGeoFields;
var
  I: Integer;
begin
  Result := [];
  for I := 0 to CheckListFields.Items.Count - 1 do
    if CheckListFields.Checked[I] then
      Include(Result, TGeoField(I));
end;

procedure TForm5.CheckListFieldsClickCheck(Sender: TObject);
begin
  GeoFieldsGrid1.GeoFields := BuildGeoFields;
end;

end.
