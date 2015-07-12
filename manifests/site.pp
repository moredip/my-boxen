require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $boxen_user,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::homebrewdir}/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::boxen_user}"
  ]
}

File {
  group => 'staff',
  owner => $boxen_user
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => File["${boxen::config::bindir}/boxen-git-credential"],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # core modules, needed for most things
  include dnsmasq
  include git
  include hub
  # include nginx

  # fail if FDE is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  include osx::keyboard::capslock_to_control
	include osx::global::tap_to_click
	include osx::dock::autohide
	include osx::dock::clear_dock
	include osx::universal_access::ctrl_mod_zoom


  # node versions
  # nodejs::version { 'v0.6': }
  # nodejs::version { 'v0.8': }
  # nodejs::version { 'v0.10': }

  # default ruby versions
  ruby::version { '1.9.3': }
  # ruby::version { '2.0.0': }
  # ruby::version { '2.1.0': }
  # ruby::version { '2.1.1': }
  ruby::version { '2.1.2': }

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar',
      'tmux'
    ]:
  }

  include chrome
  include macvim

  file { "/usr/local/bin":
    ensure => directory
  }
  file { "/usr/local/bin/mvim":
    ensure => link,
    target => "/opt/boxen/homebrew/Cellar/macvim/7.4-77/bin/mvim"
  }

  $home = "/Users/${::boxen_user}"
  $dotfiles_dir = "${home}/dotfiles"

  repository { $dotfiles_dir:
    source => "moredip/dotfiles"
  }

  exec { "install dotfiles":
    cwd      => $dotfiles_dir,
    command  => "./install.rb",
    provider => shell,
    creates  => "${home}/.vimrc",
    require  => Repository[$dotfiles_dir]
  }
  

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }

	include onepassword

	include dropbox
}

