use utf8;
package Ninkilim::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ninkilim::Schema::Result::User

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

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_nullable: 0

=head2 email

  data_type: 'text'
  is_nullable: 0

=head2 username

  data_type: 'text'
  is_nullable: 0

=head2 displayname

  data_type: 'text'
  is_nullable: 0

=head2 bio

  data_type: 'text'
  is_nullable: 0

=head2 website

  data_type: 'text'
  is_nullable: 0

=head2 location

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "bigint", is_nullable => 0 },
  "email",
  { data_type => "text", is_nullable => 0 },
  "username",
  { data_type => "text", is_nullable => 0 },
  "displayname",
  { data_type => "text", is_nullable => 0 },
  "bio",
  { data_type => "text", is_nullable => 0 },
  "website",
  { data_type => "text", is_nullable => 0 },
  "location",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 login_tokens

Type: has_many

Related object: L<Ninkilim::Schema::Result::LoginToken>

=cut

__PACKAGE__->has_many(
  "login_tokens",
  "Ninkilim::Schema::Result::LoginToken",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 postings

Type: has_many

Related object: L<Ninkilim::Schema::Result::Posting>

=cut

__PACKAGE__->has_many(
  "postings",
  "Ninkilim::Schema::Result::Posting",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-12-12 12:59:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uRpkHvH1jKYHM7WrTBYt1Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
