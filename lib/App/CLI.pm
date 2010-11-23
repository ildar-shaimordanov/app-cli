package App::CLI;
our $VERSION = '0.103';
use strict;
use warnings;

=head1 NAME

App::CLI - Dispatcher module for command line interface programs

=head1 SYNOPSIS

    package MyApp;
    use base 'App::CLI';        # the DISPATCHER of your App
                                # it's not necessary putting the dispather on the top level of your App

    package main;

    MyApp->dispatch;            # call dispather in where you want

    package MyApp::List;
    use base qw(App::CLI::Command); # any (SUB)COMMAND of your App

    use constant options => qw( 
        "h|help"   => "help",
        "verbose"  => "verbose",
        'n|name=s'  => 'name',
    );

    use constant subcommands => qw(User Nickname); # if you want subcommands

    sub run {
        my ($self, @args) = @_;

        print "verbose" if $self->{verbose};
        my $name = $self->{name}; # get arg following long option --name

        if ($self->{help}) {
            # if $ myapp list --help or $ $ myapp list -h
            # just only output PODs
        } else {
            $subcmd = $self->cascading;
            if ($subcmd) {
                $subcmd->run_command; # if you want to invoke MyApp::List::User or MyApp::List::Nickname
            } else {
                # do something that without subcommand
                # or die as below
                $self->error_cmd;
            }
        }
    }

    package MyApp::List::User;
    use base qw(App::CLI::Command);

    sub run {
        my ($self,@args) = @_;
        # code for listing user
    }

    pakcage MyApp::List::Nickname;
    use base qw(App::CLI::Command);

    sub run {
        my ($self,@args) = @_;
        # code for listing nickname
    }


    package MyApp::Help;
    use base 'App::CLI::Command::Help';

    use constant options => (
        'verbose' => 'verbose',
    );

    sub run {
        my ($self, @arg) = @_;
        # do something
        $self->SUPER(@_); # App::CLI::Command::Help would output PDOs of each command
    }

=head1 DESCRIPTION

C<App::CLI> dispatches CLI (command line interface) based commands
into command classes.  It also supports subcommand and per-command
options.

=cut

use Getopt::Long ();

use constant alias => ();
use constant global_options => ();
use constant options => ();

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub prepare {
    my $class = shift;
    my $data = {};

    $class->_getopt(
        [qw(no_ignore_case bundling pass_through)],
        _opt_map($data, $class->global_options)
    );

    my $cmd = shift @ARGV;
    $cmd = $class->get_cmd($cmd, @_, %$data);

    $class->_getopt(
        [qw(no_ignore_case bundling)],
		_opt_map($cmd, $cmd->command_options)
    );

    return $cmd;
}

sub _getopt {
    my $class = shift;
    my $config = shift;
    my $p = Getopt::Long::Parser->new;
    $p->configure(@$config);
    my $err = '';
    local $SIG{__WARN__} = sub { my $msg = shift; $err .= "$msg" };
    die $class->error_opt ($err)
	unless $p->getoptions(@_);
}

sub dispatch {
    my $class = shift;
    my $cmd = $class->prepare(@_);
    $cmd->subcommand;
    $cmd->run_command(@ARGV);
}

sub _cmd_map {
    my ($pkg, $cmd) = @_;
    my %alias = $pkg->alias;
    $cmd = $alias{$cmd} if exists $alias{$cmd};
    return ucfirst($cmd);
}

sub error_cmd {
    "Command not recognized, try $0 --help.\n";
}

sub error_opt { $_[1] }

sub command_class { $_[0] }

sub get_cmd {
    my ($class, $cmd, @arg) = @_;
    die $class->error_cmd
	unless $cmd && $cmd =~ m/^[?a-z]+$/;
    my $pkg = join('::', $class->command_class, $class->_cmd_map ($cmd));

    my $file = "$pkg.pm";
    $file =~ s!::!/!g;
    eval {require $file; };

    unless ($pkg->can('run')) {
        warn $@ if $@ and exists $INC{$file};
        die $class->error_cmd;
    }

    $cmd = $pkg->new (@arg);
    $cmd->app ($class);

    return $cmd;
}

sub _opt_map {
    my ($self, %opt) = @_;
    return map { $_ => ref($opt{$_}) ? $opt{$_} : \$self->{$opt{$_}}} keys %opt;
}

sub commands {
    my $class = shift;
    $class =~ s{::}{/}g;
    my $dir = $INC{$class.'.pm'};
    $dir =~ s/\.pm$//;
    return sort map { ($_) = m{^\Q$dir\E/(.*)\.pm}; lc($_) } $class->files;
}

sub files {
    my $class = shift;
    $class =~ s{::}{/}g;
    my $dir = $INC{$class.'.pm'};
    $dir =~ s/\.pm$//;
    return sort glob("$dir/*.pm");
}

=head1 TODO

More documentation

=head1 SEE ALSO

L<App::CLI::Command>
L<Getopt::Long>

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>
Cornelius Lin  E<lt>cornelius.howl@gmail.comE<gt>
shelling       E<lt>navyblueshellingford@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2005-2006 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
