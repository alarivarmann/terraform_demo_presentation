# IAM roles and policies

# Create the CodeBuild service role
resource "aws_iam_role" "codebuild_service_role" {
  name = "codebuild_service_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the CodeBuild service role policy
resource "aws_iam_policy" "codebuild_service_role_policy" {
  name = "codebuild_service_role_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::codepipeline*",
        "arn:aws:s3:::elasticbeanstalk*"
      ]
    }
  ]
}
EOF
}

# Attach the policy to the role
resource "aws_iam_policy_attachment" "codebuild_service_role_policy_attachment" {
  name       = "codebuild_service_role_policy_attachment"
  policy_arn = aws_iam_policy.codebuild_service_role_policy.arn
  roles      = [aws_iam_role.codebuild_service_role.name]
}

# Create the CodePipeline service role
resource "aws_iam_role" "codepipeline_service_role" {
  name = "codepipeline_service_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the CodePipeline service role policy
resource "aws_iam_policy" "codepipeline_service_role_policy" {
  name = "codepipeline_service_role_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "codebuild:*",
        "cloudformation:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# CodeCommit repository
resource "aws_codecommit_repository" "demo_repository" {
  repository_name = "demo_repository"
}

# CodeBuild project
resource "aws_codebuild_project" "demo_project" {
  name            = "demo_project"
  source {
    type      = "CODECOMMIT"
    location  = aws_codecommit_repository.demo_repository.clone_url_http
    git_clone_depth = 1
  }
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:2.0"
  }
  service_role = aws_iam_role.codebuild_service_role.arn
}

# CodeBuild build definition file
resource "aws_codebuild_source_credential" "source_credential" {
  server_type = "GITHUB"
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  token       = "YOUR_GITHUB_PERSONAL_ACCESS_TOKEN"
}

data "aws_codebuild_source_credential" "source_credential" {
  arn = aws_codebuild_source_credential.source_credential.arn
}

# Place the buildspec.yml file in the root of your repository
# In this example, we are using a simple build definition file that installs dependencies and runs tests
# You can customize this file to fit the needs of your project
resource "aws_s3_bucket_object" "buildspec" {
  bucket = aws_s3_bucket.demo_bucket.id
  key    = "buildspec.yml"
  source = "buildspec.yml"
}

# S3 bucket to store build artifacts
resource "aws_s3_bucket" "demo_bucket" {
  bucket        = "demo-bucket"
  acl           = "private"
  force_destroy = true
}

# CodePipeline pipeline
resource "aws_codepipeline" "demo_pipeline" {
  name     = "demo_pipeline"
  role_arn = aws_iam_role.codepipeline_service_role.arn

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration {
        # Replace with the URL of your GitHub repository
        RepoURL = "https://github.com/your-username/your-repo"
        Branch  = "master"
        OAuthToken = data.aws_codebuild_source_credential.source_credential.token