service 'awslogs' do
  # awslogs service is created, enabled, and started by the installer at the end of this recipe, but we need to declare
  # a chef resource for the template to notify
  action :nothing
end

template '/tmp/cwlogs.cfg' do
  source 'awslogs.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables ({
    :logfiles => node['cwlogs']['logfiles']
  })
  notifies :restart, 'service[awslogs]'
end

directory '/opt/aws/cloudwatch' do
  recursive true
end

remote_file '/opt/aws/cloudwatch/awslogs-agent-setup.py' do
  source 'https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py'
  mode '0755'
end

proxy_env = ENV.select { |k, v| %w(http_proxy https_proxy no_proxy).include?(k) && !v.empty? }
proxy_args = proxy_env.map { |k,v| "--#{k.gsub('_','-')} '#{v}'" }.join(' ')

python_runtime '2'

python_execute 'run-cloudwatch-logs installer' do
  command "/opt/aws/cloudwatch/awslogs-agent-setup.py -n -r #{node['cwlogs']['region']} -c /tmp/cwlogs.cfg #{proxy_args}"
end
