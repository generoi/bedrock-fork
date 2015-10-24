set :application, '<example>'
set :repo_url, 'git@github.com:generoi/<example>.git'
set :customer_username, '<example>'

# Hardcodes branch to always be master
# This could be overridden in a stage config file
set :branch, :master

# We are not deploying with deploy user to the JNT server, as the quota would count to that user.
# We deploy using the customer username,
set :deploy_to, -> { "/home/www/#{fetch(:customer_username)}/deploy" }

# Use :debug for more verbose output when troubleshooting
set :log_level, :info

# Apache users with .htaccess files:
# it needs to be added to linked_files so it persists across deploys:
set :linked_files, fetch(:linked_files, []).push('.env')
set :linked_dirs, fetch(:linked_dirs, []).push('web/app/uploads')

# We will after the deploy set all uploaded files to have the permissions of the customer
# So that the quota on the server will be counted towards that user.
set :file_permissions_paths, ["web"]
set :file_permissions_users, [fetch(:customer_username)]

# Slackistrano (change to true)
set :slack_run_starting,     -> { false }
set :slack_run_finishing,    -> { false }
set :slack_run_failed,       -> { false }
# Add an incoming webhook at https://<team>.slack.com/services/new/incoming-webhook
# set :slack_webhook, "https://hooks.slack.com/services/XXX/XXX/XXX"

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :service, :nginx, :reload
    end
  end
end

# The above restart task is not run by default
# Uncomment the following line to run it on deploys if needed
# after 'deploy:publishing', 'deploy:restart'

namespace :deploy do
  desc 'Update WordPress template root paths to point to the new release'
  task :update_option_paths do
    on roles(:app) do
      within fetch(:release_path) do
        if test :wp, :core, 'is-installed'
          [:stylesheet_root, :template_root].each do |option|
            # Only change the value if it's an absolute path
            # i.e. The relative path "/themes" must remain unchanged
            # Also, the option might not be set, in which case we leave it like that
            value = capture :wp, :option, :get, option, raise_on_non_zero_exit: false
            if value != '' && value != '/themes'
              execute :wp, :option, :set, option, fetch(:release_path).join('web/wp/wp-content/themes')
            end
          end
        end
      end
    end
  end
end

# The above update_option_paths task is not run by default
# Note that you need to have WP-CLI installed on your server
# Uncomment the following line to run it on deploys if needed
# after 'deploy:publishing', 'deploy:update_option_paths'
#

after "deploy:publishing", "composer:install"

# After we have put all the files where they should be, we chante ownership from deploy to the customers on all files
namespace :deploy do
  desc 'Change ownership of deployed files'
  task :chown do
    on roles(:app) do
      execute :sudo, "chown -R #{fetch(:customer_username)}:deploy #{release_path}"
      execute :sudo, "chmod g+w #{release_path}"
    end
  end
end

after "composer:install", "deploy:chown"
