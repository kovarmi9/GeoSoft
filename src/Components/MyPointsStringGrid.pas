unit MyPointsStringGrid;

interface

uses
  System.Classes,
  MyStringGrid; // má TMyStringGrid a TEnterEndBehavior

type
  TMyPointsStringGrid = class(TMyStringGrid)
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  Winapi.Windows; // VK_RETURN

constructor TMyPointsStringGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Na úplném konci: přidá řádek a skočí na jeho první datovou buňku
  EnterEndBehavior := ebAddRow;
end;

end.

