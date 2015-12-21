package MooseX::Storage::Engine::Trait::WithRoles;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: An engine trait to include roles in serialization
$MooseX::Storage::Engine::Trait::WithRoles::VERSION = '0.0.1';
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

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Engine::Trait::WithRoles - An engine trait to include roles in serialization

=head1 VERSION

version 0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
