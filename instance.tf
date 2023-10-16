resource "hcloud_ssh_key" "public-key" {
  name       = "Public key"
  public_key = "PUBLIC_KEY" #UPDATE!
}

resource "hcloud_server" "server" {
  name                       = "server"
  location                   = var.location
  image                      = var.image
  server_type                = var.server_type
  backups                    = var.backups
  delete_protection          = var.delete_protection
  rebuild_protection         = var.rebuild_protection
  ignore_remote_firewall_ids = var.ignore_remote_firewall_ids
  firewall_ids               = [hcloud_firewall.server-fw.id]
  iso                        = var.iso
  ssh_keys                   = [hcloud_ssh_key.public-key.id]

  # Once the server is ready set it up
  connection {
    host    = hcloud_server.server.ipv4_address
    type    = "ssh"
    timeout = "10m"
    agent   = true
    user    = "root"
  }

  provisioner "file" {
    source      = "arch-setup.sh"
    destination = "/root/arch-setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/arch-setup.sh",
      "/root/arch-setup.sh"
    ]
  }
}

