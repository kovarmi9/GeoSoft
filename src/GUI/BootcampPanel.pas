unit BootcampPanel;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls;

type
  TBootcampPanel = class(TPanel)
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{ TBootcampPanel }

constructor TBootcampPanel.Create(AOwner: TComponent);
begin
  inherited;
  Caption    := '';
end;

end.

