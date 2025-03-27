unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Point, Vcl.StdCtrls,
  Vcl.Grids, Vcl.Mask, Vcl.Menus, Vcl.ToolWin, Vcl.ComCtrls,
  PointsManagement2;

type
  TForm1 = class(TForm)
    ToolBar1: TToolBar;
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    Vytvoitseznam1: TMenuItem;
    Vypocty: TMenuItem;
    Open2: TMenuItem;
    procedure Open2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Open2Click(Sender: TObject);
begin
Form3.Show;
end;

end.
