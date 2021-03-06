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
# [gandalf_authorized_keys_path] Path to the authorized_keys file
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
  $gandalf_user_home      = '/var/lib/gandalf',
  $gandalf_authorized_keys_path = '/var/lib/gandalf/.ssh/authorized_keys',
  $gandalf_version        = 'latest',
  $tsuru_api_host         = 'localhost:8081',
  $tsuru_api_token        = undef
) {

  include base

  package { 'gandalf-server':
    ensure  => $gandalf_version,
    require => Class['Base']
  }
  ->
  file { '/etc/gandalf.conf':
    ensure  => present,
    content => template('gandalf/gandalf.conf.erb'),
    mode    => '0644',
    owner   => root,
    group   => root,
    notify  => Service['gandalf-server'],
  }
  ->
  file { '/etc/init/gandalf-server.conf':
    ensure  => present,
    content => template('gandalf/gandalf-server.conf.erb'),
    mode    => '0644',
    owner   => root,
    group   => root,
    notify  => Service['gandalf-server'],
    require => File['/etc/gandalf.conf']
  }

  service { 'gandalf-server':
    ensure    => running,
    enable    => true,
    provider  => 'upstart',
    subscribe => File['/etc/init/gandalf-server.conf'],
    require   => [ File['/etc/init/gandalf-server.conf'] , Package['gandalf-server'] ]
  }

  if ($gandalf_create_repositories) {
    if ( mkdir_p($gandalf_repositories_path) ) {
      file { $gandalf_repositories_path:
        ensure  => directory,
        recurse => true,
        mode    => '0755',
        owner   => $gandalf_user,
        group   => $gandalf_group,
        require => Package['gandalf-server']
      }
    } else {
      fail("Cannot create and set ${gandalf_repositories_path}")
    }
  }

  if ($gandalf_create_bare_template) {
    if ( mkdir_p("${gandalf_bare_template_path}/hooks") ) {
      file { $gandalf_bare_template_path:
        ensure  => directory,
        recurse => true,
        mode    => '0755',
        owner   => $gandalf_user,
        group   => $gandalf_group,
        require => Package['gandalf-server']
      }
    } else {
      fail("Cannot create and set ${gandalf_bare_template_path}")
    }
  }

  file { "${gandalf_bare_template_path}/hooks/pre-receive":
    ensure  => file,
    recurse => true,
    mode    => '0755',
    owner   => $gandalf_user,
    group   => $gandalf_group,
    source  => 'puppet:///modules/gandalf/pre-receive',
    require => File[$gandalf_bare_template_path]
  }

  file { "${gandalf_user_home}/.profile":
    ensure  => file,
    mode    => '0755',
    owner   => $gandalf_user,
    group   => $gandalf_group,
    content => template('gandalf/git-profile.erb'),
    require => Package['gandalf-server']
  }

}
