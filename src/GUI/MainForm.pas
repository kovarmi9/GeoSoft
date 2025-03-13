unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Point, Vcl.StdCtrls,
  Vcl.Grids, Vcl.Mask, Vcl.Menus, Vcl.ToolWin, Vcl.ComCtrls,
  PointsManagement, PointsManagement2;

type
  TForm1 = class(TForm)
    Button1: TButton;
    ToolBar1: TToolBar;
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    popis1: TMenuItem;
    Vytvoitseznam1: TMenuItem;
    Vytvoitseznam2: TMenuItem;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure popis1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
Form2.Show;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
Form3.Show;
end;

procedure TForm1.popis1Click(Sender: TObject);
begin
Form2.Show;
end;

end.
