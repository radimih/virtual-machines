# virtual-machines
Build and use my virtual machine images

## Сборка своего Vagrant Box

Пример Vagrantfile:

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "<имя Vagrant Box>"
  config.vm.box_url = "file://#{Dir.home()}/workspace/virtual-machines/boxes/<имя Vagrant Box>.json"

  config.vm.provider "virtualbox" do |v|
    v.name = "<имя виртуальной машины>"
  end
end
```
