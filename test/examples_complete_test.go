package test_test

import (
	"context"
	"fmt"
	"testing"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/budgets"
	"github.com/aws/aws-sdk-go-v2/service/iam"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/kr/pretty"
)

func TestDefaults(t *testing.T) {
	// AWS Session
	cfg, err := config.LoadDefaultConfig(
		context.TODO(),
		config.WithRegion("us-east-1"),
	)

	if err != nil {
		t.Fatal(err)
	}

	// Before starting grab the account alias so that we can reset it when done
	iamSvc := iam.NewFromConfig(cfg)
	aa, err := iamSvc.ListAccountAliases(context.TODO(), &iam.ListAccountAliasesInput{})
	if err != nil {
		t.Fatal(err)
	}

	if len(aa.AccountAliases) > 1 {
		t.Fatal("well that is unexpected")
	}

	if len(aa.AccountAliases) > 0 {
		defer func(accountAlias string) {
			t.Log("Setting account alias: " + accountAlias)
			iamSvc = iam.NewFromConfig(cfg)
			_, err = iamSvc.CreateAccountAlias(context.TODO(), &iam.CreateAccountAliasInput{AccountAlias: &accountAlias})
			if err != nil {
				t.Fatal(err)
			}
		}(aa.AccountAliases[0])
	}

	// Setup terratest
	rootFolder := "../"
	terraformFolderRelativeToRoot := "examples/complete"

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		VarFiles:     []string{"complete.tfvars"},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	pretty.Print(terraform.OutputAll(t, terraformOptions))

	// Start by checking the billing budgets
	budgetName := terraform.Output(t, terraformOptions, "aws_budgets_budget_monthly_total_name")
	budgetAccount := terraform.Output(t, terraformOptions, "aws_budgets_budget_monthly_total_account")
	budgetLimit := "1.0"

	budgetsSvc := budgets.NewFromConfig(cfg)
	budgetDesc, err := budgetsSvc.DescribeBudget(context.TODO(), &budgets.DescribeBudgetInput{
		AccountId:  &budgetAccount,
		BudgetName: &budgetName,
	})

	if err != nil {
		t.Fatal(err)
	}

	if budgetDesc.Budget.BudgetType != "COST" {
		t.Fatal(makediff(budgetName, budgetDesc.Budget.BudgetType))
	}

	if *budgetDesc.Budget.BudgetLimit.Amount != budgetLimit {
		t.Fatal(makediff(budgetLimit, *budgetDesc.Budget.BudgetLimit.Amount))
	}
}

func TestDualStack(t *testing.T) {
	// AWS Session
	cfg, err := config.LoadDefaultConfig(
		context.TODO(),
		config.WithRegion("us-east-1"),
	)

	if err != nil {
		t.Fatal(err)
	}

	// Before starting grab the account alias so that we can reset it when done
	iamSvc := iam.NewFromConfig(cfg)
	aa, err := iamSvc.ListAccountAliases(context.TODO(), &iam.ListAccountAliasesInput{})
	if err != nil {
		t.Fatal(err)
	}

	if len(aa.AccountAliases) > 1 {
		t.Fatal("well that is unexpected")
	}

	if len(aa.AccountAliases) > 0 {
		defer func(accountAlias string) {
			t.Log("Setting account alias: " + accountAlias)
			iamSvc = iam.NewFromConfig(cfg)
			_, err = iamSvc.CreateAccountAlias(context.TODO(), &iam.CreateAccountAliasInput{AccountAlias: &accountAlias})
			if err != nil {
				t.Fatal(err)
			}
		}(aa.AccountAliases[0])
	}

	// Setup terratest
	rootFolder := "../"
	terraformFolderRelativeToRoot := "examples/complete"

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		VarFiles:     []string{"dual-stack.tfvars"},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	pretty.Print(terraform.OutputAll(t, terraformOptions))

	// Verify IPv6 CIDR is assigned to the VPC
	vpcIPv6CIDR := terraform.Output(t, terraformOptions, "vpc_ipv6_cidr_block")
	if vpcIPv6CIDR == "" {
		t.Fatal(makediff("non-empty vpc_ipv6_cidr_block", vpcIPv6CIDR))
	}

	// Verify public subnets have IPv6 CIDRs
	publicIPv6CIDRs := terraform.OutputList(t, terraformOptions, "vpc_public_subnet_ipv6_cidr_blocks")
	if len(publicIPv6CIDRs) == 0 {
		t.Fatal(makediff("non-empty vpc_public_subnet_ipv6_cidr_blocks", publicIPv6CIDRs))
	}

	// Verify private subnets have IPv6 CIDRs
	privateIPv6CIDRs := terraform.OutputList(t, terraformOptions, "vpc_private_subnet_ipv6_cidr_blocks")
	if len(privateIPv6CIDRs) == 0 {
		t.Fatal(makediff("non-empty vpc_private_subnet_ipv6_cidr_blocks", privateIPv6CIDRs))
	}

	// Dual-stack does not use an egress-only IGW
	egressOnlyIGW := terraform.Output(t, terraformOptions, "vpc_egress_only_internet_gateway_id")
	if egressOnlyIGW != "" {
		t.Fatal(makediff("empty vpc_egress_only_internet_gateway_id", egressOnlyIGW))
	}

	// Verify the billing budget
	budgetName := terraform.Output(t, terraformOptions, "aws_budgets_budget_monthly_total_name")
	budgetAccount := terraform.Output(t, terraformOptions, "aws_budgets_budget_monthly_total_account")
	budgetLimit := "1.0"

	budgetsSvc := budgets.NewFromConfig(cfg)
	budgetDesc, err := budgetsSvc.DescribeBudget(context.TODO(), &budgets.DescribeBudgetInput{
		AccountId:  &budgetAccount,
		BudgetName: &budgetName,
	})

	if err != nil {
		t.Fatal(err)
	}

	if budgetDesc.Budget.BudgetType != "COST" {
		t.Fatal(makediff("COST", budgetDesc.Budget.BudgetType))
	}

	if *budgetDesc.Budget.BudgetLimit.Amount != budgetLimit {
		t.Fatal(makediff(budgetLimit, *budgetDesc.Budget.BudgetLimit.Amount))
	}
}

func TestIPv6Only(t *testing.T) {
	// AWS Session
	cfg, err := config.LoadDefaultConfig(
		context.TODO(),
		config.WithRegion("us-east-1"),
	)

	if err != nil {
		t.Fatal(err)
	}

	// Before starting grab the account alias so that we can reset it when done
	iamSvc := iam.NewFromConfig(cfg)
	aa, err := iamSvc.ListAccountAliases(context.TODO(), &iam.ListAccountAliasesInput{})
	if err != nil {
		t.Fatal(err)
	}

	if len(aa.AccountAliases) > 1 {
		t.Fatal("well that is unexpected")
	}

	if len(aa.AccountAliases) > 0 {
		defer func(accountAlias string) {
			t.Log("Setting account alias: " + accountAlias)
			iamSvc = iam.NewFromConfig(cfg)
			_, err = iamSvc.CreateAccountAlias(context.TODO(), &iam.CreateAccountAliasInput{AccountAlias: &accountAlias})
			if err != nil {
				t.Fatal(err)
			}
		}(aa.AccountAliases[0])
	}

	// Setup terratest
	rootFolder := "../"
	terraformFolderRelativeToRoot := "examples/ipv6-only"

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		VarFiles:     []string{"ipv6-only.tfvars"},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	pretty.Print(terraform.OutputAll(t, terraformOptions))

	// Verify IPv6 CIDR is assigned to the VPC
	vpcIPv6CIDR := terraform.Output(t, terraformOptions, "vpc_ipv6_cidr_block")
	if vpcIPv6CIDR == "" {
		t.Fatal(makediff("non-empty vpc_ipv6_cidr_block", vpcIPv6CIDR))
	}

	// Verify public subnets have IPv6 CIDRs
	publicIPv6CIDRs := terraform.OutputList(t, terraformOptions, "vpc_public_subnet_ipv6_cidr_blocks")
	if len(publicIPv6CIDRs) == 0 {
		t.Fatal(makediff("non-empty vpc_public_subnet_ipv6_cidr_blocks", publicIPv6CIDRs))
	}

	// Verify egress-only IGW is created (IPv6-only mode)
	egressOnlyIGW := terraform.Output(t, terraformOptions, "vpc_egress_only_internet_gateway_id")
	if egressOnlyIGW == "" {
		t.Fatal(makediff("non-empty vpc_egress_only_internet_gateway_id", egressOnlyIGW))
	}

	// Verify the billing budget
	budgetName := terraform.Output(t, terraformOptions, "aws_budgets_budget_monthly_total_name")
	budgetAccount := terraform.Output(t, terraformOptions, "aws_budgets_budget_monthly_total_account")
	budgetLimit := "1.0"

	budgetsSvc := budgets.NewFromConfig(cfg)
	budgetDesc, err := budgetsSvc.DescribeBudget(context.TODO(), &budgets.DescribeBudgetInput{
		AccountId:  &budgetAccount,
		BudgetName: &budgetName,
	})

	if err != nil {
		t.Fatal(err)
	}

	if budgetDesc.Budget.BudgetType != "COST" {
		t.Fatal(makediff("COST", budgetDesc.Budget.BudgetType))
	}

	if *budgetDesc.Budget.BudgetLimit.Amount != budgetLimit {
		t.Fatal(makediff(budgetLimit, *budgetDesc.Budget.BudgetLimit.Amount))
	}
}

func makediff(want interface{}, got interface{}) string {
	s := fmt.Sprintf("\nwant: %# v", pretty.Formatter(want))
	s = fmt.Sprintf("%s\ngot: %# v", s, pretty.Formatter(got))
	diffs := pretty.Diff(want, got)
	s = fmt.Sprintf("%s\ndifferences: ", s)
	for _, d := range diffs {
		s = fmt.Sprintf("%s\n  - %s", s, d)
	}
	return s
}
