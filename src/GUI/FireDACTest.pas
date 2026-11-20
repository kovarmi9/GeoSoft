unit FireDACTest;

// Test window, the list in SQLite.

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.ExtCtrls, Vcl.StdCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,
  FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, Vcl.DBCtrls, Vcl.Buttons;

type
  /// <summary>Shows a .db list file in a grid.</summary>
  TFireDACTestForm = class(TForm)
    PointsGrid: TDBGrid;
    PanelButtons: TPanel;
    ButtonOpen: TButton;
    ButtonFromList: TButton;
    ButtonToList: TButton;
    Navigator: TDBNavigator;
    OpenDialog: TOpenDialog;
    Connection: TFDConnection;
    PointsTable: TFDTable;
    PointsSource: TDataSource;
    procedure ButtonOpenClick(Sender: TObject);
    procedure ButtonFromListClick(Sender: TObject);
    procedure ButtonToListClick(Sender: TObject);
    procedure PointsTableAfterOpen(DataSet: TDataSet);
  end;

var
  FireDACTestForm: TFireDACTestForm;

implementation

{$R *.dfm}

uses
  PointDictionary, PointDatabase, PointsManagement;

procedure TFireDACTestForm.ButtonOpenClick(Sender: TObject);
begin
  if not OpenDialog.Execute then
    Exit;
  Connection.Close;
  Connection.Params.Database := OpenDialog.FileName;
  PointsTable.Open;
  ButtonFromList.Enabled := True;
  ButtonToList.Enabled := True;
end;

procedure TFireDACTestForm.ButtonFromListClick(Sender: TObject);
begin
  Connection.Close;
  TPointDatabase.Save(Connection.Params.Database,
    TPointDictionary.GetInstance);
  PointsTable.Open;
end;

procedure TFireDACTestForm.ButtonToListClick(Sender: TObject);
begin
  if not PointsManagementForm.AskSaveChanges then
    Exit;
  Connection.Close;
  TPointDatabase.Load(Connection.Params.Database,
    TPointDictionary.GetInstance);
  // The list file lacks these points
  TPointDictionary.GetInstance.Modified := True;
  PointsTable.Open;
end;

procedure TFireDACTestForm.PointsTableAfterOpen(DataSet: TDataSet);
begin
  // The table fills in defaults
  PointsTable.FieldByName('X').Required := False;
  PointsTable.FieldByName('Y').Required := False;
  PointsTable.FieldByName('Z').Required := False;
  PointsTable.FieldByName('Description').Required := False;
end;

end.
