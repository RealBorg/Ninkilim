use utf8;
package Ninkilim::Schema::Result::Media;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ninkilim::Schema::Result::Media

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

=head1 TABLE: C<medias>

=cut

__PACKAGE__->table("medias");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'medias_id_seq'

=head2 posting

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 filename

  data_type: 'text'
  is_nullable: 0

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "medias_id_seq",
  },
  "posting",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "filename",
  { data_type => "text", is_nullable => 0 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 posting

Type: belongs_to

Related object: L<Ninkilim::Schema::Result::Posting>

=cut

__PACKAGE__->belongs_to(
  "posting",
  "Ninkilim::Schema::Result::Posting",
  { id => "posting" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-11-24 05:37:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:58boQsfIkfGOmH6G/hqMFQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
