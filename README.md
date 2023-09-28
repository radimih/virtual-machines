# virtual-machines

Для сборки Vagrant-образов используется HashiCorp [Packer](https://developer.hashicorp.com/packer).

ПРИМЕЧАНИЯ:

- На **Fedora** лучше просто скачать бинарник утилиты Packer, чем устанавливать его из rpm-репозитория
  HashiCorp, так как в этом репозитории находится и Vagrant, а его предпочтительнее ставить из родного
  репозитория Fedora.

- ВНИМАНИЕ! Загрузка бинарника или доступ к apt/rpm-репозиториям HashiCorp могут быть закрыты из России.

## Сборка своего Vagrant Box

```bash
git submodule update --init
packer init templates/<имя Packer-шаблона.pkr.hcl>
packer build templates/<имя Packer-шаблона.pkr.hcl>
```

В каталоге `boxes` будет создан соответствующий Vagrant Box (`*.box`) и файл с метаданными (`*.json`).

Необходимо периодически обновлять репозитории вендоров:

```bash
git submodule update --remote vendors/bento
```

## Использование своего Vagrant Box

В Vagrantfile указываются параметры:

- `box` - имя Vagrant Box (параметр `box_name` в Packer-шаблоне)
- `box_url` - полный путь до файла с метаданными Vagrant Box (`*.json`):

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "<имя Vagrant Box>"
  config.vm.box_url = "file://#{Dir.home()}/1git/virtual-machines/boxes/<имя Vagrant Box>.json"

  # Отключить использование NFS для Synced Folders, так как это требует прав root
  config.nfs.functional = false

  # Полный список параметров: https://vagrant-libvirt.github.io/vagrant-libvirt/configuration.html

  config.vm.provider :libvirt do |p|
    p.cpus = 2
    p.memory = 4096
  end
end
```

Первый вызов команды `vagrant up` автоматически добавит в Vagrant соответствующий Vagrant Box (`vagrant box list`).

Если Vagrant Box был обновлён, то чтобы изменения вступили в силу, необходимо перед командой `vagrant up`
удалить из Vagrant предыдущий вариант Vagrant Box:

```bash
vagrant box remove <имя Vagrant Box>
```
