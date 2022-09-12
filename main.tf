terraform {
  required_version = ">= 0.14.2"
}

variable "password" {}
variable "email" {}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack?ref=11.7"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "11.7"

  cluster_name = "unx101-mcgill"
  domain       = "calculquebec.cloud"
  image        = "CentOS-7-x64-2021-11"

  instances = {
    mgmt   = { type = "p4-6gb", tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "p2-3gb", tags = ["login", "public", "proxy"], count = 1 }
    node   = { type = "p8-30gb", tags = ["node"], count = 2 }
  }

  volumes = {
    nfs = {
      home     = { size = 100 }
      project  = { size = 50 }
      scratch  = { size = 50 }
    }
  }

  generate_ssh_key = true
  public_keys = [
    "ssh-rsa ...",
  ]

  nb_users = 30
  # Shared password, randomly chosen if blank
  guest_passwd = var.password
  
  hieradata = file("config.yaml")
}

output "accounts" {
  value = module.openstack.accounts
}

output "public_ip" {
  value = module.openstack.public_ip
}

## Uncomment to register your domain name with CloudFlare
module "dns" {
  source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare?ref=11.7"
  email            = var.email
  name             = module.openstack.cluster_name
  domain           = module.openstack.domain
  public_instances = module.openstack.public_instances
  ssh_private_key  = module.openstack.ssh_private_key
  sudoer_username  = module.openstack.accounts.sudoer.username
}
