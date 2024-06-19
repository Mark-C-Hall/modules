# Fetch Github's OIDC Thumbprint
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Create an IAM OIDC identity provider that trusts Github
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# Role for Github Actions
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
      type        = "Federated"
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        for a in var.allowed_repos_branches :
        "repo:${a["org"]}/${a["repo"]}:ref:refs/heads/${a["branch"]}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# Variable for adding allowed repos
variable "allowed_repos_branches" {
  description = "Github repos and branches allowed to assume the IAM role"
  type = list(object({
    org    = string
    repo   = string
    branch = string
  }))
}

# Custom IAM Policy for GitHub Actions
resource "aws_iam_policy" "github_actions_custom_policy" {
  name        = "github-actions-custom-policy"
  description = "Custom policy for GitHub Actions to access S3 and CloudFront"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "VisualEditor0",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "cloudfront:CreateInvalidation"
        ],
        Resource = [
          "arn:aws:cloudfront::998908665479:distribution/*",
          "arn:aws:s3:::www.markchall.com/*",
          "arn:aws:s3:::www.markchall.com"
        ]
      }
    ]
  })
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name               = "github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# Attach Custom Policy to the Role
resource "aws_iam_role_policy_attachment" "github_actions_role_custom_policy" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_custom_policy.arn
}
