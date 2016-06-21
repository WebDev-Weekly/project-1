Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.provision "shell", path: "deploy/setup.sh", args: "local"
  config.vm.network :forwarded_port, host: 8008, guest: 80

  config.vm.synced_folder ".", "/websites/todolist.com"
end