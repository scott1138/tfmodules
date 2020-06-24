locals {
  images = {
    "ImageAbbreviation"    = ["Publisher", "Offer", "Sku"]
    "UBUNTU16"             = ["Canonical", "UbuntuServer", "16.04-LTS", "Linux"]
    "UBUNTU18"             = ["Canonical", "UbuntuServer", "18.04-LTS", "Linux"]
    "WS2019"               = ["MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter", "Windows"]
    "WS2019-CORE"          = ["MicrosoftWindowsServer", "WindowsServer", "2019-Datacenter-Core", "Windows"]
    "WS2016"               = ["MicrosoftWindowsServer", "WindowsServer", "2016-Datacenter", "Windows"]
    "WS2016-CORE"          = ["MicrosoftWindowsServer", "WindowsServer", "2016-Datacenter-Core", "Windows"]
    "WS2012R2"             = ["MicrosoftWindowsServer", "WindowsServer", "2012-R2-Datacenter", "Windows"]
    "SQL2016SP2STD-WS2016" = ["MicrosoftSQLServer", "SQL2016SP2-WS2016", "Standard", "Windows"]
    "SQL2016SP2ENT-WS2016" = ["MicrosoftSQLServer", "SQL2016SP2-WS2016", "Enterprise", "Windows"]
    "SQL2016SP2DEV-WS2016" = ["MicrosoftSQLServer", "SQL2016SP2-WS2016", "SQLDEV", "Windows"]
    "SQL2017STD-WS2016"    = ["MicrosoftSQLServer", "SQL2017-WS2016", "Standard", "Windows"]
    "SQL2017ENT-WS2016"    = ["MicrosoftSQLServer", "SQL2017-WS2016", "Enterprise", "Windows"]
    "SQL2017DEV-WS2016"    = ["MicrosoftSQLServer", "SQL2017-WS2016", "SQLDEV", "Windows"]
  }
}

