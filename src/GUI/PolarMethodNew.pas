unit PolarMethodNew;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ToolWin,
  Vcl.Grids, Vcl.ExtCtrls,
  MyPointsStringGrid, MyStringGrid;  // <— pøidáno

type
  TForm9 = class(TForm)
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    ComboBox4: TComboBox;
    ToolButton3: TToolButton;
    ComboBox5: TComboBox;
    ToolButton2: TToolButton;
    ComboBox6: TComboBox;
    ToolBar3: TToolBar;
    CheckBox1: TCheckBox;
    ToolBar4: TToolBar;
    //MyPointsStringGrid1: TMyPointsStringGrid;
    MyStringGrid1: TMyStringGrid;
  private
    procedure InitMyGridHeader;     // <— pøidáno
    procedure UpdateCheckCaption;
    procedure CheckBox1Click(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  Form9: TForm9;

implementation

{$R *.dfm}

const
  CAP_VOLNE = 'Volné stanovisko';
  CAP_PEVNE = 'Pevné stanovisko';

constructor TForm9.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  CheckBox1.OnClick := CheckBox1Click;

  UpdateCheckCaption;

  InitMyGridHeader;   // <— nastaví popisky a velikost gridu

end;

procedure TForm9.UpdateCheckCaption;
begin
  if CheckBox1.Checked then
    CheckBox1.Caption := CAP_PEVNE
  else
    CheckBox1.Caption := CAP_VOLNE;
end;

procedure TForm9.CheckBox1Click(Sender: TObject);
begin
  UpdateCheckCaption;
end;

procedure TForm9.InitMyGridHeader;
begin
  with MyStringGrid1 do
  begin
    // základ
    FixedRows := 1;             // horní øádek = hlavièka
    FixedCols := 0;             // rovnou èísla bodù
    ColCount  := 7;             // 0..7
    RowCount  := 2;             // 0..2
    Options   := Options + [goEditing];

    // texty hlavièky (øádek 0, sloupce 0..6)
    Cells[0,0] := 'èíslo bodu';
    Cells[1,0] := 'Výška stroje';
    Cells[2,0] := 'X';
    Cells[3,0] := 'Y';
    Cells[4,0] := 'Z';
    Cells[5,0] := 'Kvalita';
    Cells[6,0] := 'Popis';

    Invalidate; // pøekreslit (tuèné/centrované vykreslí tvoje DrawCell)
  end;
end;

end.
