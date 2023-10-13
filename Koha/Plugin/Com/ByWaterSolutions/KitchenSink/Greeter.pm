package Koha::Plugin::Com::ByWaterSolutions::KitchenSink::Greeter;

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use base 'Koha::BackgroundJob';

=head1 NAME

KitchenSink::Greeter - Background task for greeting in the logs

This is a subclass of Koha::BackgroundJob.

=head1 API

=head2 Class methods

=head3 job_type

Define the job type of this job: greeter

=cut

sub job_type {
    return 'plugin_kitchensink_greeter';
}

=head3 process

Process the modification.

=cut

sub process {
    my ( $self, $args ) = @_;

    $self->start;

    my @messages;
    my $report = {
        total_greets  => $self->size,
        total_success => 0,
    };

    foreach my $step ( 1 .. $self->size ) {

        warn "Greeting: Hola! ($step)";

        push @messages,
            {
            type => 'success',
            code => 'greeted',
            };

        $report->{total_success}++;

        $self->step;
    }

    my $data = $self->decoded_data;
    $data->{messages} = \@messages;
    $data->{report}   = $report;

    $self->finish($data);
}

=head3 enqueue

Enqueue the new job

=cut

sub enqueue {
    my ( $self, $args ) = @_;

    $self->SUPER::enqueue(
        {
            job_size => $args->{size} // 5,
            job_args => {},
        }
    );
}

1;
