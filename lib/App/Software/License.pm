package App::Software::License;
# ABSTRACT: commandline interface to Software::License

use Moose;
use MooseX::Types::Moose qw/Str Num Maybe/;
use File::HomeDir;
use File::Spec::Functions qw/catfile/;

use namespace::clean -except => 'meta';

with qw/MooseX::Getopt MooseX::SimpleConfig/;

=head1 SYNOPSIS

    software-license --holder 'J. Random Hacker' --license Perl_5 --type notice

=head1 DESCRIPTION

This module provides a commandline interface to Software::License. It can be
used to easily produce license notices to be included in other documents.

All the attributes documented below are available as commandline options
through L<MooseX::Getopt> and can also be configured in
L<$HOME/.software_license.conf> though L<MooseX::SimpleConfig>.

=cut

=attr holder

Name of the license holder.

=cut

has holder => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=attr year

Year to be used in the copyright notice.

=cut

has year => (
    is       => 'ro',
    isa      => Maybe[Num],
    default  => undef,
);

=attr license

Name of the license to use. Must be the name of a module available under the
Software::License:: namespace. Defaults to Perl_5.

=cut

has license => (
    is      => 'ro',
    isa     => Str,
    default => 'Perl_5',
);

=attr type

The type of license notice you'd like to generate. Available values are:

B<* notice>

This method returns a snippet of text, usually a few lines, indicating the
copyright holder and year of copyright, as well as an indication of the license
under which the software is distributed.

B<* license>

This method returns the full text of the license.

B<* fulltext>

This method returns the complete text of the license, preceded by the copyright
notice.

B<* version>

This method returns the version of the license.  If the license is not
versioned, this returns nothing.

B<* meta_yml_name>

This method returns the string that should be used for this license in the CPAN
META.yml file, or nothing if there is no known string to use.

=cut

has type => (
    is      => 'ro',
    isa     => Str,
    default => 'notice',
);

has '+configfile' => (
    default => catfile(File::HomeDir->my_home, '.software_license.conf'),
);

has _software_license => (
    is      => 'ro',
    isa     => 'Software::License',
    lazy    => 1,
    builder => '_build__software_license',
    handles => {
        notice   => 'notice',
        text     => 'license',
        fulltext => 'fulltext',
        version  => 'version',
    },
);

sub _build__software_license {
    my ($self) = @_;
    my $class = "Software::License::${\$self->license}";
    Class::MOP::load_class($class);
    return $class->new({
        holder => $self->holder,
        year   => $self->year,
    });
}

override BUILDARGS => sub {
    my $args = super;
    $args->{license} = $args->{extra_argv}->[0]
        if @{ $args->{extra_argv} };
    return $args;
};

around get_config_from_file => sub {
    my $orig = shift;
    my $ret;
    eval { $ret = $orig->(@_); };
    return $ret;
};

sub run {
    my ($self) = @_;
    my $meth = $self->type;
    print $self->_software_license->$meth;
}

__PACKAGE__->meta->make_immutable;

1;
