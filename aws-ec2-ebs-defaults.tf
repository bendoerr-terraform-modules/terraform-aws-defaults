data "aws_kms_alias" "ebs" {
  name = "alias/aws/ebs"
}

resource "aws_ebs_default_kms_key" "default" {
  key_arn = data.aws_kms_alias.ebs.target_key_arn
}

resource "aws_ebs_encryption_by_default" "default" {
  enabled = true
}