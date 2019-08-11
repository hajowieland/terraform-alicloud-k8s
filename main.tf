resource "random_id" "cluster_name" {
  count       = var.enable_alibaba ? 1 : 0
  byte_length = 6
}

data "alicloud_zones" main {
  count                       = var.enable_alibaba ? 1 : 0
  available_resource_creation = "VSwitch"
  enable_details              = true
}

resource "alicloud_key_pair" "publickey" {
  count      = var.enable_alibaba ? 1 : 0
  public_key = file(var.ssh_public_key_path)
}

resource "alicloud_vpc" "vpc" {
  count      = var.enable_alibaba ? 1 : 0
  cidr_block = var.ali_vpc_cidr
  name       = var.ali_vpc_name
}

resource "alicloud_vswitch" "vswitches" {
  count             = var.enable_alibaba ? length(var.ali_vswitch_cidrs) : 0
  vpc_id            = alicloud_vpc.vpc.0.id
  cidr_block        = var.ali_vswitch_cidrs[count.index]
  availability_zone = data.alicloud_zones.main.0.zones[count.index].id
  name              = "${var.ack_name}-${random_id.cluster_name.0.hex}-vswitch-${count.index}"

  depends_on = [alicloud_vpc.vpc]
}

resource "alicloud_nat_gateway" "default" {
  count         = var.enable_alibaba ? 1 : 0
  vpc_id        = alicloud_vpc.vpc[count.index].id
  specification = "Small"
  name          = "${var.ack_name}-${random_id.cluster_name[count.index].hex}-natgw"

  lifecycle {
    prevent_destroy = true
  }
  depends_on = [alicloud_vswitch.vswitches]
}

## Data source for getting a NAT gateway
//data "alicloud_nat_gateways" "default" {
//  count = var.enable_alibaba ? 1 : 0
//  vpc_id     = alicloud_vpc.vpc[count.index].id
//  name_regex = "k8s-ali-.*"
//}

resource "alicloud_eip" "eip" {
  count     = var.enable_alibaba ? 1 : 0
  bandwidth = "10"

  depends_on = [alicloud_nat_gateway.default]
}

resource "alicloud_eip_association" "eipassoc" {
  count         = var.enable_alibaba ? 1 : 0
  allocation_id = alicloud_eip.eip[count.index].id
  instance_id   = alicloud_nat_gateway.default[count.index].id
  #instance_id = data.alicloud_nat_gateways.default[count.index].id

  depends_on = [alicloud_eip.eip]
}

resource "alicloud_snat_entry" "default" {
  count         = var.enable_alibaba ? length(var.ali_vswitch_cidrs) : 0
  snat_table_id = alicloud_nat_gateway.default.0.snat_table_ids
  #snat_table_id = data.alicloud_nat_gateways.default[count.index].gateways.0.snat_table_id
  source_vswitch_id = alicloud_vswitch.vswitches[count.index].id
  snat_ip           = alicloud_eip.eip.0.ip_address

  depends_on = [alicloud_eip_association.eipassoc]
}

# Create policies which aren't provided by Alibaba by default
# (or created the first time when you create a Kubernetes cluster via the Web console)
# We prefix our manually created policies with k8s-*

resource "alicloud_ram_policy" "k8s-AliyunOSSAccess" {
  count       = var.enable_alibaba ? 1 : 0
  name        = "k8s-AliyunOSSAccess"
  document    = <<EOF
{
  "Statement": [
    {
      "Action": [
        "oss:PutObject",
        "oss:ListObjects",
        "oss:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ],
    "Version": "1"
}
EOF
  description = "Allow access by CS to OSS"
  force       = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_policy" "k8s-AliyunCMSAccess" {
  count       = var.enable_alibaba ? 1 : 0
  name        = "k8s-AliyunCMSAccess"
  document    = <<EOF
{
  "Statement": [
    {
      "Action": "cms:*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ],
    "Version": "1"
}
EOF
  description = "Allow access by CS to OSS"
  force       = true

  lifecycle {
    prevent_destroy = true
  }
}


resource "alicloud_ram_policy" "k8s-AliyunRAMpassrole" {
  count       = var.enable_alibaba ? 1 : 0
  name        = "k8s-AliyunRAMpassrole"
  document    = <<EOF
{
  "Statement": [
      {
        "Action": "ram:PassRole",
        "Resource": "*",
        "Effect": "Allow"
      }
  ],
    "Version": "1"
}
EOF
  description = "Allow RAM to pass role"
  force       = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_policy" "k8s-AliyunCRaccess" {
  count       = var.enable_alibaba ? 1 : 0
  name        = "k8s-AliyunCRaccess"
  document    = <<EOF
{
  "Statement": [
      {
          "Action": "*",
          "Resource": "*",
          "Effect": "Allow"
      }
  ],
    "Version": "1"
}
EOF
  description = "Allow CS to access CR"
  force       = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_policy" "k8s-AliyunOOSaccess" {
  count       = var.enable_alibaba ? 1 : 0
  name        = "k8s-AliyunOOSaccess"
  document    = <<EOF
{
  "Statement": [
      {
          "Action": "*",
          "Resource": "*",
          "Effect": "Allow"
      }
  ],
    "Version": "1"
}
EOF
  description = "Allow ESS to access OOS"
  force       = true

  lifecycle {
    prevent_destroy = true
  }
}


##################################################################
###  RAM roles, policies, attachments
##################################################################

## Get default aliyun policies where it makes sense (kinda)

data "alicloud_ram_policies" "AliyunECSReadOnlyAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunECSReadOnlyAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunECSFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunECSFullAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunSLBFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunSLBFullAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunLogFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunLogFullAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunVPCFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunVPCFullAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunDNSFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunDNSFullAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunRDSFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunRDSFullAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunROSFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunROSFullAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunESSFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunESSFullAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunRAMReadOnlyAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunRAMReadOnlyAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunPvtzFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunPvtzFullAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunECIFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunECIFullAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunMNSFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunMNSFullAccess$"
  type       = "System"
}

data "alicloud_ram_policies" "AliyunRAMFullAccess" {
  count      = var.enable_alibaba ? 1 : 0
  name_regex = "^AliyunRAMFullAccess$"
  type       = "System"
}

## AliyunCSClusterRole@role.5395559225751014.onaliyunservice.com
resource "alicloud_ram_role" "AliyunCSClusterRole" {
  count       = var.enable_alibaba ? 1 : 0
  name        = "AliyunCSClusterRole"
  document    = <<EOF
{
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "cs.aliyuncs.com"
                ]
            }
        }
    ],
    "Version": "1"
}
EOF
  description = "The clusters of Container Service will use this role to access your resources in other services."
  force       = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-k8s-AliyunOSSAccess-AliyunCSClusterRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = alicloud_ram_policy.k8s-AliyunOSSAccess[count.index].name
  policy_type = alicloud_ram_policy.k8s-AliyunOSSAccess[count.index].type
  role_name   = alicloud_ram_role.AliyunCSClusterRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunECSReadOnlyAccess-AliyunCSClusterRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunECSReadOnlyAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSClusterRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-k8s-AliyunCMSAccess-AliyunCSClusterRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = alicloud_ram_policy.k8s-AliyunCMSAccess[count.index].name
  policy_type = alicloud_ram_policy.k8s-AliyunCMSAccess[count.index].type
  role_name   = alicloud_ram_role.AliyunCSClusterRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunSLBFullAccess-AliyunCSClusterRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunSLBFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSClusterRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunLogFullAccess-AliyunCSClusterRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunLogFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSClusterRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

## AliyunCSDefaultRole@role.5395559225751014.onaliyunservice.com
resource "alicloud_ram_role" "AliyunCSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  name        = "AliyunCSDefaultRole"
  document    = <<EOF
{
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "cs.aliyuncs.com"
                ]
            }
        }
    ],
    "Version": "1"
}
EOF
  description = "The Container Service will use this role to access your resources in other services."
  force       = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-k8s-AliyunRAMpassrole-AliyunCSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = alicloud_ram_policy.k8s-AliyunRAMpassrole[count.index].name
  policy_type = alicloud_ram_policy.k8s-AliyunRAMpassrole[count.index].type
  role_name   = alicloud_ram_role.AliyunCSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunRAMFullAccess-AliyunCSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunRAMFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunECSFullAccess-AliyunCSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunECSFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunVPCFullAccess-AliyunCSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunVPCFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunSLBFullAccess-AliyunCSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunSLBFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunDNSFullAccess-AliyunCSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunDNSFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunRDSFullAccess-AliyunCSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunRDSFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunROSFullAccess-AliyunCSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunROSFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunESSFullAccess-AliyunCSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunESSFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-k8s-AliyunCMSAccess-AliyunCSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = alicloud_ram_policy.k8s-AliyunCMSAccess[count.index].name
  policy_type = alicloud_ram_policy.k8s-AliyunCMSAccess[count.index].type
  role_name   = alicloud_ram_role.AliyunCSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

## AliyunCSManagedKubernetesRole@role.5395559225751014.onaliyunservice.com
resource "alicloud_ram_role" "AliyunCSManagedKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  name        = "AliyunCSManagedKubernetesRole"
  document    = <<EOF
{
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "cs.aliyuncs.com"
                ]
            }
        }
    ],
    "Version": "1"
}
EOF
  description = "The Container Service for Managed Kubernetes will use this role to access your resources in other services."
  force       = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-k8s-AliyunCRaccess-AliyunCSManagedKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = alicloud_ram_policy.k8s-AliyunCRaccess[count.index].name
  policy_type = alicloud_ram_policy.k8s-AliyunCRaccess[count.index].type
  role_name   = alicloud_ram_role.AliyunCSManagedKubernetesRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunRAMFullAccess-AliyunCSManagedKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunRAMFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSManagedKubernetesRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunECSFullAccess-AliyunCSManagedKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunECSFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSManagedKubernetesRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunSLBFullAccess-AliyunCSManagedKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunSLBFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSManagedKubernetesRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunVPCFullAccess-AliyunCSManagedKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunVPCFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSManagedKubernetesRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

## AliyunCSServerlessKubernetesRole@role.5395559225751014.onaliyunservice.com
resource "alicloud_ram_role" "AliyunCSServerlessKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  name        = "AliyunCSServerlessKubernetesRole"
  document    = <<EOF
{
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "cs.aliyuncs.com"
                ]
            }
        }
    ],
    "Version": "1"
}
EOF
  description = "The Container Service for Serverless Kubernetes will use this role to access your resources in other services."
  force       = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-k8s-AliyunCRaccess-AliyunCSServerlessKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = alicloud_ram_policy.k8s-AliyunCRaccess[count.index].name
  policy_type = alicloud_ram_policy.k8s-AliyunCRaccess[count.index].type
  role_name   = alicloud_ram_role.AliyunCSServerlessKubernetesRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunVPCFullAccess-AliyunCSServerlessKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunVPCFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSServerlessKubernetesRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunECSFullAccess-AliyunCSServerlessKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunECSFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSServerlessKubernetesRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunSLBFullAccess-AliyunCSServerlessKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunSLBFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSServerlessKubernetesRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunPvtzFullAccess-AliyunCSServerlessKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunPvtzFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSServerlessKubernetesRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunECIFullAccess-AliyunCSServerlessKubernetesRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunECIFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSServerlessKubernetesRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

## AliyunESSDefaultRole@role.5395559225751014.onaliyunservice.com
resource "alicloud_ram_role" "AliyunESSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  name        = "AliyunESSDefaultRole"
  document    = <<EOF
{
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "ess.aliyuncs.com"
                ]
            }
        }
    ],
    "Version": "1"
}
EOF
  description = "The ESS service will use this role to run ECS instances."
  force       = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-k8s-AliyunOOSaccess-AliyunESSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = alicloud_ram_policy.k8s-AliyunOOSaccess[count.index].name
  policy_type = alicloud_ram_policy.k8s-AliyunOOSaccess[count.index].type
  role_name   = alicloud_ram_role.AliyunESSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-k8s-AliyunCMSAccess-AliyunESSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = alicloud_ram_policy.k8s-AliyunCMSAccess[count.index].name
  policy_type = alicloud_ram_policy.k8s-AliyunCMSAccess[count.index].type
  role_name   = alicloud_ram_role.AliyunESSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-k8s-AliyunRAMpassrole-AliyunESSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = alicloud_ram_policy.k8s-AliyunRAMpassrole[count.index].name
  policy_type = alicloud_ram_policy.k8s-AliyunRAMpassrole[count.index].type
  role_name   = alicloud_ram_role.AliyunESSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunECSFullAccess-AliyunESSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunECSFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunESSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunSLBFullAccess-AliyunESSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunSLBFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunESSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunRDSFullAccess-AliyunESSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunRDSFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunESSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunVPCFullAccess-AliyunESSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunVPCFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunESSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunMNSFullAccess-AliyunESSDefaultRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunMNSFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunESSDefaultRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}

# AliyunCSKubernetesAuditRole@role.5395559225751014.onaliyunservice.com
resource "alicloud_ram_role" "AliyunCSKubernetesAuditRole" {
  count       = var.enable_alibaba ? 1 : 0
  name        = "AliyunCSKubernetesAuditRole"
  document    = <<EOF
{
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "cs.aliyuncs.com"
                ]
            }
        }
    ],
    "Version": "1"
}
EOF
  description = "The Container Service for Kubernetes will use this role to access your resources in other services."
  force       = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "alicloud_ram_role_policy_attachment" "attach-AliyunLogFullAccess-AliyunCSKubernetesAuditRole" {
  count       = var.enable_alibaba ? 1 : 0
  policy_name = data.alicloud_ram_policies.AliyunLogFullAccess[count.index].policies.0.name
  policy_type = "System"
  role_name   = alicloud_ram_role.AliyunCSKubernetesAuditRole[count.index].name

  lifecycle {
    prevent_destroy = true
  }
}


# Create the managed Kubernetes cluster
resource "alicloud_cs_managed_kubernetes" "ack" {
  count = var.enable_alibaba ? 1 : 0

  name                  = "${var.ack_name}-${random_id.cluster_name[count.index].hex}"
  vswitch_ids           = alicloud_vswitch.vswitches.*.id
  new_nat_gateway       = false
  worker_instance_types = var.ack_node_types.*
  worker_number         = var.ack_node_count
  key_name              = alicloud_key_pair.publickey[count.index].key_name
  pod_cidr              = var.ack_k8s_pod_cidr
  service_cidr          = var.ack_k8s_service_cidr
  install_cloud_monitor = true
  slb_internet_enabled  = true
  cluster_network_type  = var.ack_k8s_cni
  kube_config           = "./kubeconfig_ack"

  force_update = true

  depends_on = [alicloud_snat_entry.default]
}
