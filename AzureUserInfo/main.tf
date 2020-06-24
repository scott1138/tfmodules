data "external" "userinfo" {
  # the \" tells terraform to not treat the " as the end of the string
  # the `\" passes the " to PowerShell and the the ` tells PowerShell not to treat it as the end of a string
  program = ["pwsh","-file","${path.module}/userinfo.ps1"]
}