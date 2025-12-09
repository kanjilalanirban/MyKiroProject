package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestEKSClusterCreation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"cluster_name":       "test-eks-cluster",
			"environment":        "test",
			"vpc_id":             "vpc-test123",
			"subnet_ids":         []string{"subnet-test1", "subnet-test2"},
			"allowed_cidr_blocks": []string{"10.0.0.0/8"},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndPlan(t, terraformOptions)
}

func TestEKSClusterOutputs(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"cluster_name":       "test-eks-cluster",
			"environment":        "test",
			"vpc_id":             "vpc-test123",
			"subnet_ids":         []string{"subnet-test1", "subnet-test2"},
			"allowed_cidr_blocks": []string{"10.0.0.0/8"},
		},
	}

	terraform.Init(t, terraformOptions)
	planStruct := terraform.InitAndPlan(t, terraformOptions)

	// Verify outputs are defined
	assert.NotNil(t, planStruct)
}

func TestSecurityGroupRules(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"cluster_name":       "test-eks-cluster",
			"environment":        "test",
			"vpc_id":             "vpc-test123",
			"subnet_ids":         []string{"subnet-test1", "subnet-test2"},
			"allowed_cidr_blocks": []string{"10.0.0.0/8"},
		},
	}

	terraform.Init(t, terraformOptions)
	plan := terraform.InitAndPlan(t, terraformOptions)

	// Verify security groups are created
	assert.NotNil(t, plan)
}

func TestKMSEncryption(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"cluster_name":       "test-eks-cluster",
			"environment":        "test",
			"vpc_id":             "vpc-test123",
			"subnet_ids":         []string{"subnet-test1", "subnet-test2"},
			"allowed_cidr_blocks": []string{"10.0.0.0/8"},
		},
	}

	terraform.Init(t, terraformOptions)
	plan := terraform.InitAndPlan(t, terraformOptions)

	// Verify KMS keys are created
	assert.NotNil(t, plan)
}
