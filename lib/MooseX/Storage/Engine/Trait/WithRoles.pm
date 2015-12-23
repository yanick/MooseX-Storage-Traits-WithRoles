package MooseX::Storage::Engine::Trait::WithRoles;
# ABSTRACT: An engine trait to include roles in serialization

use Moose::Util qw/ with_traits /;

use List::Util qw/ pairgrep /;

use Moose::Role;
use namespace::autoclean;

around collapse_object => sub {
    my( $orig, $self, @args ) = @_;

    my $packed = $orig->( $self, @args );

    if( my @roles = map { $_->name } @{ $self->object->meta->roles } ) {

        $_ = { $_->meta->genitor->name => { pairgrep { $a ne '<<MOP>>' }  %{ $_->meta->parameters } } }
              for grep { $_->meta->is_anon_role and $_->meta->isa('MooseX::Role::Parameterized::Meta::Role::Parameterized') } @roles;

        $packed->{'__ROLES__'} = \@roles;
    }

    if ( $self->object->meta->is_anon_class ) {
        $packed->{'__CLASS__'} = ( $self->object->meta->superclasses )[0];
    }

    $packed;

};

around expand_object => sub {
    my( $orig, $self, $data, @args ) = @_;

    my $class_with_roles = $data->{'__CLASS__'};

    if( my $roles = delete $data->{'__ROLES__'} ) {
        for my $role( @$roles ) {
            if ( ref $role ) {
                my( $c, $params ) = %$role;
                $class_with_roles = with_traits( $class_with_roles, $c->meta->generate_role( parameters => $params ) );
            }
            else {
                $class_with_roles = with_traits( $class_with_roles, $role,);
            }
        }
    }

    $data->{'__CLASS__'} = $class_with_roles;
    $self->class($class_with_roles);

    $orig->($self,$data,@args);
};

1;

__END__

