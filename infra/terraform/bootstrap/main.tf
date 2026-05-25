locals {
  oidc_url         = "token.actions.githubusercontent.com"
  deploy_role_name = var.deploy_role_name != "" ? var.deploy_role_name : "${var.project_name}-${var.account_name}-github-deploy"
  ssm_prefix       = "/${var.project_name}"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://${local.oidc_url}"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_url}:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = local.deploy_role_name
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_deploy" {
  statement {
    sid     = "CloudFormation"
    effect  = "Allow"
    actions = ["cloudformation:*"]
    resources = [
      "*"
    ]
  }

  statement {
    sid     = "Lambda"
    effect  = "Allow"
    actions = ["lambda:*"]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "ApiGateway"
    effect = "Allow"
    actions = [
      "apigateway:GET",
      "apigateway:POST",
      "apigateway:PUT",
      "apigateway:PATCH",
      "apigateway:DELETE",
      "apigateway:TagResource",
      "apigateway:UntagResource"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid     = "Logs"
    effect  = "Allow"
    actions = ["logs:*"]
    resources = [
      "*"
    ]
  }

  statement {
    sid     = "S3"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "*"
    ]
  }

  statement {
    sid     = "CloudFront"
    effect  = "Allow"
    actions = ["cloudfront:*"]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "CloudFrontUseCert"
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid     = "DynamoDB"
    effect  = "Allow"
    actions = ["dynamodb:*"]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "Route53Read"
    effect = "Allow"
    actions = [
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListTagsForResource",
      "route53:ListResourceRecordSets"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "SsmParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:ListTagsForResource",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:DescribeParameters"
    ]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/*"
    ]
  }

  statement {
    sid    = "SsmDescribe"
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "IamPassAndManage"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:PassRole",
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
    ]
  }

  statement {
    sid    = "IamServiceLinkedRole"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/*"
    ]

    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values = [
        "ops.apigateway.amazonaws.com",
        "apigateway.amazonaws.com"
      ]
    }
  }

  statement {
    sid    = "IamPolicyResources"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"
    ]
  }

  statement {
    sid     = "Cognito"
    effect  = "Allow"
    actions = ["cognito-idp:*"]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "Acm"
    effect = "Allow"
    actions = [
      "acm:AddTagsToCertificate",
      "acm:DescribeCertificate",
      "acm:DeleteCertificate",
      "acm:GetCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
      "acm:RemoveTagsFromCertificate",
      "acm:RequestCertificate"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid    = "StsCallerIdentity"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity"
    ]
    resources = [
      "*"
    ]
  }

  dynamic "statement" {
    for_each = var.account_name != "org" && var.org_route53_role_arn != "" ? [1] : []

    content {
      sid     = "AssumeOrgRoute53Role"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      resources = [
        var.org_route53_role_arn
      ]
    }
  }
}

resource "aws_iam_policy" "github_deploy" {
  name   = "${var.project_name}-${var.account_name}-github-deploy-policy"
  policy = data.aws_iam_policy_document.github_deploy.json
}

resource "aws_iam_role_policy_attachment" "github_deploy" {
  role       = aws_iam_role.github_deploy.name
  policy_arn = aws_iam_policy.github_deploy.arn
}
