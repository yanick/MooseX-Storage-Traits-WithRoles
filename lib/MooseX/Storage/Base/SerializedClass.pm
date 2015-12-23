package MooseX::Storage::Base::SerializedClass;
# ABSTRACT: Deserialize according to the serialized __CLASS__

=head1 SYNOPSIS

  package ThirdDimension;
  use Moose::Role;

  has 'z' => (is => 'rw', isa => 'Int');

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage( base => 'SerializedClass', traits => [ 'WithRoles' ] );

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  1;

  use Moose::Util qw/ with_traits /;

  my $p = with_traits( 'Point', 'ThirdDimension' )->new(x => 10, y => 10, z => 10);

  my $packed = $p->pack(); 
  # { __CLASS__ => 'Point', '__ROLES__' => [ 'ThirdDimension' ], x => 10, y => 10, z => 10 }

  # unpack the hash into a class
  my $p2 = Point->unpack($packed);

  print $p2->z;

=head1 DESCRIPTION

Behaves like L<MooseX::Storage::Basic>, with the exception that 
the unpacking will reinflate the object into the class and roles
as provided in the serialized data. It is means to be used in
conjuncture with L<MooseX::Storage::Traits::WithRoles>.

=head1 EXPORTED FUNCTIONS

The function C<moosex_unpack> can be exported. The function unpacks
a serialized object based on its C<__CLASS__> and C<__ROLES__> attributes.

    use MooseX::Storage::Base::SerializedClass qw/ moosex_unpack /;

    my $object = moosex_unpack( $struct );

=cut

use parent 'Exporter';

use Moose::Role;

with 'MooseX::Storage::Basic';

use Moose::Util qw/ with_traits /;
use Class::Load 'load_class';

our @EXPORT_OK = qw/ moosex_unpack /;

use namespace::autoclean;

around unpack => sub {
    my( $orig, $class, $data, %args ) = @_;
    $class = Class::Load::load_class( $data->{'__CLASS__'} );

    if( my $roles = delete $data->{'__ROLES__'} ) {
        for my $role( @$roles ) {
            if ( ref $role ) {
                my( $c, $params ) = %$role;
                $class = with_traits( $class, $c->meta->generate_role( parameters => $params ) );
            }
            else {
                $class = with_traits( $class, $role,);
            }
        }
    }

    $data->{'__CLASS__'} = $class;

    $orig->($class,$data,%args);
};

sub moosex_unpack {
    MooseX::Storage::Base::SerializedClass::Dummy->unpack(shift);
}


{
    package 
        MooseX::Storage::Base::SerializedClass::Dummy;

    use Moose;
    use MooseX::Storage;

    with Storage( base => 'SerializedClass', traits => [ 'WithRoles' ] );

    __PACKAGE__->meta->make_immutable;

}

1;




