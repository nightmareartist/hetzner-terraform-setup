variable "hcloud_token" {
  description = "Token used to connect to Hetzner."
  default     = ""
  type        = string
  sensitive   = true
}

variable "allow_deprecated_images" {
  description = "Enable the use of deprecated images (default: false)."
  type        = bool
  default     = false
}

variable "backups" {
  description = "Enable backup (extra costs)"
  type        = bool
  default     = false
}

variable "delete_protection" {
  description = "Protect VPS from being delete by accident"
  type        = bool
  default     = true
}

variable "ignore_remote_firewall_ids" {
  description = "Ignores any updates to the firewall_ids argument which were received from the server."
  type        = bool
  default     = false
}

variable "image" {
  description = "Default OS that VM will start up with."
  type        = string
  default     = "debian-11"
}

variable "iso" {
  description = "ISO image to mount to the server."
  type        = string
  default     = "archlinux-2022.06.01-x86_64.iso"
}

variable "keep_disk" {
  description = "If true, do not upgrade the disk. This allows downgrading the server type later."
  type        = bool
  default     = false
}

variable "location" {
  description = "Location of Hetzner data center."
  default     = "hel1"
  type        = string
}

variable "rebuild_protection" {
  description = "Enable or disable rebuild protection (Needs to be the same as delete_protection)."
  type        = bool
  default     = true
}

variable "server_type" {
  description = "Hetzner VPS server type."
  type        = string
  default     = "cx11"
}

