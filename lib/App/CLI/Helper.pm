package App::CLI::Helper;

use strict;
use warnings;

use File::Basename qw( basename );

sub import {
    no strict 'refs';
    my $caller = caller;
    for (qw(commands files prog_name)) {
        *{ $caller . "::$_" } = *$_;
    }
}

=head3 mloc([$mode])

Return the module location depending on the C<$mode> as follows:

=over 4

=item C<+1> stands for the file name (converts C<Class::Name> to C<Class/Name.pm>)

=item C<0> or I<nothing> stands for the file location (assumes C<$INC{"Class/Name.pm"}>)

=item C<-1> stands for the upper directory name as C<dirname $INC{"Class/Name.pm"}>

=item C<-2> stands for the directory name supposed to be the upper directory for underlying modules

=back

=cut

sub mloc {
	my ( $self, $mode ) = @_;
	$self = ref $self || $self;

	$self =~ s{::}{/}g;
	$self .= ".pm";
	return $self if $mode > 0;

	$self = $INC{$self};
	return $self unless $mode;

	$self and ( $self ) =~ $mode < -1 ? qr{\.pm$} : qr{/[^/]+$};
	return $self;
}

=head3 commands()

List the application commands.

=cut

sub commands {
    my ( $class, $include_alias ) = @_;

    my $dir = $class->mloc(-2);

    my @cmds = map { ($_) = m{^\Q$dir\E/(.*)\.pm}; lc($_) } $class->files;

    if ( $include_alias and ref $class and $class->can('alias') ) {
        my %aliases = $class->alias;
        push @cmds, $_ foreach keys %aliases;
    }
    my @sorted_cmds = sort @cmds;

    return @sorted_cmds;
}

=head3 prog_name()

The name of the program running your application. This will default to
C<basename $0>, but can be overridden from within your application.

=cut

{
    my $default;

    sub prog_name {
        my $self = shift;

        $default ||= basename $0;
        return $default unless ref $self;

        $self->{prog_name} //= $default;
        return $self->{prog_name};
    }
}

=head3 files()

Return module files of subcommands of first level

=cut

sub files {
    my $class = shift;

    my $dir = $class->mloc(-2);

    my @sorted_files = sort glob("$dir/*.pm");

    return @sorted_files;
}

1;
