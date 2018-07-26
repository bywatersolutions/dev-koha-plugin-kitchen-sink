package Koha::Plugin::Com::ByWaterSolutions::KitchenSink::BotherPatronController;

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';

=head1 API

=head2 Class Methods

=head3 Method that bothers the patron, with no side effects

=cut

sub bother {
    my $c = shift->openapi->valid_input or return;

    my $patron_id = $c->validation->param('patron_id');
    my $patron    = Koha::Patrons->find($patron_id);

    unless ($patron) {
        return $c->render( status => 404, openapi => { error => "Patron not found." } );
    }

    return $c->render( status => 200, openapi => { bothered => Mojo::JSON->true } );
}

1;
