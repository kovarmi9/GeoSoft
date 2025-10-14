unit MyPointsStringGrid;

interface

uses
  System.Classes,
  MyStringGrid;

type
  TMyPointsStringGrid = class(TMyStringGrid)
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

constructor TMyPointsStringGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // zatím nic navíc
end;

end.

