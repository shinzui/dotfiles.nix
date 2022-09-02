{
  system.defaults.NSGlobalDomain = {
    # Configures the trackpad tracking speed (0 to 3). The default is "1"
    "com.apple.trackpad.scaling" = 2.0;
    AppleInterfaceStyleSwitchesAutomatically = true;
    AppleMeasurementUnits = "Centimeters";
    AppleMetricUnits = 1;
    AppleTemperatureUnit = "Celsius";
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
  };

  # Firewall
  system.defaults.alf = {
    globalstate = 0;
    allowsignedenabled = 1;
    allowdownloadsignedenabled = 1;
    stealthenabled = 1;
  };

  # Dock and Mission Control
  system.defaults.dock = {
    autohide = true;
    expose-group-by-app = false;
    mru-spaces = false;
    tilesize = 48;
    show-recents = false;
    # Disable all hot corners
    wvous-bl-corner = 1;
    wvous-br-corner = 1;
    wvous-tl-corner = 1;
    wvous-tr-corner = 1;
  };


  system.defaults.loginwindow = {
    GuestEnabled = false;
  };

  # Spaces
  system.defaults.spaces.spans-displays = false;

  # Trackpad
  system.defaults.trackpad = {
    Clicking = false;
    TrackpadRightClick = true;
    #enable silent clicking
    ActuationStrength = 0;
  };

  # Finder
  system.defaults.finder = {
    FXEnableExtensionChangeWarning = true;
    ShowPathbar = true;
  };
}
