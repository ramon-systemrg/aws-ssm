Vagrant.configure("2") do |config|

  config.vm.box = "centos7"
  # I am updating this url. I build my own boxes, but you can use what you have.
  config.vm.box_url = "http://go.nsdrg.com/centos7.box"
  config.vm.define "web1" do |web1|
  # I create my own keys since I build my own boxes.
  config.ssh.private_key_path = ['~/.vagrant.d/insecure_private_key']
  config.ssh.insert_key = true
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.network "public_network", :bridge => "eno1", :ip => "10.1.10.190"
  web1.vm.hostname = "web1"
  end

  # Configures provisioners.
  config.vm.provision :shell, :path => "provision.sh"

  # Install this vagrant plugin for this to work:
  # vagrant plugin install vagrant_reboot_linux

  # execute code before reload
  config.vm.provision "shell",
    reboot: true,
    inline: 'echo before reboot'

  # execute code after reload
  config.vm.provision "shell", :path => "/home/ramon/vagrant/post.sh"

end
