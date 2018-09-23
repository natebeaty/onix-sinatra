from fabric.api import *

env.hosts = ['microcosmpublishing.com']
env.user = 'microcosmpub'
env.project_name = 'onix-sinatra'
env.path = '/home/microcosmpub/webapps/passenger/%s' % env.project_name
env.git_branch = 'master'

def deploy():
  update()
  bundle()
  restart()

def update():
  with cd(env.path):
    run('git pull origin %s' % env.git_branch)

def bundle():
  with cd(env.path):
    run('bundle install --quiet')

def restart():
  with cd(env.path):
    run('../bin/restart')

def dev():
  local('bundle exec rackup -E development config.ru')
