namespace :deploy do
  task :update_jekyll do
    on roles(:app) do
      within "#{deploy_to}/current" do
        execute :bundle, 'install'
        execute :bundle, 'exec jekyll build'
      end
    end
  end

  after "deploy:symlink:release", "deploy:update_jekyll"
end
