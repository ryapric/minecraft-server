Vagrant.configure("2") do |config|
  box = "debian/bullseye64"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus   = 1
    vb.memory = 1024
  end

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.define "minecraft" do |mc|
    mc.vm.box = box
    mc.vm.network "forwarded_port", guest: 19132, host: 19132, protocol: "udp"
    mc.vm.synced_folder ".", "/vagrant", disabled: true

    mc.vm.provision "file", source: "./bedrock-server-cfg", destination: "/tmp/bedrock-server-cfg"
    mc.vm.provision "file", source: "./scripts", destination: "/tmp/scripts"

    mc.vm.provision "shell",
      inline: <<-SCRIPT
        export version=''
        bash /tmp/scripts/init.sh vagrant
      SCRIPT
  end
end
