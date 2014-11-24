log_level                :info
log_location             STDOUT
node_name                'iandexter'
client_key               '/Users/iandexter/.chef/iandexter.pem'
validation_client_name   'chef-validator'
validation_key           '/Users/iandexter/.chef/chef-validator.pem'
chef_server_url          'https://chef-server:443'
syntax_check_cache_path  '/Users/iandexter/.chef/syntax_check_cache'
cookbook_path [ '/path/to/chef/repo/cookbooks/' ]
knife[:editor] = '/usr/bin/vim'
