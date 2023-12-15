<br/>
<p align="center">
  <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-defaults">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="docs/logo-dark.png">
      <img src="docs/logo-light.png" alt="Logo">
    </picture>
  </a>

<h3 align="center">Ben's Terraform AWS Defaults Module</h3>

  <p align="center">
    This is how I do it.
    <br/>
    <br/>
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-defaults"><strong>Explore the docs »</strong></a>
    <br/>
    <br/>
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/issues">Report Bug</a>
    .
    <a href="https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/issues">Request Feature</a>
  </p>
</p>

![Contributors](https://img.shields.io/github/contributors/bendoerr-terraform-modules/terraform-aws-defaults?color=dark-green) ![Issues](https://img.shields.io/github/issues/bendoerr-terraform-modules/terraform-aws-defaults) ![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/bendoerr-terraform-modules/terraform-aws-defaults/test.yml)
![GitHub tag (with filter)](https://img.shields.io/github/v/tag/bendoerr-terraform-modules/terraform-aws-defaults?filter=v*)
![License](https://img.shields.io/github/license/bendoerr-terraform-modules/terraform-aws-defaults)

## About The Project

My opinionated AWS Defaults module.

## Usage

```
module "context" {
    source  = "bendoerr-terraform-modules/context/null"
  version = "0.4.1"
  namespace = "brd"
  role      = "production'
  region    = "us-east-1"
  project   = "example'
}

module "aws_defaults" {
  source               = "git@github.com:bendoerr-terraform-modules/terraform-aws-defaults?ref=v0.3.0"
  context              = module.context.shared
  budget_monthly_limit = 10
  budget_alert_emails  = "alerts@example.com"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_account"></a> [iam\_account](#module\_iam\_account) | terraform-aws-modules/iam/aws//modules/iam-account | 5.32.0 |
| <a name="module_label_account_alias"></a> [label\_account\_alias](#module\_label\_account\_alias) | git@github.com:bendoerr-terraform-modules/terraform-null-label | v0.4.0 |
| <a name="module_label_monthly_total"></a> [label\_monthly\_total](#module\_label\_monthly\_total) | git@github.com:bendoerr-terraform-modules/terraform-null-label | v0.4.0 |
| <a name="module_label_network"></a> [label\_network](#module\_label\_network) | git@github.com:bendoerr-terraform-modules/terraform-null-label | v0.4.0 |
| <a name="module_vpc_default"></a> [vpc\_default](#module\_vpc\_default) | terraform-aws-modules/vpc/aws | 5.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_budgets_budget.monthly_total](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |
| [aws_ebs_default_kms_key.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_default_kms_key) | resource |
| [aws_ebs_encryption_by_default.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_encryption_by_default) | resource |
| [aws_ec2_serial_console_access.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_serial_console_access) | resource |
| [aws_ecs_account_setting_default.awsvpc_trunking](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_account_setting_default) | resource |
| [aws_ecs_account_setting_default.container_insights](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_account_setting_default) | resource |
| [aws_kms_alias.ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_budget_alert_emails"></a> [budget\_alert\_emails](#input\_budget\_alert\_emails) | n/a | `set(string)` | n/a | yes |
| <a name="input_budget_monthly_limit"></a> [budget\_monthly\_limit](#input\_budget\_monthly\_limit) | n/a | `string` | n/a | yes |
| <a name="input_context"></a> [context](#input\_context) | Shared Context from Ben's terraform-null-context | <pre>object({<br>    attributes     = list(string)<br>    dns_namespace  = string<br>    environment    = string<br>    instance       = string<br>    instance_short = string<br>    namespace      = string<br>    region         = string<br>    region_short   = string<br>    role           = string<br>    role_short     = string<br>    project        = string<br>    tags           = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_iam_alias_postfix"></a> [iam\_alias\_postfix](#input\_iam\_alias\_postfix) | n/a | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | n/a | <pre>object({<br>    cidr           = string<br>    enable_nat     = bool<br>    enable_private = bool<br>    subnets        = list(object({<br>      az      = string<br>      public  = string<br>      private = string<br>    }))<br>  })</pre> | <pre>{<br>  "cidr": "0.0.0.0/0",<br>  "enable_nat": false,<br>  "enable_private": false,<br>  "subnets": [<br>    {<br>      "az": "us-east-1a",<br>      "private": "",<br>      "public": "0.0.0.0/0"<br>    }<br>  ]<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_budgets_budget_monthly_total_account"></a> [aws\_budgets\_budget\_monthly\_total\_account](#output\_aws\_budgets\_budget\_monthly\_total\_account) | n/a |
| <a name="output_aws_budgets_budget_monthly_total_name"></a> [aws\_budgets\_budget\_monthly\_total\_name](#output\_aws\_budgets\_budget\_monthly\_total\_name) | n/a |
| <a name="output_vpc_azs"></a> [vpc\_azs](#output\_vpc\_azs) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
| <a name="output_vpc_private_subnet_ids"></a> [vpc\_private\_subnet\_ids](#output\_vpc\_private\_subnet\_ids) | n/a |
| <a name="output_vpc_public_subnet_ids"></a> [vpc\_public\_subnet\_ids](#output\_vpc\_public\_subnet\_ids) | n/a |
<!-- END_TF_DOCS -->

## Roadmap

See the [open issues](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/issues) for a list of proposed features (and known issues).

## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.
* If you have suggestions for adding or removing projects, feel free to [open an issue](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/issues/new) to discuss it, or directly create a pull request after you edit the *README.md* file with necessary changes.
* Please make sure you check your spelling and grammar.
* Create individual PR for each suggestion.

### Creating A Pull Request

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See [LICENSE](https://github.com/bendoerr-terraform-modules/terraform-aws-defaults/blob/main/LICENSE.txt) for more information.

## Authors

* **Benjamin R. Doerr** - *Terraformer* - [Benjamin R. Doerr](https://github.com/bendoerr/) - *Built Ben's Terraform Modules*

## Acknowledgements

* [ShaanCoding (ReadME Generator)](https://github.com/ShaanCoding/ReadME-Generator)
