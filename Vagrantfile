Vagrant.configure("2") do |config|
  config.vm.box = "bento/fedora-42"
  config.vm.box_architecture = "arm64"
  config.vm.hostname = "cloudbyte"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "cloudbyte-linux-project"
    vb.cpus = 2
    vb.memory = 2048
  end
end
