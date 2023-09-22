# =====================================================================================================================
# OS: Ubuntu Server 22.04
#
# Based on: Chef/Bento (https://github.com/chef/bento)
# =====================================================================================================================

packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable box_name {
  type    = string
  default = "ubuntu-22.04-desktop"
}

variable box_version {
  type    = string
  default = "1.0"
}

variable cicd_mode {
  type    = bool
  default = true
  description = "When this value is set to true, the machine will start without a console during VM build"
}

locals {
  build_time = "${formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())}"
  distr = {
    iso_checksum_url = "https://releases.ubuntu.com/jammy/SHA256SUMS"
    iso_url = "https://releases.ubuntu.com/jammy/ubuntu-22.04.3-live-server-amd64.iso"
  }
  # ${path.root} - the directory of this file
  output_box_file = "${path.root}/../boxes/${var.box_name}-${var.box_version}.box"
  bento_dir = "${path.root}/../vendors/bento"
  bento_http_dir = "${local.bento_dir}/packer_templates/http/ubuntu"
  bento_scripts_dir = "${local.bento_dir}/packer_templates/scripts/ubuntu"
  bento_common_scripts_dir = "${local.bento_dir}/packer_templates/scripts/_common"
}

source "virtualbox-iso" "ubuntu" {
  cpus                     = 2  # the number of cpus to use for building the VM
  memory                   = 2048  # the amount of memory to use for building the VM in megabytes
  disk_size                = 20000  # the size, in megabytes, of the hard disk to create for the VM

  boot_command             = [
    "<wait>",
    "c",
    "<wait>",
    "set gfxpayload=keep<enter>",
    "<wait>",
    "linux /casper/vmlinuz quiet autoinstall ds=nocloud-net\\;",
    "s=http://{{.HTTPIP}}:{{.HTTPPort}}/ ---<enter>",
    "<wait>",
    "initrd /casper/initrd<wait><enter>",
    "<wait>",
    "boot<enter>",
    "<wait>"
  ]
  boot_wait                = "5s"
  gfx_accelerate_3d        = true  # true для Desktop
  gfx_controller           = "vmsvga"
  gfx_vram_size            = 128  # 128 для Desktop
  guest_additions_path     = "VBoxGuestAdditions_{{ .Version }}.iso"
  guest_os_type            = "Ubuntu_64"
  hard_drive_interface     = "sata"
  hard_drive_discard       = true
  hard_drive_nonrotational = true
  headless                 = var.cicd_mode
  http_directory           = "${local.bento_http_dir}"
  iso_checksum             = "file:${local.distr.iso_checksum_url}"
  iso_url                  = "${local.distr.iso_url}"
  shutdown_command         = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_password             = "vagrant"
  ssh_username             = "vagrant"
  ssh_timeout              = "1h"
  vboxmanage               = [
    # Hardware VirtualBox settings (see https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm)
    ["modifyvm", "{{ .Name }}", "--audio", "none"],
    ["modifyvm", "{{ .Name }}", "--hwvirtex", "on"],
    ["modifyvm", "{{ .Name }}", "--ioapic", "on"],
    ["modifyvm", "{{ .Name }}", "--nat-localhostreachable1", "on"],
    ["modifyvm", "{{ .Name }}", "--rtcuseutc", "on"],
  ]
  vboxmanage_post          = [
    # General VirtualBox settings (see https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm)
    ["modifyvm", "{{ .Name }}", "--clipboard", "bidirectional"],
    ["modifyvm", "{{ .Name }}", "--description", "Vagrant box: ${var.box_name}, version: ${var.box_version}\n\nPacker build time: ${local.build_time}"],
    ["modifyvm", "{{ .Name }}", "--vrde", "off"], # disable VirtualBox Remote Display Protocol (VRDP)
    # GUI VirtualBox settings
    ["setextradata", "global", "GUI/Customizations", "noStatusBar"],
    ["setextradata", "global", "GUI/MaxGuestResolution", "any"], # remove all limits on guest resolutions
    ["setextradata", "global", "GUI/SuppressMessages", "all"], # disable all notifications (eg, about auto capture keyboard and mouse)
  ]
}

build {
  sources = ["source.virtualbox-iso.ubuntu"]

  provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/vagrant"]
    execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts           = [
      "${local.bento_scripts_dir}/update_ubuntu.sh",
      "${local.bento_common_scripts_dir}/motd.sh",
      "${local.bento_common_scripts_dir}/sshd.sh",
      "${local.bento_scripts_dir}/networking_ubuntu.sh",
      "${local.bento_scripts_dir}/sudoers_ubuntu.sh",
      "${local.bento_common_scripts_dir}/vagrant.sh",
      "${local.bento_common_scripts_dir}/virtualbox.sh",
      "${path.root}/scripts/ubuntu/desktop.sh",  # desktop.sh для Desktop
      "${path.root}/scripts/ubuntu/cleanup.sh",
      "${local.bento_common_scripts_dir}/minimize.sh"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      output = "${local.output_box_file}"
    }
    post-processor "shell-local" {
      environment_vars = [
        "BOX_FILE=${local.output_box_file}",
        "BOX_NAME=${var.box_name}",
        "BOX_VERSION=${var.box_version}",
      ]
      scripts = ["${path.root}/scripts/_local/make_box_metadata.sh"]
    }
  }
}
