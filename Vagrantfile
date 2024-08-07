# You can set these yourself, but they're expected to be passed in the Makefile
bedrock_version = ENV["bedrock_version"]
java_version    = ENV["java_version"]
level_name      = ENV["level_name"]

if not bedrock_version or not java_version
  puts "WARNING: You typically must provide version strings for the Minecraft server editions -- did you forget to call this from the Makefile?"
  # exit 1
end

Vagrant.configure("2") do |config|
  box = "debian/bookworm64"

  cpus   = 2
  memory = 2048

  config.vm.provider "libvirt" do |lv|
    lv.cpus = cpus
    lv.memory = memory
  end

  config.vm.provider "virtualbox" do |vb|
    vb.cpus   = cpus
    vb.memory = memory
  end
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.define "bedrock" do |mc|
    mc.vm.box = box

    # NOTE: at the moment, UDP forwarding isn't actually supported in
    # vagrant-libvirt, and so the server cannot be reached from outside the box
    # (and so thusly, not at all)
    ["tcp", "udp"].each do |protocol|
      mc.vm.network "forwarded_port", guest: 19132, host: 19132, protocol: protocol
    end

    mc.vm.synced_folder ".", "/vagrant", disabled: true

    mc.vm.provision "file", source: "./server-cfg", destination: "/tmp/server-cfg"
    mc.vm.provision "file", source: "./scripts", destination: "/tmp/scripts"

    mc.vm.provision "shell",
      inline: <<-SCRIPT
        bash /tmp/scripts/init.sh bedrock #{bedrock_version} vagrant #{level_name}
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
        bash /tmp/scripts/init.sh java #{java_version} vagrant #{level_name}
      SCRIPT
  end
end
