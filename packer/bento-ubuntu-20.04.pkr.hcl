# =====================================================================================================================
# OS: Ubuntu Server 20.04
#
# Based on: https://github.com/chef/bento/blob/main/packer_templates/ubuntu/ubuntu-20.04-amd64.json
# =====================================================================================================================

variable "box_basename" {
  type    = string
  default = "ubuntu-20.04"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "disk_size" {
  type    = number
  default = 65536
}

variable "git_revision" {
  type    = string
  default = "__unknown_git_revision__"
}

variable "guest_additions_url" {
  type    = string
  default = ""
}

variable "headless" {
  type    = bool
  default = false
}

variable "http_proxy" {
  type    = string
  default = "${env("http_proxy")}"
}

variable "https_proxy" {
  type    = string
  default = "${env("https_proxy")}"
}

variable "iso_checksum" {
  type    = string
  default = "28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad"
}

variable "iso_name" {
  type    = string
  default = "ubuntu-20.04.4-live-server-amd64.iso"
}

# The amount of memory to use for building the VM in megabytes
variable "memory" {
  type    = number
  default = 1024
}

variable "mirror" {
  type    = string
  default = "http://releases.ubuntu.com"
}

variable "mirror_directory" {
  type    = string
  default = "focal"
}

variable "name" {
  type    = string
  default = "ubuntu-20.04"
}

variable "no_proxy" {
  type    = string
  default = "${env("no_proxy")}"
}

// variable "preseed_path" {
//   type    = string
//   default = "preseed.cfg"
// }

variable "template" {
  type    = string
  default = "ubuntu-20.04-amd64"
}

// variable "version" {
//   type    = string
//   default = "TIMESTAMP"
// }

locals {
  boxes_dir = "${path.root}/../boxes"
  parent_project_dir = "${path.root}/../vendors/bento"
  parent_project_http_dir = "${local.parent_project_dir}/packer_templates/ubuntu/http"
  parent_project_scripts_dir = "${local.parent_project_dir}/packer_templates/ubuntu/scripts"
  parent_project_common_scripts_dir = "${local.parent_project_dir}/packer_templates/_common"
}

source "virtualbox-iso" "ubuntu" {
  boot_command            = [
    " <wait>",
    " <wait>",
    " <wait>",
    " <wait>",
    " <wait>",
    "<esc><wait>",
    "<f6><wait>",
    "<esc><wait>",
    "<bs><bs><bs><bs><wait>",
    " autoinstall<wait5>",
    " ds=nocloud-net<wait5>",
    ";s=http://<wait5>{{.HTTPIP}}<wait5>:{{.HTTPPort}}/<wait5>",
    " ---<wait5>",
    "<enter><wait5>"
  ]
  boot_wait               = "5s"
  cpus                    = var.cpus
  disk_size               = var.disk_size
  guest_additions_path    = "VBoxGuestAdditions_{{ .Version }}.iso"
  guest_additions_url     = "${var.guest_additions_url}"
  guest_os_type           = "Ubuntu_64"
  hard_drive_interface    = "sata"
  http_directory          = "${local.parent_project_http_dir}"
  iso_checksum            = "${var.iso_checksum}"
  iso_url                 = "${var.mirror}/${var.mirror_directory}/${var.iso_name}"
  memory                  = "${var.memory}"
  // output_directory        = "${local.boxes_dir}/packer-${var.template}-virtualbox"
  shutdown_command        = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_password            = "vagrant"
  ssh_port                = 22
  ssh_timeout             = "10000s"
  ssh_username            = "vagrant"
  virtualbox_version_file = ".vbox_version"
  vm_name                 = "${var.template}"
}

build {
  sources = ["source.virtualbox-iso.ubuntu"]

  provisioner "shell" {
    environment_vars  = [
      "HOME_DIR=/home/vagrant",
      "http_proxy=${var.http_proxy}",
      "https_proxy=${var.https_proxy}",
      "no_proxy=${var.no_proxy}"
    ]
    execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts           = [
      "${local.parent_project_scripts_dir}/update.sh",
      "${local.parent_project_common_scripts_dir}/motd.sh",
      "${local.parent_project_common_scripts_dir}/sshd.sh",
      "${local.parent_project_scripts_dir}/networking.sh",
      "${local.parent_project_scripts_dir}/sudoers.sh",
      "${local.parent_project_scripts_dir}/vagrant.sh",
      "${local.parent_project_common_scripts_dir}/virtualbox.sh",
      "${local.parent_project_scripts_dir}/cleanup.sh",
      "${local.parent_project_common_scripts_dir}/minimize.sh"
    ]
  }

  post-processor "vagrant" {
    output = "${local.boxes_dir}/${var.box_basename}.box"
  }
}
