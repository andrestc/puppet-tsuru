#
# == Class: gandalf
#
#  Tsuru gandalf node
#
# === Parameters
#
# [gandalf_host] Gandalf host to
# [gandalf_ipbind_port] Gandalf ip x port to bind
# [gandalf_db_url] Gandalf mongodb url
# [gandalf_db_name] Gandalf mongodb database name
# [gandalf_repositories_path] Git repository root path
# [gandalf_create_repositories] Create repositories base dir
# [gandalf_bare_template_path] Git base template to use
# [gandalf_create_bare_template] Create bare template dir
# [gandalf_user] Gandalf running user
# [gandalf_group] Gandalf running group
# [gandalf_version] Gandalf server package version
# [tsuru_api_host] Tsuru Server API Host
# [tsuru_api_token] Tsuru API Token


class gandalf (
  $gandalf_host          = 'localhost',
  $gandalf_ipbind_port   = '0.0.0.0:8080',
  $gandalf_db_url        = 'localhost:27017',
  $gandalf_db_name       = 'gandalf',
  $gandalf_repositories_path  = '/var/lib/gandalf/repositories',
  $gandalf_create_repositories = true,
  $gandalf_bare_template_path = '/var/lib/gandalf/bare-template',
  $gandalf_create_bare_template = true,
  $gandalf_user           = 'git',
  $gandalf_group          = 'git',
  $gandalf_version        = 'latest',
  $gandalf_git_daemon     = 'false',
  $tsuru_api_host         = 'localhost:8081',
  $tsuru_api_token        = undef
) {

  require base

  package { 'gandalf-server':
    ensure => $gandalf_version
  }

  file { '/etc/gandalf.conf':
    ensure  => present,
    content => template('gandalf/gandalf.conf.erb'),
    mode    => '0644',
    owner   => root,
    group   => root,
    notify  => Service['gandalf-server'],
  }

  file { '/etc/init/gandalf-server.conf':
    ensure  => present,
    content => template('gandalf/gandalf-server.conf.erb'),
    mode    => '0644',
    owner   => root,
    group   => root,
    notify  => Service['gandalf-server'],
    require => File['/etc/gandalf.conf']
  }

  if ($gandalf_git_daemon) {
    file { '/etc/init/git-daemon.conf':
      ensure  => present,
      content => template('gandalf/git-daemon.conf.erb'),
      mode    => '0644',
      owner   => root,
      group   => root,
      notify  => Service['git-daemon'],
    }

    service { 'git-daemon':
      ensure     => running,
      enable     => true,
      provider   => 'upstart',
      subscribe  => File['/etc/init/git-daemon.conf'],
      require    => File['/etc/init/git-daemon.conf']
    }
  }

  service { 'gandalf-server':
    ensure     => running,
    enable     => true,
    provider   => 'upstart',
    subscribe  => File['/etc/init/gandalf-server.conf'],
    require    => File['/etc/init/gandalf-server.conf']
  }

  if ($gandalf_create_repositories) {
    if ( mkdir_p($gandalf_repositories_path) ) {
      file { $gandalf_repositories_path:
        ensure  => directory,
        recurse => true,
        mode    => '0755',
        owner   => $gandalf_user,
        group   => $gandalf_group
      }
    } else {
      fail("Cannot create and set ${gandalf_repositories_path}")
    }
  }

  if ($gandalf_create_bare_template) {
    if ( mkdir_p($gandalf_bare_template_path) ) {
      file { $gandalf_bare_template_path:
        ensure  => directory,
        recurse => true,
        mode    => '0755',
        owner   => $gandalf_user,
        group   => $gandalf_group
      }
    } else {
      fail("Cannot create and set ${gandalf_bare_template_path}")
    }
  }

}
