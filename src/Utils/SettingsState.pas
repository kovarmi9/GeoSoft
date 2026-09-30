unit SettingsState;

// Program settings, for the current run only.

interface

type
  TPolarSettings = record
    ShowTargetHeight: Boolean;  // target height column
    ShowDescription:  Boolean;  // description column
    Congruent:        Boolean;  // else Helmert
  end;

  TSettings = record
    Scale: Double;              // length scale
    Polar: TPolarSettings;
  end;

var
  GSettings: TSettings;

implementation

initialization
  GSettings.Scale := 1.0;
  // GEUS does not ask for it by default
  GSettings.Polar.ShowTargetHeight := False;
  // Shown unless the settings hide it
  GSettings.Polar.ShowDescription  := True;
  // Lengths are reduced by Scale already
  GSettings.Polar.Congruent := True;

end.
