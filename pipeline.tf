resource "aws_codebuild_project" "ditf-plan" {
  name         = "ditf-plan"
  description  = "Plan stage for terraform"
  service_role = aws_iam_role.ditf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:1.2.3"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential          = var.dockerhub_credentials
      credential_provider = "SECRETS_MANAGER"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/planspec.yaml")
  }
}

resource "aws_codebuild_project" "ditf-apply" {
  name         = "ditf-apply"
  description  = "Apply stage for terraform"
  service_role = aws_iam_role.ditf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:0.14.3"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential          = var.dockerhub_credentials
      credential_provider = "SECRETS_MANAGER"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/applyspec.yaml")
  }
}


resource "aws_codepipeline" "ditf_pipeline" {

  name     = "tf-cicd"
  role_arn = aws_iam_role.ditf-cp-role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.ditf_artifacts.id
  }
  #coonnect github and pass the cource code
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["tf-code"]
      configuration = {
        FullRepositoryId     = "DuranIsrael/AWS-CICD-pipeline-demo"
        BranchName           = "main"
        ConnectionArn        = var.codestar_connector_credentials
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Plan"
    action {
      name            = "Build"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = "ditf-cicd-plan"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = "ditf-cicd-apply"
      }
    }
  }

}