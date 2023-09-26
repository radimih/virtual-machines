# =====================================================================================================================
# OS: Fedora Workstation
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
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable box_name {
  type    = string
  default = "fedora-38-workstation"
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
    # Невозможно использовать образ Fedora Workstation, так как для LiveCD не работает способ установки через Kickstart
    # https://docs.fedoraproject.org/en-US/fedora/f36/install-guide/advanced/Kickstart_Installations/#sect-kickstart-howto
    iso_checksum_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-38-1.6-x86_64-CHECKSUM"
    iso_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-dvd-x86_64-38-1.6.iso"
  }
  # ${path.root} - the directory of this file
  output_box_file = "${path.root}/../boxes/${var.box_name}-${var.box_version}.box"
  bento_dir = "${path.root}/../vendors/bento"
  bento_http_dir = "${local.bento_dir}/packer_templates/http/fedora"
  bento_scripts_dir = "${local.bento_dir}/packer_templates/scripts/fedora"
  bento_common_scripts_dir = "${local.bento_dir}/packer_templates/scripts/_common"
}

source "qemu" "fedora" {
  cpus                     = 2  # the number of cpus to use for building the VM
  memory                   = 2048  # the amount of memory to use for building the VM in megabytes
  disk_size                = 20000  # the size, in megabytes, of the hard disk to create for the VM

  boot_command             = [
    "<wait><up><up>e<wait><down><down><end> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<F10><wait>"
  ]
  boot_wait                = "5s"
  headless                 = var.cicd_mode
  http_directory           = "${local.bento_http_dir}"
  iso_checksum             = "file:${local.distr.iso_checksum_url}"
  iso_url                  = "${local.distr.iso_url}"
  shutdown_command         = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_password             = "vagrant"
  ssh_username             = "vagrant"
  ssh_timeout              = "1h"

  # QEMU specific configuration

  accelerator  = "kvm"
  display      = "none"  # allowing QEMU to choose the default
  machine_type = "q35"  # list of machine_type: qemu-system-x86_64 -machine help
  #qemuargs     = local.qemuargs
}

build {
  sources = ["source.qemu.fedora"]

  provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/vagrant"]
    execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts           = [
      "${local.bento_scripts_dir}/networking_fedora.sh",
      "${local.bento_scripts_dir}/update_dnf.sh",
      "${local.bento_scripts_dir}/build-tools_fedora.sh",
      "${local.bento_common_scripts_dir}/motd.sh",
      "${local.bento_common_scripts_dir}/sshd.sh",
      "${local.bento_common_scripts_dir}/vagrant.sh",
      "${path.root}/scripts/fedora/workstation.sh",
      "${local.bento_scripts_dir}/real-tmp_fedora.sh",
      "${local.bento_scripts_dir}/cleanup_dnf.sh",
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
