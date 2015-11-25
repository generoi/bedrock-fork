WP_CLI_HOST ?= vagrant
DATABASE_EXPORT ?= database.sql

DEV_HOST ?= <example-project>.dev
PRODUCTION_HOST ?= <example-project>.com
LOCAL_HOST ?= localhost:3000

PRODUCTION_REMOTE_HOST ?= deploy@<example-project>.com:/home/www/<example-project>

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

production-pull-db:
	make db-clean WP_CLI_HOST=production $(DATABASE_EXPORT)
	cat $(DATABASE_EXPORT) | wp ssh db cli --host=vagrant
	make dev-db-search-replace db-clean dev-plugins

production-push-db: $(DATABASE_EXPORT)
	cat $(DATABASE_EXPORT) | wp ssh db cli --host=production
	make production-db-search-replace db-clean

production-db-search-replace:
	wp ssh search-replace --recurse-objects --network '$(DEV_HOST)' '$(PRODUCTION_HOST)' --host=production
	wp ssh search-replace --recurse-objects --network '$(LOCAL_HOST)' '$(PRODUCTION_HOST)' --host=production

dev-db-search-replace:
	wp ssh search-replace --recurse-objects --network '$(PRODUCTION_HOST)' '$(DEV_HOST)' --host=vagrant
	wp ssh search-replace --recurse-objects --network '$(LOCAL_HOST)' '$(DEV_HOST)' --host=vagrant

db-clean:
	rm -f $(DATABASE_EXPORT)

# Files -----------------------------------------------------------------------

dev-fetch-files:
	vagrant ssh-config --host default > /tmp/vagrant-ssh-config
	rsync -r -e 'ssh -F /tmp/vagrant-ssh-config' default:/var/www/wordpress/web/app/uploads/ web/app/uploads/
	rm -f /tmp/vagrant-ssh-config

production-pull-files:
	rsync -v -r -e 'ssh -o ForwardAgent=yes -o ProxyCommand="ssh deploy@minasanor.genero.fi nc %h %p 2> /dev/null"' $(PRODUCTION_REMOTE_HOST)/deploy/current/web/app/uploads/ web/app/uploads/
	vagrant ssh-config --host default >| /tmp/vagrant-ssh-config
	rsync -v -r --no-perms --no-owner --no-group --verbose -e 'ssh -F /tmp/vagrant-ssh-config' web/app/uploads/ default:/var/www/wordpress/web/app/uploads/

production-push-files: dev-fetch-files
	rsync -v -r -e 'ssh -o ForwardAgent=yes -o ProxyCommand="ssh deploy@minasanor.genero.fi nc %h %p 2> /dev/null"' web/app/uploads/ $(PRODUCTION_REMOT_HOST)/deploy/current/web/app/uploads/

# Plugins setup ---------------------------------------------------------------

dev-plugins:
	wp ssh plugin activate debug-bar kint-debugger --host=vagrant
	wp ssh plugin deactivate autoptimize --host=vagrant

.PHONY: all vm-clean vm-fetch-files
