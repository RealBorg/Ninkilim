use utf8;
package Ninkilim::Schema::Result::Peer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ninkilim::Schema::Result::Peer

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<peers>

=cut

__PACKAGE__->table("peers");

=head1 ACCESSORS

=head2 url

  data_type: 'text'
  is_nullable: 0

=head2 owner

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 last_id

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "url",
  { data_type => "text", is_nullable => 0 },
  "owner",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "last_id",
  { data_type => "bigint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</url>

=back

=cut

__PACKAGE__->set_primary_key("url");

=head1 RELATIONS

=head2 owner

Type: belongs_to

Related object: L<Ninkilim::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "owner",
  "Ninkilim::Schema::Result::User",
  { id => "owner" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-12-20 07:54:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IVJw7lEfUHDc0SuTe1VCVw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
