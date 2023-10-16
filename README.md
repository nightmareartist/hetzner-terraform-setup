## Setup Arch Linux instance on Hetzner Cloud

In order to better understand what this code does, please, check out my blog post [Setting up Arch Linux on Hetzner](https://nightmareartist.com/post/null/).

There are a few things that need to be changed before the code is executed.

1. Adjust names and other variables in `instance.tf` and `firewall.tf`
2. Adjust various options in `arch-setup.sh` - one thing that you should definitely change is username of the default user that gets created. If you don't do that you will end up with `myuser` as the default account.
3. Get API token from Hetzner, that is something you need to do manually before you can run Terraform. This token can be used from a secret storage, put temporarily into TF file (don't do that) or added to `apply` command in the following format: `terraform apply -var="hcloud_token=TOKEN_GOES_HERE"`

Once all the requirements are satisfied run:

```hcl
    terraform plan
    terraform apply
```

This setup will create a local Terraform state file. If you want to keep that file in a remote location ie. bucket, the code needs to be adjusted. However, what you have here will be enough to get you going.

### Requirements

| Name                                                 | Version   |
|------------------------------------------------------|-----------|
| [Terraform](https://www.terraform.io/downloads.html) | \>= 1.3.0 |


### License

This project is licensed under the Mozilla Public License Version 2.0 - see the [LICENSE](LICENSE) file for details
