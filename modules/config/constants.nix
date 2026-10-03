{ delib, homeManagerUser, ... }:
delib.module {
  name = "constants";

  options.constants = with delib; {
    username = readOnly (strOption homeManagerUser);
    userfullname = readOnly (strOption "Kumar Aarav");
    useremail = readOnly (strOption "kumar@kumaraarav.dev");
  };
}
