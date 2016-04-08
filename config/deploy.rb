set :application, '<example-project>'
set :repo_url, 'git@github.com:generoi/<example-project>.git'
set :customer_username, '<example-project>'

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
set :linked_dirs, fetch(:linked_dirs, []).push('web/app/uploads', 'web/app/cache')

# We will after the deploy set all uploaded files to have the permissions of the customer
# So that the quota on the server will be counted towards that user.
set :file_permissions_paths, ["web"]
set :file_permissions_users, [fetch(:customer_username)]

set :tail_options,            "-n 100 -f"
set :rsync_options,           "--recursive --times --compress --human-readable --progress"

# Assets
set :assets_compile,          "npm run-script build"
set :assets_output,           %w[web/app/themes/<example-project>/dist web/app/themes/<example-project>/bower_components]

# Slackistrano (change to true)
set :slack_run_starting,     -> { false }
set :slack_run_finishing,    -> { false }
set :slack_run_failed,       -> { false }
# Add an incoming webhook at https://<team>.slack.com/services/new/incoming-webhook
# set :slack_webhook, "https://hooks.slack.com/services/XXX/XXX/XXX"

# Task definitions
namespace :deploy do
  desc 'Change ownership of deployed files'
  task :chown do
    on roles(:app) do
      execute :sudo, "chown -R #{fetch(:customer_username)}:deploy #{release_path}"
      execute :sudo, "chmod -R g+w #{release_path}"
    end
  end

end

namespace :cache do
  desc 'Flush WP Super Cache'
  task 'flush-wpcc' do
    on roles(:app) do
      within current_path do
        begin
          execute :sudo, :chown, '-Rf', 'deploy:deploy', 'web/app/cache/supercache'
          execute :rm, '-rf', 'web/app/cache/supercache/*'
          execute :rm, '-rf', 'web/app/cache/meta/*'
          execute :rm, '-f', 'web/app/cache/wp-cache-*'
        rescue Exception
          # Ignore exceptions as they are throw if * expands to nothing
        end
      end
    end
  end

  desc 'Flush Autoptimize Cache'
  task 'flush-autoptimize' do
    on roles(:app) do
      within current_path do
        begin
          execute :sudo, :chown, '-Rf', 'deploy:deploy', 'web/app/cache/autoptimize/*'
          execute :rm, '-rf', 'web/app/cache/autoptimize/*'
        rescue Exception
          # Ignore exceptions as they are throw if * expands to nothing
        end
      end
    end
  end
end

# Sanity check
before "deploy:starting", "deploy:check:pushed"
before "deploy:starting", "deploy:check:assets"
before "deploy:starting", "deploy:check:sshagent"

# Install plugins
before "deploy:updated", "composer:install"
# Compiled and rsync assets
after "deploy:updated", "assets:push"

# Change the file owner to the customer
after "deploy:updated", "deploy:chown"
# Clear the cache
after "deploy:published", "cache:flush-autoptimize"
after "deploy:published", "cache:flush-wpcc"
