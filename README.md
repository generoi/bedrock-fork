# <example-project>

> **Note, here's a [diff of commits availabe upstream](https://github.com/generoi/bedrock/compare/genero...roots:master)**

Bedrock is a modern WordPress stack that helps you get started with the best development tools and project structure.

Much of the philosophy behind Bedrock is inspired by the [Twelve-Factor App](http://12factor.net/) methodology including the [WordPress specific version](https://roots.io/twelve-factor-wordpress/).

## Features

* Better folder structure
* Dependency management with [Composer](http://getcomposer.org)
* Easy WordPress configuration with environment specific files
* Environment variables with [Dotenv](https://github.com/vlucas/phpdotenv)
* Autoloader for mu-plugins (use regular plugins as mu-plugins)
* Enhanced security (separated web root and secure passwords with [wp-password-bcrypt](https://github.com/roots/wp-password-bcrypt))

Use [Trellis](https://github.com/roots/trellis) for additional features:

* Easy development environments with [Vagrant](http://www.vagrantup.com/)
* Easy server provisioning with [Ansible](http://www.ansible.com/) (Ubuntu 14.04, PHP 7, MariaDB)
* One-command deploys

See a complete working example in the [roots-example-project.com repo](https://github.com/roots/roots-example-project.com).

## Requirements

* PHP >= 5.6
* Composer - [Install](https://getcomposer.org/doc/00-intro.md#installation-linux-unix-osx)

## Installation

### Local development

    git clone --recursive git@github.com:generoi/<example-project>.git <example-project>
    cd <example-project>

    # Setup git hooks
    ./lib/git-hooks/install.sh

    # Install dependencies
    bundle
    composer install

    # Setup the ENV variables (pre-configured for the VM)
    cp .env.example .env

    # Build the VM
    vagrant up --provision

    # To sync files from your computer to the virtual machine, run
    vagrant gatling-rsync-auto

    # Install theme dependencies
    # If npm install fails, make sure you have the lastest node and npm installed
    cd web/app/themes/example
    npm install
    bower install

#### Using WP-CLI locally

Install the WP-CLI together with the SSH command

    composer global require wp-cli/wp-cli
    composer global require x-team/wp-cli-ssh dev-master

Usage (eg how to import a db from local)

    wp ssh db cli --host=vagrant < dump.sql

### minasanor.genero.fi

#### Clone the git repo

Do this in you /var/www/u/USERNAME/ forlder on the dev server, unless you use
a VM on your own machine with vagrant, than this will be the "site" folder....

    git clone --recursive git@github.com:generoi/<example-project>.git <example-project>

#### Fetch what is needed

Fetch both the needed php (to build the site with its plugins and fetch wp
core) and ruby code (that capistrano needs) by running

    bundle
    composer install

    cd web/app/themes/<example-project>
    npm install
    bower install

if composer complains, do the composer udpate using the `--ignore-platform-reqs` flag

    composer update --ignore-platform-reqs

if capistrano complains that somethings is missing, it might be that you need
to run bundle again if the Capfile has been updated what it requires but it has
not yet been fetched

#### Set up database and Wordpress

1. Create a new project in a new folder for your project:

  `composer create-project roots/bedrock your-project-folder-name`

2. Copy `.env.example` to `.env` and update environment variables:
  * `DB_NAME` - Database name
  * `DB_USER` - Database user
  * `DB_PASSWORD` - Database password
  * `DB_HOST` - Database host
  * `WP_ENV` - Set to environment (`development`, `staging`, `production`)
  * `WP_HOME` - Full URL to WordPress home (http://example.com)
  * `WP_SITEURL` - Full URL to WordPress including subdirectory (http://example.com/wp)
  * `AUTH_KEY`, `SECURE_AUTH_KEY`, `LOGGED_IN_KEY`, `NONCE_KEY`, `AUTH_SALT`, `SECURE_AUTH_SALT`, `LOGGED_IN_SALT`, `NONCE_SALT`

  If you want to automatically generate the security keys (assuming you have wp-cli installed locally) you can use the very handy [wp-cli-dotenv-command][wp-cli-dotenv]:

      wp package install aaemnnosttv/wp-cli-dotenv-command

      wp dotenv salts regenerate

  Or, you can cut and paste from the [Roots WordPress Salt Generator][roots-wp-salt].

3. Add theme(s) in `web/app/themes` as you would for a normal WordPress site.

4. Set your site vhost document root to `/path/to/site/web/` (`/path/to/site/current/web/` if using deploys)

5. Access WP admin at `http://example.com/wp/wp-admin`

## Setup a new repository

1. Clone the repo - `git clone --recursive git@github.com:generoi/bedrock.git foobar`
2. Clone the theme

    ```sh
    cd foobar/web/app/themes;

    # Regular sage
    git clone git@github.com:generoi/sage.git foobar
    # Alternatively the Timber version
    git clone -b timber git@github.com:generoi/sage.git foobar

    # Delete the git files
    rm -rf foobar/.git

    # Install NPM and Bower packages
    npm install
    bower install

    # Return to the root of the project
    cd -
    ```

3. Setup git hooks `./lib/git-hooks/install.sh`
4. Install dependencies `bundle; composer install`
5. Setup the ENV variables (pre-configured for the VM) `cp .env.example .env`
6. Rename everything (relies on your theme being named the same as the repository)

    ```sh
    # Search and replace all references to the project
    find . -type f -print0 | xargs -0 sed -i 's/<example-project>/foobar/g'

    # You need to manually setup the production host in:
    # - `Makefile`
    # - `config/deploy/production.rb`
    # - `wp-cli.yml`
    ```

7. Setup the new remote git repository

    ```sh
    # Remove the existing master branch (bedrocks own)
    git branch -D master

    # Switch to a new master branch for this project
    git checkout -b master

    # Create a new repository on github
    open https://github.com/organizations/generoi/repositories/new

    # Set origin url to to the newly created github repository
    git remote set-url origin git@github.com:generoi/<example-project>.git

    # Push the code
    git push -u origin master
    ```

7. Setup the VM

    ```sh
    # Change the VM IP to something unique
    vim config/local.config.yml

    # Build the VM
    vagrant up --provision

    # To sync files from your computer to the virtual machine, run
    vagrant rsync-auto
    ```

## Deploys

There are two methods to deploy Bedrock sites out of the box:

* [Trellis](https://github.com/roots/trellis)
* [bedrock-capistrano](https://github.com/roots/bedrock-capistrano)

Any other deployment method can be used as well with one requirement:

`composer install` must be run as part of the deploy process.

## Documentation

Bedrock documentation is available at [https://roots.io/bedrock/docs/](https://roots.io/bedrock/docs/).

## Contributing

Contributions are welcome from everyone. We have [contributing guidelines](https://github.com/roots/guidelines/blob/master/CONTRIBUTING.md) to help you get started.

## Community

Keep track of development and community news.

* Participate on the [Roots Discourse](https://discourse.roots.io/)
* Follow [@rootswp on Twitter](https://twitter.com/rootswp)
* Read and subscribe to the [Roots Blog](https://roots.io/blog/)
* Subscribe to the [Roots Newsletter](https://roots.io/subscribe/)
* Listen to the [Roots Radio podcast](https://roots.io/podcast/)

[roots-wp-salt]:https://roots.io/salts.html
[wp-cli-dotenv]:https://github.com/aaemnnosttv/wp-cli-dotenv-command
