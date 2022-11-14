bedrock_server_version = "1.19.40"
java_server_version    = "1.19.2"

Vagrant.configure("2") do |config|
  box = "debian/bullseye64"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus   = 2
    vb.memory = 2048
  end

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.define "bedrock" do |mc|
    mc.vm.box = box

    ["tcp", "udp"].each do |protocol|
      mc.vm.network "forwarded_port", guest: 19132, host: 19132, protocol: protocol
    end

    mc.vm.synced_folder ".", "/vagrant", disabled: true

    mc.vm.provision "file", source: "./server-cfg", destination: "/tmp/server-cfg"
    mc.vm.provision "file", source: "./scripts", destination: "/tmp/scripts"

    mc.vm.provision "shell",
      inline: <<-SCRIPT
        bash /tmp/scripts/init.sh bedrock #{bedrock_server_version} vagrant
      SCRIPT
  end

  config.vm.define "java" do |mc|
    mc.vm.box = box

    ["tcp", "udp"].each do |protocol|
      mc.vm.network "forwarded_port", guest: 25565, host: 25565, protocol: protocol # Java port
      mc.vm.network "forwarded_port", guest: 19132, host: 19132 + 1, protocol: protocol # Bedrock port
    end

    mc.vm.synced_folder ".", "/vagrant", disabled: true

    mc.vm.provision "file", source: "./server-cfg", destination: "/tmp/server-cfg"
    mc.vm.provision "file", source: "./scripts", destination: "/tmp/scripts"

    mc.vm.provision "shell",
      inline: <<-SCRIPT
        bash /tmp/scripts/init.sh java #{java_server_version} vagrant
      SCRIPT
  end
end
