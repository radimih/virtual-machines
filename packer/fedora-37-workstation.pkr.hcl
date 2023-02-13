# =====================================================================================================================
# OS: Fedora Workstation 37
#
# Based on: Chef/Bento (https://github.com/chef/bento)
# =====================================================================================================================

variable box_name {
  type    = string
  default = "fedora-37-workstation"
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
    iso_checksum_url = "https://getfedora.org/static/checksums/37/iso/Fedora-Server-37-1.7-x86_64-CHECKSUM"
    iso_url = "https://download.fedoraproject.org/pub/fedora/linux/releases/37/Server/x86_64/iso/Fedora-Server-dvd-x86_64-37-1.7.iso"
  }
  # ${path.root} - the directory of this file
  output_box_file = "${path.root}/../boxes/${var.box_name}-${var.box_version}.box"
  bento_dir = "${path.root}/../vendors/bento"
  bento_http_dir = "${local.bento_dir}/packer_templates/http/fedora"
  bento_scripts_dir = "${local.bento_dir}/packer_templates/scripts/fedora"
  bento_common_scripts_dir = "${local.bento_dir}/packer_templates/scripts/_common"
}

source "virtualbox-iso" "fedora" {
  cpus                     = 2  # the number of cpus to use for building the VM
  memory                   = 2048  # the amount of memory to use for building the VM in megabytes
  disk_size                = 20000  # the size, in megabytes, of the hard disk to create for the VM

  boot_command             = [
    "<up><up>e<wait><down><down><end> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<F10><wait>"
  ]
  boot_wait                = "5s"
  guest_additions_path     = "VBoxGuestAdditions_{{ .Version }}.iso"
  guest_os_type            = "Fedora_64"
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
    ["setextradata", "global", "GUI/Customizations", "noStatusBar"],
    ["setextradata", "global", "GUI/MaxGuestResolution", "any"], # remove all limits on guest resolutions
    ["setextradata", "global", "GUI/SuppressMessages", "all"], # disable all notifications (eg, about auto capture keyboard and mouse)
  ]
}

build {
  sources = ["source.virtualbox-iso.fedora"]

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
      "${local.bento_common_scripts_dir}/virtualbox.sh",
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
