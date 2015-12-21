package MooseX::Storage::Engine::Trait::WithRoles;
# ABSTRACT: An engine trait to include roles in serialization

our $VERSION = '0.51';

use Moose::Util qw/ with_traits /;

use Moose::Role;
use namespace::autoclean;

around collapse_object => sub {
    my( $orig, $self, @args ) = @_;

    my $packed = $orig->( $self, @args );

    if( my @roles = map { $_->name } @{ $self->object->meta->roles } ) {
        $packed->{'__ROLES__'} = \@roles;
    }

    if ( $self->object->meta->is_anon_class ) {
        $packed->{'__CLASS__'} = ( $self->object->meta->superclasses )[0];
    }

    $packed;

};

around expand_object => sub {
    my( $orig, $self, $data, @args ) = @_;

    if( my $roles = delete $data->{'__ROLES__'} ) {
        my $class_with_roles = with_traits(
            $data->{'__CLASS__'},
            @$roles,
        );
        $data->{'__CLASS__'} = $class_with_roles;
        warn $class_with_roles;
        $self->class($class_with_roles);
    }

    $orig->($self,$data,@args);
};

1;

__END__

