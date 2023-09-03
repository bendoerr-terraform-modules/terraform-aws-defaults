package test

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/budgets"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/kr/pretty"
	"testing"
)

func TestDefaults(t *testing.T) {
	t.Parallel()

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

	// AWS Session
	cfg, err := config.LoadDefaultConfig(
		context.TODO(),
		config.WithRegion("us-east-1"),
	)

	if err != nil {
		t.Fatal(err)
	}

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
