package MooseX::Storage::Engine::Trait::WithRoles;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: An engine trait to include roles in serialization
$MooseX::Storage::Engine::Trait::WithRoles::VERSION = '0.1.0';
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

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Engine::Trait::WithRoles - An engine trait to include roles in serialization

=head1 VERSION

version 0.1.0

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
