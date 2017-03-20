node default {

  $default_packages = [
    'ant',
    'build-essential',
    'curl',
    'git',
    'graphicsmagick',
    'software-properties-common',
    'libgtk-3-0',
    'libasound2',
    'xvfb',
  ]
  package { $default_packages :
    ensure => 'installed',
  }

  file { '/etc/profile.d/xdebug_env_vars.sh':
    # The serverName setting must be the name of server defined in your IDE.
    # For PhpStorm you can set it in Languages & Frameworks > PHP > Servers.
    content => "#!/bin/sh\nexport XDEBUG_CONFIG=''\nexport PHP_IDE_CONFIG='serverName=u2'\n",
  }
  file { '/etc/profile.d/xdebug_env_aliases.sh':
    content => "#!/bin/sh
alias xdebuginfo='printf \"PHP xdebug extension:\\n* cli: %s\\n* fpm: %s\\n\" \"`phpquery -v 7.0 -s cli -m xdebug`\" \"`phpquery -v 7.0 -s fpm -m xdebug`\"'
alias xdebugoncli='sudo phpenmod -s cli xdebug'
alias xdebugoffcli='sudo phpdismod -s cli xdebug'
alias xdebugonfpm='sudo phpenmod -s fpm xdebug && sudo service php7.0-fpm restart'
alias xdebugofffpm='sudo phpdismod -s fpm xdebug && sudo service php7.0-fpm restart'
alias xdebugon='xdebugoncli && xdebugonfpm && xdebuginfo'
alias xdebugoff='xdebugoffcli && xdebugofffpm && xdebuginfo'

if [ -n \"\$PS1\" ]; then
  echo ''
  xdebuginfo
  echo ''
  echo -e \"You can now use xdebug* aliases to enable/disable/query xdebug PHP extension:\\n* xdebugon, xdebugoncli, xdebugonfpm\\n* xdebugoff, xdebugoffcli, xdebugofffpm\\n* xdebuginfo\"
fi
",
  }

  class { '::php':
    package_prefix => 'php-',
    fpm => true,
    composer => true,
    # pear => true,
    phpunit => true,
    extensions => {
      apcu => {},
      bcmath => {},
      curl => {},
      imagick => {},
      intl => {},
      json => {},
      mbstring => {},
      mcrypt => {},
      mysql => {},
      soap => {},
      sqlite3 => {},
      zip => {},
      xdebug => {
        settings => {
          'Xdebug/xdebug.cli_color' => '1',
          'Xdebug/xdebug.default_enable' => '1',
          'Xdebug/xdebug.idekey' => 'PHPSTORM',
          'Xdebug/xdebug.max_nesting_level' => '1000',
          'Xdebug/xdebug.remote_autostart' => '0',
          # 'Xdebug/xdebug.remote_connect_back' => '1',  # does not work for CLI, that's why we have to use: remote_connect_back=0 and remote_host=IP
          'Xdebug/xdebug.remote_connect_back' => '0',
          'Xdebug/xdebug.remote_enable' => '1',
          'Xdebug/xdebug.remote_port' => '9001',
          'Xdebug/xdebug.var_display_max_data' => '1000',
          'Xdebug/xdebug.var_display_max_depth' => '20',
        },
      },
    },
    settings => {
      'Date/date.timezone' => 'Europe/Berlin',
      'PHP/display_errors' => 'On',
      'PHP/display_startup_errors' => 'On',
      'PHP/error_reporting' => 'E_ALL',
      'PHP/html_errors' => 'On',
      'PHP/memory_limit' => '-1',
      'PHP/short_open_tag' => 'Off',
    },
  } ->
  exec { 'disable xdebug':
      command => "sudo phpdismod -s cli xdebug && sudo phpdismod -s fpm xdebug && sudo service php7.0-fpm restart",
      path    => ['/bin/', '/usr/bin', '/usr/local/bin'],
  }

  $web_folder = "/var/www/html"

  class { 'apache':
    default_vhost => false,
  }

  apache::mod { 'actions': }
  apache::mod { 'rewrite': }
  apache::mod { 'proxy': }
  apache::mod { 'proxy_fcgi': }

  apache::vhost { $hostname:
    port => '80',
    docroot => $web_folder,
    default_vhost => true,
    directories => [
      {
        path => $web_folder,
        allow_override => ['All'],
      },
      {
        provider => 'filesmatch',
        path => '\.php$',
        sethandler => 'proxy:fcgi://127.0.0.1:9000',
      },
    ],
  }

  class { 'mysql::server':
    databases => {
      'u2' => {
        ensure => 'present',
        charset => 'utf8',
      },
    },
    users => {
      'u2@%' => {
        ensure => 'present',
      },
    },
    grants => {
      'u2@%/*.*' => {
        ensure => 'present',
        options => ['GRANT'],
        privileges => ['ALL'],
        table => '*.*',
        user => 'u2@%',
      },
    },
    override_options => {
      'mysqld' => {
        'bind-address' => '0.0.0.0',
      },
    },
  }

  class { 'nodejs':
    # Some node.js packages assume /usr/bin/node to be available, the default is /usr/bin/nodejs.
    # For some reason legacy_debian_symlinks must be defined before npm_package_ensure, or npm will not be installed. (Can someone confirm on his dev env?)

    legacy_debian_symlinks => true,
    npm_package_ensure => 'present',
  }

  class { 'firefox' :
    version => '47.0.1',
  } ->
  file { 'create firefox symlink':
    ensure => link,
    path   => '/usr/local/bin/firefox',
    target => '/opt/firefox/firefox',
  }

  package { 'yarn':
    ensure   => 'present',
    provider => 'npm',
  }

  package { 'selenium-standalone':
    ensure   => 'present',
    provider => 'npm',
  } ->
  exec { 'install selenium':
    command => "selenium-standalone install --version=2.53.1",
    path    => ['/bin/', '/usr/bin', '/usr/local/bin'],
  }

  # We could use https://forge.puppet.com/puppet/unattended_upgrades to manage unattended-upgrades, but for now this is enough
  file_line { 'disable unattended-upgrades':
    path => '/etc/apt/apt.conf.d/10periodic',
    line => 'APT::Periodic::Unattended-Upgrade "0";',
  }

}
