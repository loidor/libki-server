package Libki::Controller::API::PrintManager::v1_0;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Libki::Controller::API::Client::v1_0 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 jobs

Print server API to send print jobs to the Print Manager.

When hit, this API will send the next queued print job to the Print Manager
and mark it as Pending in the queue, with the time it was set to Pending.

If the Pending job is not confirmed within 1 minute, libki_cron.pl will
reset the status so another Print Manager can try again.

=cut

sub jobs : Path('print') : Args(0) {
    my ( $self, $c ) = @_;

    delete $c->stash->{Settings};

    my $instance = $c->instance;
    my $config   = $c->config->{instances}->{$instance} || $c->config;
    my $log      = $c->log();

    my $now = $c->now();

    my $print_jobs = $c->model('DB::PrintJob')->search( { status => "Queued" }, { order_by => { -asc => 'released_on' } } );

    $c->forward( $c->view('JSON') );
}

=head1 AUTHOR

Kyle M Hall <kyle@kylehall.info>

=cut

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;

1;
