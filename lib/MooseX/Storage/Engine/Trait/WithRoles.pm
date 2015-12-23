package MooseX::Storage::Engine::Trait::WithRoles;
# ABSTRACT: An engine trait to include roles in serialization

use Moose::Util qw/ with_traits /;

use List::Util qw/ pairgrep /;

use Moose::Role;
use MooseX::Storage::Base::SerializedClass;
use List::MoreUtils qw/ apply /;

use namespace::autoclean;

around collapse_object => sub {
    my( $orig, $self, @args ) = @_;

    my $packed = $orig->( $self, @args );

    if( my @roles = map { $_->name } @{ $self->object->meta->roles } ) {
        $packed->{'__ROLES__'} = [
            apply { 
                $_ = { $_->meta->genitor->name => { pairgrep { $a ne '<<MOP>>' }  %{ $_->meta->parameters } } }
                    if $_->meta->isa('MooseX::Role::Parameterized::Meta::Role::Parameterized') 
            } @roles
        ];
    }

    ( $packed->{'__CLASS__'} ) = $self->object->meta->superclasses
        if $self->object->meta->is_anon_class;

    return $packed;
};

around expand_object => sub {
    my( $orig, $self, $data, @args ) = @_;

    $self->class(
        MooseX::Storage::Base::SerializedClass::_unpack_class($data)
    );

    $orig->($self,$data,@args);
};

1;

__END__

