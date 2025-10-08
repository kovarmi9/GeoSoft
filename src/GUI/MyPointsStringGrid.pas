unit MyPointsStringGrid;

interface

uses
  System.Classes,
  Vcl.Grids;

type
  TMyPointsStringGrid = class(TStringGrid)
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

constructor TMyPointsStringGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // zatím nic; sem si èasem doplníš defaulty (Options, FixedRows, …)
end;

end.
