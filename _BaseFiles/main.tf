locals {
  tf_tag = {
    Source       = "TFModule-ModuleName_1.0.0.0"
    CreatedDate  = "${timestamp()}"
    ModifiedDate = "${timestamp()}"
  }
}
