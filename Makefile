WP_CLI_HOST ?= vagrant
DATABASE_EXPORT ?= database.sql

all:

# Virtual Machine -------------------------------------------------------------
#
# To scaffold the files for the VM run `make vm`. After that simply provision
# it.

vm:
	cp -r lib/drupal-vm vm
	ln -sf ../config/drupal-vm.config.yml vm/config.yml
	ln -sf ../config/Vagrantfile vm/Vagrantfile

vm-clean:
	rm -rf vm

# Database --------------------------------------------------------------------
#
# To get a dump from the VM run `make database.sql`

$(DATABASE_EXPORT):
	wp ssh db export - --host=$(WP_CLI_HOST) >| $(DATABASE_EXPORT)

# Files -----------------------------------------------------------------------

vm-fetch-files:
	vagrant ssh-config --host default > /tmp/vagrant-ssh-config
	rsync -r -e 'ssh -F /tmp/vagrant-ssh-config' default:/var/www/wordpress/web/app/uploads/ web/app/uploads/
	rm -f /tmp/vagrant-ssh-config

.PHONY: all vm-clean vm-fetch-files
