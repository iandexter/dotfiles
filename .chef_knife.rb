chef_server_url         'https://chef.internal.compareglobal.co.uk:443'
client_key              '/Users/iandexter/.chef/iandexter_node.pem'
cookbook_path           [ '/Users/iandexter/projects/compareglobal/infrastructure/chef-repo/cookbooks' ]
log_level               :info
log_location            STDOUT
node_name               'iandexter_node'
ssl_verify_mode         :verify_none
syntax_check_cache_path '/Users/iandexter/.chef/syntax_check_cache'
validation_client_name  'chef-validator'
validation_key          '/Users/iandexter/.chef/chef-validator.pem'
knife[:editor] = '/usr/bin/vim'
