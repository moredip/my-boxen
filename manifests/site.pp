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

  git::config::global {
		'user.name' : value => 'Pete Hodgson';
		'user.email' : value => 'git@thepete.net';

		'alias.co' : value => checkout;
		'alias.ff' : value => 'merge --ff-only';
		'alias.l' : value => 'log --graph --pretty=format\':%C(yellow)%h%Cblue%d%Creset %s %C(white) %an, %ar\'';
		'alias.new' : value => '!git init $1 && cd $1 && touch .gitignore && git add .gitignore && git commit -m \'initial commit\' && echo';

		'color.ui' : value => 'auto';

		'push.default' : value => 'simple';
  }


  # fail if FDE is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  include osx::keyboard::capslock_to_control
	include osx::global::tap_to_click
	include osx::dock::autohide
	include osx::dock::clear_dock
	include osx::universal_access::ctrl_mod_zoom

	class { 'osx::dock::hot_corners':
	  top_right => "Put Display to Sleep",
  }


  nodejs::version { '0.12.7': }

  ruby::version { '2.2.3': }

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar',
      'bash-completion',
      'tmux',
      'reattach-to-user-namespace',
			'heroku-toolbelt',
			'awscli',
			's3cmd',
			'maven',
			'postgresql',
			'tree',
			'pstree',
			'docker',
			'docker-machine',
			'ansible'
    ]:
  }

	include brewcask
	package { 'spectacle': provider => 'brewcask' } 
	package { 'dropbox': provider => 'brewcask' } 
	package { 'skype': provider => 'brewcask' } 
	package { 'vlc': provider => 'brewcask' } 
	package { 'google-cloud-sdk': provider => 'brewcask' } 
	package { 'java': provider => 'brewcask' } 

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

  file { "${home}/tmp":
    ensure => directory
  }

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
	include googledrive

	include virtualbox
	include vagrant
}

