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

=head3 module_info([$name])

Return the module details:

=over 4

=item B<class>

The class of the object as C<Class::Name>.

=item B<filename>

The module filename (converted as C<Class::Name> to C<Class/Name.pm>.

=item B<location>

The file location as C<$INC{"Class/Name.pm"}>.

=item B<dirname>

the directory where the module lies (the same as C<dirname $INC{"Class/Name.pm"}>).

=item B<moduledir>

Assume the module has submodules and return the directory name next to the file location (the same as C<$INC{"Class/Name.pm"} =~ s{\.pm$}{}>).

=back

=cut

sub module_info {
	my ( $self, $name ) = @_;
	$self = ref $self || $self;

	my %spec = ();

	$spec{class} = $self;

	$self =~ s{::}{/}g;
	$self .= ".pm";
	$spec{filename} = $self;

	$self = $INC{$self};
	$spec{location} = $self;

	( $spec{moduledir} = $self ) =~ s{\.pm$}{};
	( $spec{dirname}   = $self ) =~ s{/[^/]+$}{};

	return ( $name && grep { $name eq $_ } keys %spec )
		? $spec{$name}
		: %spec;
}

=head3 commands()

List the application commands.

=cut

sub commands {
    my ( $class, $include_alias ) = @_;

    my $dir = $class->module_info("moduledir");

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

    my $dir = $class->module_info("moduledir");

    my @sorted_files = sort glob("$dir/*.pm");

    return @sorted_files;
}

1;
