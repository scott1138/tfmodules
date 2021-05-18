locals {
    location_map = {
        pascal_long = {
            "centralus"      = "CentralUS"
            "eastus"         = "EastUS"
            "eastus2"        = "EastUS2"
            "westus"         = "WestUS"
            "westus2"        = "WestUS2"
            "northcentralus" = "NorthCentralUS"
            "southcentralus" = "SouthCentralUS"
            "westcentralus"  = "WestCentralUS"
        },
        uc_short = {
            "centralus"      = "CUS"
            "eastus"         = "EUS"
            "eastus2"        = "EUS2"
            "westus"         = "WUS"
            "westus2"        = "WUS2"
            "northcentralus" = "NCUS"
            "southcentralus" = "SCUS"
            "westcentralus"  = "WCUS"
        },
        lc_short = {
            "centralus"      = "cus"
            "eastus"         = "eus"
            "eastus2"        = "eus2"
            "westus"         = "wus"
            "westus2"        = "wus2"
            "northcentralus" = "ncus"
            "southcentralus" = "scus"
            "westcentralus"  = "wcus"
        }
    }

}
