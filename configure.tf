provider "aws" {
    region = "eu-central-1"
}

resource "aws_s3_bucket"  "tf-state-bucket" {
    bucket = "ym-lmu-cne-2019-tf-state"
    acl = "private"

    tags = {
        Context = "CNE20192020"
    }
}