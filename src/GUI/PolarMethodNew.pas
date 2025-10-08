unit PolarMethodNew;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ToolWin,
  Vcl.Grids, Vcl.ExtCtrls,
  BootcampPanel, MyPointsStringGrid;  // <� p�id�no

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
    Button1: TButton;
    Button2: TButton;
    MyPointsStringGrid1: TMyPointsStringGrid;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    FBootPanel: TBootcampPanel;        // <� p�id�no: na�e komponenta
    P: TBootcampPanel;
    FGrid: TMyPointsStringGrid;        // <� p�id�no: na�e komponenta
    Q: TMyPointsStringGrid;
    procedure InitMyGridHeader;     // <� p�id�no
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
  CAP_VOLNE = 'Voln� stanovisko';
  CAP_PEVNE = 'Pevn� stanovisko';

constructor TForm9.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  CheckBox1.OnClick := CheckBox1Click;

  UpdateCheckCaption;

  InitMyGridHeader;   // <� nastav� popisky a velikost gridu

end;

procedure TForm9.UpdateCheckCaption;
begin
  if CheckBox1.Checked then
    CheckBox1.Caption := CAP_PEVNE
  else
    CheckBox1.Caption := CAP_VOLNE;
end;

procedure TForm9.Button1Click(Sender: TObject);
begin
  P := TBootcampPanel.create( Self );
  P.Parent := Self;
  P.SetBounds(50, 50, 300, 100);
end;

procedure TForm9.Button2Click(Sender: TObject);
begin
  Q := TMyPointsStringGrid.create( Self );
  Q.Parent := Self;
  Q.SetBounds(50, 50, 300, 100);
end;

procedure TForm9.CheckBox1Click(Sender: TObject);
begin
  UpdateCheckCaption;
end;

procedure TForm9.InitMyGridHeader;
begin
  with MyPointsStringGrid1 do
  begin
    // z�klad
    FixedRows := 1;             // horn� ��dek = hlavi�ka
    FixedCols := 0;             // rovnou ��sla bod�
    ColCount  := 7;             // 0..7
    RowCount  := 2;             // 0..2
    Options   := Options + [goEditing];

    // texty hlavi�ky (��dek 0, sloupce 0..6)
    Cells[0,0] := '��slo bodu';
    Cells[1,0] := 'V��ka stroje';
    Cells[2,0] := 'X';
    Cells[3,0] := 'Y';
    Cells[4,0] := 'Z';
    Cells[5,0] := 'Kvalita';
    Cells[6,0] := 'Popis';

    Invalidate; // p�ekreslit (tu�n�/centrovan� vykresl� tvoje DrawCell)
  end;
end;


end.
