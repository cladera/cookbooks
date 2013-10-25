node[:deploy].each do |app_name, deploy|
  template "#{deploy[:deploy_to]}/current/app/config/parameters.yml" do
      source "parameters.yml.erb"
      mode 0660
      group deploy[:group]

      if platform?("ubuntu")
        owner "www-data"
      elsif platform?("amazon")
        owner "apache"
      end

      variables(
        :host =>     (deploy[:database][:host] rescue nil),
        :user =>     (deploy[:database][:username] rescue nil),
        :password => (deploy[:database][:password] rescue nil),
        :db =>       (deploy[:database][:database] rescue nil),
        :domain =>    (node[:wsapp][:domain] rescue nil),
        :media_bucket => (node[:wsmediabucket] rescue nil),
        :aws_access_key => (node[:awsaccess] rescue nil),
        :aws_secret_key => (node[:awssecret] rescue nil)
      )

     only_if do
       File.directory?("#{deploy[:deploy_to]}/current")
     end
  end
  bash "cache_logs_perms" do
    user "root"
    cwd "#{deploy[:deploy_to]}/current"
    code <<-EOH
    chmod -Rf 777 app/cache
    chmod -Rf 777 app/logs
    EOH
  end
  script "install_composer" do
    interpreter "bash"
    user "root"
    cwd "#{deploy[:deploy_to]}/current"
    code <<-EOH
    curl -s https://getcomposer.org/installer | php
    php composer.phar install
    EOH
  end
end
