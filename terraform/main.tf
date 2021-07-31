variable "docker-registry-vm-name" {
  type    = "string"
  default = "<DOCKER_REGISTRY_VM_NAME>"
}

resource "openstack_compute_keypair_v2" "<DOCKER_REGISTRY_KEY_PAIR_NAME>" {
  name       = "<DOCKER_REGISTRY_KEY_PAIR_NAME>"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0kvQ7WkUo473l/TeUCw3Et8d7HURwRUCrG+QtpPvFwJOx6GQqOGgTmN92O9v6UGCFrRasdafgagaohoubMpMfBl1xnNonCRfN5Har1pBopQjgYyIBPnjbHcbqq6Fci2ggyDiI2lMpYYl9+n3Jcgx+wufF8S+uGTgvHnTL0smtpgvRe1kdpgo6LMTGdM2UXdaRdUlUCg3QWLFxLcSQ8gspVFwxv+2NFKZrH9RnNVqELPeABXKwaW+EjYdkHSQd0eE2CUXDrS4jnXM1FzKZhdClvjjigtLHdUzAh/6wnSyZAJy3pkZW/xuczP2+FsX5F1BJKdXEKodbZ99F Generated-by-Nova"
}

resource "openstack_compute_instance_v2" "docker-registry-vm" {
  name            = "${var.docker-registry-vm-name}"
  image_name      = "<DOCKER_REGISTRY_IMAGE>"
  flavor_name     = "<DOCKER_REGISTRY_FLAVOR>"
  key_pair        = "${openstack_compute_keypair_v2.<DOCKER_REGISTRY_KEY_PAIR_NAME>.name}"
  security_groups = ["default"]

  network {
    name = "<DOCKER_REGISTRY_NETWORK_NAME>"
  }

  user_data = <<-EOF
      #cloud-config
      user: cloud-user
      password: <SSHPASS>
      chpasswd: {expire: False}
      ssh_pwauth: True
      hostname: <DOCKER_REGISTRY_VM_NAME>
      fqdn: <DOCKER_REGISTRY_VM_NAME>
      system_info:
        default_user:
          name: cloud-user
          lock_passwd: false
      write_files:
        - content: |
            127.0.0.1  localhost localhost4 localhost4.localdomain4 <DOCKER_REGISTRY_VM_NAME>
            ::1        localhost localhost6 localhost6.localdomain6 <DOCKER_REGISTRY_VM_NAME>
          path: /etc/hosts
          owner: root:root
          permissions: '0644'
  EOF
}

