# Public: Installs Vagrant
#
# Usage:
#
#   include vagrant

class vagrant(
  $version = '1.7.4',
  $completion = false
) {
  validate_bool($completion)

  $ensure_completion = $completion ? {
    true    => 'present',
    default => 'absent',
  }

  package { "Vagrant_${version}":
    ensure   => installed,
    source   => "https://dl.bintray.com/mitchellh/vagrant/vagrant_${version}.dmg",
    provider => 'pkgdmg'
  }

  file { "/Users/${::boxen_user}/.vagrant.d":
    ensure  => directory,
    require => Package["Vagrant_${version}"],
  }

  homebrew::tap { 'homebrew/completions':
    ensure => $ensure_completion,
  }

  package { 'vagrant-completion':
    ensure   => $ensure_completion,
    provider => 'homebrew',
    require  => Homebrew::Tap['homebrew/completions'],
  }
}
