# =====================================================================================================================
# OS: Ubuntu Desktop 20.04
#
# Based on: Chef/Bento (https://github.com/chef/bento)
# =====================================================================================================================

variable box_name {
  type    = string
  default = "ubuntu-20.04-desktop"
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
    iso_checksum = "28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad"
    iso_name = "ubuntu-20.04.4-live-server-amd64.iso"
    mirror = "http://releases.ubuntu.com"
    mirror_directory = "focal"
  }
  # ${path.root} - the directory of this file
  output_box_file = "${path.root}/../boxes/${var.box_name}-${var.box_version}.box"
  parent_project_dir = "${path.root}/../vendors/bento"
  parent_project_http_dir = "${local.parent_project_dir}/packer_templates/ubuntu/http"
  parent_project_scripts_dir = "${local.parent_project_dir}/packer_templates/ubuntu/scripts"
  parent_project_common_scripts_dir = "${local.parent_project_dir}/packer_templates/_common"
}

source "virtualbox-iso" "ubuntu" {
  cpus                     = 2  # the number of cpus to use for building the VM
  memory                   = 2048  # the amount of memory to use for building the VM in megabytes
  disk_size                = 20000  # the size, in megabytes, of the hard disk to create for the VM

  boot_command             = [
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
    ";s=http://<wait5>{{ .HTTPIP }}<wait5>:{{ .HTTPPort }}/<wait5>",
    " ---<wait5>",
    "<enter><wait5>"
  ]
  boot_wait                = "5s"
  guest_additions_path     = "VBoxGuestAdditions_{{ .Version }}.iso"
  guest_os_type            = "Ubuntu_64"
  hard_drive_interface     = "sata"
  hard_drive_discard       = true
  hard_drive_nonrotational = true
  headless                 = var.cicd_mode
  http_directory           = "${local.parent_project_http_dir}"
  iso_checksum             = "${local.distr.iso_checksum}"
  iso_url                  = "${local.distr.mirror}/${local.distr.mirror_directory}/${local.distr.iso_name}"
  shutdown_command         = "echo 'vagrant' | sudo -S shutdown -P now"
  ssh_password             = "vagrant"
  ssh_username             = "vagrant"
  ssh_timeout              = "1h"
  vboxmanage               = [
    # Hardware VirtualBox settings (see https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm)
    ["modifyvm", "{{ .Name }}", "--accelerate3d", "on"],
    ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{ .Name }}", "--hwvirtex", "on"],
    ["modifyvm", "{{ .Name }}", "--ioapic", "on"],
    ["modifyvm", "{{ .Name }}", "--rtcuseutc", "on"],
    ["modifyvm", "{{ .Name }}", "--vram", "256"],
  ]
  vboxmanage_post          = [
    # General VirtualBox settings (see https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm)
    ["modifyvm", "{{ .Name }}", "--clipboard", "bidirectional"],
    ["modifyvm", "{{ .Name }}", "--description", "Vagrant box: ${var.box_name}, version: ${var.box_version}\n\nPacker build time: ${local.build_time}"],
    ["modifyvm", "{{ .Name }}", "--vrde", "off"], # disable VirtualBox Remote Display Protocol (VRDP)
    # GUI VirtualBox settings
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
      "${local.parent_project_scripts_dir}/update.sh",
      "${local.parent_project_common_scripts_dir}/motd.sh",
      "${local.parent_project_common_scripts_dir}/sshd.sh",
      "${local.parent_project_scripts_dir}/networking.sh",
      "${local.parent_project_scripts_dir}/sudoers.sh",
      "${local.parent_project_scripts_dir}/vagrant.sh",
      "${local.parent_project_common_scripts_dir}/virtualbox.sh",
      "${path.root}/scripts/ubuntu/desktop.sh",
      "${path.root}/scripts/ubuntu/cleanup.sh",
      "${local.parent_project_common_scripts_dir}/minimize.sh"
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
