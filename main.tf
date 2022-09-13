terraform {
  required_version = ">= 1.1.0"
}

variable "password" {}
variable "email" {}

module "openstack" {
  source         = "git::https://github.com/ComputeCanada/magic_castle.git//openstack?ref=11.9.5"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "11.9.5"

  cluster_name = "unx101-mcgill"
  domain       = "calculquebec.cloud"
  image        = "Rocky-8.6-x64-2022-07"

  instances = {
    mgmt   = { type = "p4-7.5gb", tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "p4-7.5gb", tags = ["login", "public", "proxy"], count = 1 }
    node   = { type = "c8-60gb", tags = ["node"], count = 2 }
  }

  volumes = {
    nfs = {
      home     = { size = 20 }
      project  = { size = 20 }
      scratch  = { size = 20 }
    }
  }

  generate_ssh_key = true
  public_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDrLe7HKWKVDZVp3TCPrnJ7oizZp9PYhYnEiheacll4gTxQbun/hhLE5eXQu7RLpgxfHRMKd55F6YNGdvLP17TcBuG2JOxTFIENb78QiLTveqRZAinz0IFVQ6KnStAQ4IuEi29BY2F0A0ASFup5/cHQFbqHM4fJawc8Qckkp+OgNX31qlKkySnjdSc277LqGkohD4tR3IyA0B/SN19qEsL1lIDlZrrTGjofC0Ej0yI0yit8Ww0CYpjoO4KBzIJsz/CPAxL6ocQNYIln15e/2uQKXuF2iWpJ5KA0QWEYuLA4rON+2UfogCtyvfZUhuQX8NFihVjKMetqBSdafY4y/ggGENTzIivyvr+6gPIStkhnN2XPbu2gBzOekAnzgNYA7IYyHvCwC0dENsYrPQaODk5ArxN6s+m0k+pKiSJAQ6tyKjEnlwQWzMZZU4PTmydgMfJvuqRCL4DNcKBLGt9JmUu9+IYl5E++EPeR3zeH3EyQGHW75xmG8TUMGj49DSamwfc= Pier-Luc@Edge1",
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
  source           = "git::https://github.com/ComputeCanada/magic_castle.git//dns/cloudflare?ref=11.9.5"
  email            = var.email
  name             = module.openstack.cluster_name
  domain           = module.openstack.domain
  public_instances = module.openstack.public_instances
  ssh_private_key  = module.openstack.ssh_private_key
  sudoer_username  = module.openstack.accounts.sudoer.username
}
