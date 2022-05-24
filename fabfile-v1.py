from fabric.api import *

env.hosts = ['microcosm.opalstacked.com']
env.user = 'cosm-www'
env.shell = '/bin/bash -lic' # interactive shell to source .bashrc
env.forward_agent = True
env.project_name = 'onix-sinatra'
env.path = '/home/cosm-www/apps/onix-api/%s' % env.project_name
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
    run('../stop')
    run('../start')

def dev():
  local('bundle exec rackup -E development config.ru')
z