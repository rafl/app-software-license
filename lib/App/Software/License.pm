package App::Software::License;

use Moose;
use MooseX::Types::Moose qw/Str Num Maybe/;
use File::HomeDir;
use File::Spec::Functions qw/catfile/;

use namespace::clean -except => 'meta';

with qw/MooseX::Getopt MooseX::SimpleConfig/;

has holder => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has year => (
    is       => 'ro',
    isa      => Maybe[Num],
    default  => undef,
);

has license => (
    is      => 'ro',
    isa     => Str,
    default => 'Perl_5',
);

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
    $args->{type} = $args->{extra_argv}->[0]
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
