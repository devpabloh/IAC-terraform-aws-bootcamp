# iam.tf

// A política que permite que o serviço EC2 assuma esta role
data "aws_iam_policy_document" "assume_role_policy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

// A role em si
resource "aws_iam_role" "ec2_role" {
    name               = "ec2-role-para-rds"
    assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

// Anexa uma política gerenciada pela AWS que permite o acesso ao Systems Manager
resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
    role       = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// Criamos o perfil da instância que é o que de fato se anexa à EC2
resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2-instance-profile"
    role = aws_iam_role.ec2_role.name
}