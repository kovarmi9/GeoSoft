unit AddPoint;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Grids, Vcl.StdCtrls;

type
  TForm6 = class(TForm)
    StringGrid1: TStringGrid;
    StatusBar1: TStatusBar;
    ControlBar1: TControlBar;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    File2: TMenuItem;
    SaveAs1: TMenuItem;
    SaveAs2: TMenuItem;
    Import1: TMenuItem;
    FromTXT1: TMenuItem;
    FromTXT2: TMenuItem;
    FromBinary1: TMenuItem;
    Import2: TMenuItem;
    oTXT1: TMenuItem;
    oTXT2: TMenuItem;
    oBinary1: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Button1: TButton;
    Button2: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form6: TForm6;

implementation

{$R *.dfm}

end.
