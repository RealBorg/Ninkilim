use utf8;
package Ninkilim::Schema::Result::LoginToken;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ninkilim::Schema::Result::LoginToken

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

=head1 TABLE: C<login_tokens>

=cut

__PACKAGE__->table("login_tokens");

=head1 ACCESSORS

=head2 user_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 token

  data_type: 'text'
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "token",
  { data_type => "text", is_nullable => 0 },
  "created",
  { data_type => "timestamp", is_nullable => 0 },
);

=head1 RELATIONS

=head2 user

Type: belongs_to

Related object: L<Ninkilim::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Ninkilim::Schema::Result::User",
  { id => "user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-12-12 12:53:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kUXHYqWz5jNCHneKsB2N6Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
