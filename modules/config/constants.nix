{ delib, ... }:
delib.module {
  name = "constants";

  options.constants = with delib; {
    username = readOnly (strOption "kumar");
    userfullname = readOnly (strOption "Kumar Aarav");
    useremail = readOnly (strOption "kumar@kumaraarav.dev");
  };
}
