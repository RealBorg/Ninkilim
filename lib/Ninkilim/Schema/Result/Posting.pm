use utf8;
package Ninkilim::Schema::Result::Posting;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ninkilim::Schema::Result::Posting

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

=head1 TABLE: C<postings>

=cut

__PACKAGE__->table("postings");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 full_text

  data_type: 'text'
  is_nullable: 0

=head2 lang

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 3

=head2 reposted

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 in_reply_to

  data_type: 'bigint'
  is_nullable: 1

=head2 highlight

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 source

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "full_text",
  { data_type => "text", is_nullable => 0 },
  "lang",
  { data_type => "char", default_value => "", is_nullable => 0, size => 3 },
  "reposted",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "in_reply_to",
  { data_type => "bigint", is_nullable => 1 },
  "highlight",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "source",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 medias

Type: has_many

Related object: L<Ninkilim::Schema::Result::Media>

=cut

__PACKAGE__->has_many(
  "medias",
  "Ninkilim::Schema::Result::Media",
  { "foreign.posting_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 source

Type: belongs_to

Related object: L<Ninkilim::Schema::Result::Source>

=cut

__PACKAGE__->belongs_to(
  "source",
  "Ninkilim::Schema::Result::Source",
  { id => "source" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-11-18 15:17:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BvYbHsKU+ft2ZrsgcZv2zw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;