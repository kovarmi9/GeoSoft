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
    StringGrid1: TStringGrid;
    ToolBar4: TToolBar;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    FBootPanel: TBootcampPanel;        // <� p�id�no: na�e komponenta
    P: TBootcampPanel;
    FGrid: TMyPointsStringGrid;        // <� p�id�no: na�e komponenta
    Q: TMyPointsStringGrid;
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

end.
