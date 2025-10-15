//unit MyPointsStringGrid;
//
//interface
//
//uses
//  System.Classes,
//  MyStringGrid;
//
//type
//  TMyPointsStringGrid = class(TMyStringGrid)
//  public
//    constructor Create(AOwner: TComponent); override;
//  end;
//
//implementation
//
//uses
//  Winapi.Windows; // VK_RETURN
//
//constructor TMyPointsStringGrid.Create(AOwner: TComponent);
//begin
//  inherited Create(AOwner);
//  // zatím nic navíc
//end;
//
//end.
//
unit MyPointsStringGrid;

interface

uses
  System.Classes,
  MyStringGrid; // má TEnterEndBehavior a TMyStringGrid

type
  TMyPointsStringGrid = class(TMyStringGrid)
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

constructor TMyPointsStringGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // na úplném konci: přidej řádek a skoč na jeho první datovou buňku
  EnterEndBehavior := ebAddRow;
end;

end.

