unit SettingsState;

// Program settings, for the current run only.

interface

type
  TPolarSettings = record
    ShowTargetHeight: Boolean;  // target height column
    ShowDescription:  Boolean;  // description column
    Congruent:        Boolean;  // else Helmert
  end;

  // Place the scale was determined for, as typed
  TScalePlace = record
    PointNumber: string;
    Y, X, Height: string;
  end;

  // Job protocol (.ptk): every run, by the button, or none
  TProtocolMode = (pmAll, pmManual, pmOff);

  TSettings = record
    Scale: Double;              // length scale
    ScalePlace: TScalePlace;
    LengthDecimals: Integer;    // shown places of lengths and coordinates
    AngleDecimals: Integer;     // shown places of angles
    AreaDecimals: Integer;      // shown places of areas
    Polar: TPolarSettings;
    ProtocolMode: TProtocolMode;
  end;

var
  GSettings: TSettings;

implementation

initialization
  GSettings.Scale := 1.0;
  // KN uses 2 places, angles in gon 4 places
  GSettings.LengthDecimals := 2;
  GSettings.AngleDecimals := 4;
  // Whole square metres as in the cadastre
  GSettings.AreaDecimals := 0;
  // Not asked for by default
  GSettings.Polar.ShowTargetHeight := False;
  // Shown unless the settings hide it
  GSettings.Polar.ShowDescription  := True;
  // Lengths are reduced by Scale already
  GSettings.Polar.Congruent := True;
  // Nothing computed is forgotten
  GSettings.ProtocolMode := pmAll;

end.
