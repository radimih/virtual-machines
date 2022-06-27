# virtual-machines
Build and use my virtual machine images

## Сборка своего Vagrant Box

```bash
packer build packer/<имя Packer-шаблона.pkr.hcl>
```

В каталоге `boxes` будет создан соответствующий Vagrant Box (`*.box`) и файл с метаданными (`*.json`).

Созданный Vagrant Box добавлять с помощью команды `vagrant box add` не нужно. Достаточно
в Vagrantfile в параметре `box_url` указать полный путь до файла с метаданными Vagrant Box (`*.json`).

Пример Vagrantfile:

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "<имя Vagrant Box>"
  config.vm.box_url = "file://#{Dir.home()}/workspace/virtual-machines/boxes/<имя Vagrant Box>.json"

  config.vm.provider "virtualbox" do |v|
    v.name = "<имя виртуальной машины в VirtualBox>"
  end
end
```
