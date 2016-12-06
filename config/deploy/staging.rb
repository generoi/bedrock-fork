set :stage,     :staging
set :app_url,   'http://<example-project>.web.staging.minasanor.genero.fi'
set :deploy_to, '/var/www/staging/<example-project>'

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
role :app, %w{deploy@minasanor.genero.fi}
role :web, %w{deploy@minasanor.genero.fi}
role :db,  %w{deploy@minasanor.genero.fi}

set :ssh_options, {
  forward_agent: true
}
