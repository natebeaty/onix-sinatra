# Microcosm Publishing
# Fabfile ONIX Sinatra app to deploy and fire up dev
# nate@clixel.com 2002-?

from fabric import task
from invoke import run as local
from patchwork.transfers import rsync

# linode
remote_path = "/var/www/onix-api/onix-sinatra"
remote_hosts = ["natebeaty@dev.microcosmpublishing.com"]
project_name = "onix-sinatra"
git_branch = "master"

# opalstack
# remote_hosts = ["cosm-www@microcosmpublishing.com"]
# remote_path = "/home/cosm-www/apps/onix-api/onix-sinatra/"
# project_name = "onix-sinatra"
# git_branch = "master"

# deploy
@task(hosts=remote_hosts)
def deploy(c,assets=None):
    update(c)
    bundle(c)
    restart(c)

def update(c):
    c.run("cd {} && git pull origin {}".format(remote_path, git_branch))

def bundle(c):
    c.run("cd {} && bundle install --quiet".format(remote_path))

def restart(c):
    c.run("cd {}; ../stop; ../start".format(remote_path))

@task
def dev(c):
    local("bundle exec rackup -E development config.ru")
