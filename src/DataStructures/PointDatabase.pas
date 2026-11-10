unit PointDatabase;

// Coordinate list in an SQLite database file.

interface

uses
  System.SysUtils, System.Generics.Collections, Data.DB,
  LiteAccess, Point, PointDictionary;

type
  /// <summary>Opens and saves the list as SQLite.</summary>
  TPointDatabase = class
  private
    // Direct mode needs no DLL
    class function OpenConnection(const FileName: string;
      ACreate: Boolean): TLiteConnection; static;
  public
    /// <summary>Reads all points, a bad file keeps the list.</summary>
    class function Load(const FileName: string;
      APoints: TPointDictionary): Integer; static;
    /// <summary>Writes all points in one transaction.</summary>
    class procedure Save(const FileName: string;
      APoints: TPointDictionary); static;
    /// <summary>True for a .db file.</summary>
    class function IsDatabase(const FileName: string): Boolean; static;
  end;

implementation

const
  DATABASE_EXT = '.db';

  // Same limits as Validation
  CREATE_TABLE =
    'CREATE TABLE IF NOT EXISTS Points (' +
    'PointNumber INTEGER PRIMARY KEY NOT NULL ' +
    'CHECK (PointNumber <> 0 AND ' +
    'PointNumber BETWEEN -999999999999999 AND 999999999999999), ' +
    'X REAL NOT NULL DEFAULT 0 CHECK (abs(X) < 1e308), ' +
    'Y REAL NOT NULL DEFAULT 0 CHECK (abs(Y) < 1e308), ' +
    'Z REAL NOT NULL DEFAULT 0 CHECK (abs(Z) < 1e308), ' +
    'Quality INTEGER NOT NULL CHECK (Quality BETWEEN 0 AND 8), ' +
    'Description TEXT NOT NULL DEFAULT '''' ' +
    'CHECK (length(Description) <= 32)) STRICT';

  INSERT_POINT =
    'INSERT INTO Points (PointNumber, X, Y, Z, Quality, Description) ' +
    'VALUES (:PointNumber, :X, :Y, :Z, :Quality, :Description)';

  SELECT_POINTS =
    'SELECT PointNumber, X, Y, Z, Quality, Description ' +
    'FROM Points ORDER BY PointNumber';

class function TPointDatabase.OpenConnection(const FileName: string;
  ACreate: Boolean): TLiteConnection;
begin
  Result := TLiteConnection.Create(nil);
  try
    Result.Options.Direct := True;
    Result.Options.ForceCreateDatabase := ACreate;
    Result.LoginPrompt := False;
    Result.Database := FileName;
    Result.Connect;
  except
    Result.Free;
    raise;
  end;
end;

class function TPointDatabase.Load(const FileName: string;
  APoints: TPointDictionary): Integer;
var
  Connection: TLiteConnection;
  Query: TLiteQuery;
  Loaded: TList<TPoint>;
  P: TPoint;
begin
  // Opening would create it
  if not FileExists(FileName) then
    raise Exception.CreateFmt('Soubor %s neexistuje.', [FileName]);

  Loaded := TList<TPoint>.Create;
  try
    Connection := OpenConnection(FileName, False);
    Query := TLiteQuery.Create(nil);
    try
      Query.Connection := Connection;
      Query.SQL.Text := SELECT_POINTS;
      // INTEGER would be read as 32 bits
      Query.DataTypeMap.AddFieldNameRule('PointNumber', ftLargeint);
      Query.Open;
      while not Query.Eof do
      begin
        Loaded.Add(TPoint.Create(
          Query.FieldByName('PointNumber').AsLargeInt,
          Query.FieldByName('X').AsFloat,
          Query.FieldByName('Y').AsFloat,
          Query.FieldByName('Z').AsFloat,
          Query.FieldByName('Quality').AsInteger,
          Query.FieldByName('Description').AsString));
        Query.Next;
      end;
    finally
      Query.Free;
      Connection.Free;
    end;

    // Read all first, a bad file keeps the list
    APoints.Clear;
    for P in Loaded do
      APoints.AddOrUpdatePoint(P);
    APoints.Modified := False;
    Result := Loaded.Count;
  finally
    Loaded.Free;
  end;
end;

class procedure TPointDatabase.Save(const FileName: string;
  APoints: TPointDictionary);
var
  Connection: TLiteConnection;
  Query: TLiteQuery;
  Key: Int64;
  P: TPoint;
begin
  Connection := OpenConnection(FileName, True);
  Query := TLiteQuery.Create(nil);
  try
    Query.Connection := Connection;
    Query.SQL.Text := CREATE_TABLE;
    Query.Execute;

    // A failed save keeps the file
    Connection.StartTransaction;
    try
      Query.SQL.Text := 'DELETE FROM Points';
      Query.Execute;
      Query.SQL.Text := INSERT_POINT;
      for Key in APoints.SortedNumbers do
      begin
        P := APoints.GetPoint(Key);
        Query.ParamByName('PointNumber').AsLargeInt := P.PointNumber;
        Query.ParamByName('X').AsFloat := P.X;
        Query.ParamByName('Y').AsFloat := P.Y;
        Query.ParamByName('Z').AsFloat := P.Z;
        Query.ParamByName('Quality').AsInteger := P.Quality;
        Query.ParamByName('Description').AsString := string(P.Description);
        Query.Execute;
      end;
      Connection.Commit;
    except
      Connection.Rollback;
      raise;
    end;
  finally
    Query.Free;
    Connection.Free;
  end;
end;

class function TPointDatabase.IsDatabase(const FileName: string): Boolean;
begin
  Result := SameText(ExtractFileExt(FileName), DATABASE_EXT);
end;

end.
