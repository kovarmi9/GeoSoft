unit LiteDACTest;

// Test window, the list in SQLite.

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.DBGrids, Vcl.DBCtrls, Data.DB,
  MemDS, DBAccess, LiteAccess, LiteCall, LiteConsts, Vcl.Buttons;

type
  /// <summary>Shows a .db list file in a grid.</summary>
  TLiteDACTestForm = class(TForm)
    Connection: TLiteConnection;
    PointsTable: TLiteTable;
    PointsSource: TDataSource;
    PanelButtons: TPanel;
    ButtonOpen: TButton;
    ButtonFromList: TButton;
    ButtonToList: TButton;
    Navigator: TDBNavigator;
    PointsGrid: TDBGrid;
    OpenDialog: TOpenDialog;
    procedure ButtonOpenClick(Sender: TObject);
    procedure ButtonFromListClick(Sender: TObject);
    procedure ButtonToListClick(Sender: TObject);
  end;

var
  LiteDACTestForm: TLiteDACTestForm;

implementation

{$R *.dfm}

uses
  PointDictionary, PointDatabase, PointsManagement;

procedure TLiteDACTestForm.ButtonOpenClick(Sender: TObject);
begin
  if not OpenDialog.Execute then
    Exit;
  Connection.Disconnect;
  Connection.Database := OpenDialog.FileName;
  PointsTable.Open;
  ButtonFromList.Enabled := True;
  ButtonToList.Enabled := True;
end;

procedure TLiteDACTestForm.ButtonFromListClick(Sender: TObject);
begin
  Connection.Disconnect;
  TPointDatabase.Save(Connection.Database, TPointDictionary.GetInstance);
  PointsTable.Open;
end;

procedure TLiteDACTestForm.ButtonToListClick(Sender: TObject);
begin
  if not PointsManagementForm.AskSaveChanges then
    Exit;
  Connection.Disconnect;
  TPointDatabase.Load(Connection.Database, TPointDictionary.GetInstance);
  // The list file lacks these points
  TPointDictionary.GetInstance.Modified := True;
  PointsTable.Open;
end;

end.
