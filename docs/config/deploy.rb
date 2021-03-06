# config valid only for current version of Capistrano
lock "3.9.0"

set :application, "Brewing_Bits"
set :repo_url, "git@bitbucket.org:Haniyya/brewing-bits.git"
set :repository, '_site'
set :scm, :none
set :deploy_via, :copy
set :copy_compression, :gzip
set :use_sudo, false
role :web, '46.101.42.193'

set :user, 'deploy'
set :deploy_to, "/home/deploy/blog"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", "config/secrets.yml"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  task :clean_jekyll do
    on roles(:web) do
      within "#{deploy_to}/current" do
        execute :bundle, 'exec jekyll clean'
      end
    end
  end

  task :update_jekyll => :clean_jekyll do
    on roles(:web) do
      within "#{deploy_to}/current" do
        execute :bundle, 'exec jekyll build'
      end
    end
  end

  after "deploy:symlink:release", "deploy:update_jekyll"
end
