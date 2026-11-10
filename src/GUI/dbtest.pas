unit dbtest;

// Test window, the list in SQLite.

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids,
  Vcl.DBGrids, Vcl.DBCtrls, Data.DB, MemDS, DBAccess, LiteAccess;

type
  /// <summary>Shows a .db list file in a grid.</summary>
  TdbtestForm = class(TForm)
    Connection: TLiteConnection;
    PointsTable: TLiteTable;
    PointsSource: TDataSource;
    PanelButtons: TPanel;
    ButtonOpen: TButton;
    ButtonFromList: TButton;
    ButtonToList: TButton;
    Navigator: TDBNavigator;
    PointsGrid: TDBGrid;
    StatusBar: TStatusBar;
    OpenDialog: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure ButtonOpenClick(Sender: TObject);
    procedure ButtonFromListClick(Sender: TObject);
    procedure ButtonToListClick(Sender: TObject);
    procedure PointsTableChanged(DataSet: TDataSet);
  private
    procedure OpenTable;
    procedure CloseTable;
    function DatabaseChosen: Boolean;
    procedure UpdateStatusBar;
  end;

var
  dbtestForm: TdbtestForm;

implementation

{$R *.dfm}

uses
  PointDictionary, PointDatabase, PointsManagement;

procedure TdbtestForm.FormCreate(Sender: TObject);
begin
  // INTEGER would be read as 32 bits
  PointsTable.DataTypeMap.AddFieldNameRule('PointNumber', ftLargeint);
  // TEXT would be a memo
  PointsTable.DataTypeMap.AddFieldNameRule('Description', ftWideString, 32);
end;

procedure TdbtestForm.ButtonOpenClick(Sender: TObject);
begin
  if not OpenDialog.Execute then
    Exit;
  CloseTable;
  Connection.Database := OpenDialog.FileName;
  OpenTable;
end;

procedure TdbtestForm.ButtonFromListClick(Sender: TObject);
begin
  if not DatabaseChosen then
    Exit;
  CloseTable;
  try
    TPointDatabase.Save(Connection.Database, TPointDictionary.GetInstance);
  finally
    OpenTable;
  end;
end;

procedure TdbtestForm.ButtonToListClick(Sender: TObject);
begin
  if not DatabaseChosen or not PointsManagementForm.AskSaveChanges then
    Exit;
  CloseTable;
  try
    TPointDatabase.Load(Connection.Database, TPointDictionary.GetInstance);
    // The list file lacks these points
    TPointDictionary.GetInstance.Modified := True;
  finally
    OpenTable;
  end;
end;

procedure TdbtestForm.PointsTableChanged(DataSet: TDataSet);
begin
  UpdateStatusBar;
end;

procedure TdbtestForm.OpenTable;
begin
  Connection.Connect;
  PointsTable.Open;
  // Empty text counts as no value
  PointsTable.FieldByName('Description').Required := False;
  UpdateStatusBar;
end;

// TPointDatabase opens its own connection
procedure TdbtestForm.CloseTable;
begin
  if PointsTable.State in dsEditModes then
    PointsTable.Post;
  PointsTable.Close;
  Connection.Disconnect;
end;

function TdbtestForm.DatabaseChosen: Boolean;
begin
  Result := Connection.Database <> '';
  if not Result then
    ShowMessage('Nejdřív otevřete soubor .db.');
end;

procedure TdbtestForm.UpdateStatusBar;
begin
  StatusBar.SimpleText := Format('%s   |   Bodů: %d',
    [Connection.Database, PointsTable.RecordCount]);
end;

end.
