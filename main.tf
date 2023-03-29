provider "aws" {
  region  = "us-east-1"
}

# Defining the SageMaker "Assume Role" policy
data "aws_iam_policy_document" "sm_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    
    principals {
      type = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

# Defining the SageMaker notebook IAM role
resource "aws_iam_role" "notebook_iam_role" {
  name = "sm_notebook_role"
  assume_role_policy = data.aws_iam_policy_document.sm_assume_role_policy.json
}

# Attaching the AWS default policy, "AmazonSageMakerFullAccess"
resource "aws_iam_policy_attachment" "sm_full_access_attach" {
  name = "sm-full-access-attachment"
  roles = [aws_iam_role.notebook_iam_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Creating the SageMaker notebook instance
resource "aws_sagemaker_notebook_instance" "notebook_instance" {
  name = "terraform-autogluon-notebook"
  role_arn = aws_iam_role.notebook_iam_role.arn
  #instance_type = "ml.t2.medium"
  instance_type = "ml.m5.12xlarge"
  volume_size = 10
  #lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.notebook_config.name
  default_code_repository = aws_sagemaker_code_repository.git_repo.code_repository_name
}

# Defining the Git repo to instantiate on the SageMaker notebook instance
resource "aws_sagemaker_code_repository" "git_repo" {
  code_repository_name = "terraform-sagemaker-demo-repo"
  
  git_config {
    repository_url = "https://github.com/dminhk/terraform-sagemaker-demo.git"
  }
}

# Defining the SageMaker notebook lifecycle configuration
resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "notebook_config" {
  name = "sagemaker-notebook-lifecycle-config"
  on_create = filebase64("on-create.sh")
  on_start = filebase64("on-start.sh")
}

# Output
output "aws_sagemaker_notebook_instance_url" {
  description = "AWS SageMaker Notebook Instance URL"
  value = "http://${aws_sagemaker_notebook_instance.notebook_instance.url}/lab"
}
