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

=head2 get_pending_job

Print server API to send print jobs to the Print Manager.

When hit, this API will send the next queued print job to the Print Manager
and mark it as Pending in the queue, with the time it was set to Pending.

If the Pending job is not confirmed within 1 minute, libki_cron.pl will
reset the status so another Print Manager can try again.

=cut

sub get_pending_job : Path('get_pending_job') : Args(0) {
    my ( $self, $c ) = @_;

    delete $c->stash->{Settings};

    my $queued_to = $c->request->params->{name} || $c->request->address;

    my $instance = $c->instance;
    my $config   = $c->config->{instances}->{$instance} || $c->config;
    my $log      = $c->log();

    my $now = $c->now();

    my $job = $c->model('DB::PrintJob')->search(
        {
            instance  => $instance,
            status    => 'Pending',
            type      => 'PrintManager',
        },
        {
            order_by => { -asc => 'released_on' }
        }
    )->next();

    my $data;
    if ($job) {
        if ( $job->update( { status => 'Queued', queued_on => $now, queued_to => $queued_to } ) ) {
            $data = {
                job_id        => $job->id,
                copies        => $job->copies,
                printer       => $job->printer,
                user_id       => $job->user_id,
                print_file_id => $job->print_file_id,
            };

            $c->stash( { job => $data } );
        }
    }

    $c->forward( $c->view('JSON') );
}

=head2 get_file

Returns the PDF of a given print file id

=cut

sub get_file : Local : Args(1) {
    my ( $self, $c, $id ) = @_;
    my $instance = $c->instance;

    warn "ID: '$id'";
    warn "INSTANCE: '$instance'";
    my $print_file = $c->model('DB::PrintFile')->find({ id => $id, instance => $instance });

    if ( $print_file ) {
        my $filename = $print_file->filename;

        $c->response->content_type('application/octet-stream');
        $c->response->header( 'attachment', "$id.pdf" );
        $c->response->body( $print_file->data );
    } else {
        $c->response->body( 'Page not found' );
        $c->response->status(404);
    }
}

=head2 job

Print server API to update the status of a job,
including setting a job to:
    QUEUED: Job just added and has not yet been downloaded ( this is the status set by get_pending_job );
    IN_PROGRESS: Job downloaded and has been added to the client-side native printer queue
    DONE: Job printed successfully
    ERROR: Job cannot be printed due to an error
    SUBMITTED: Job submitted to third-party service ( meaning we may not get any feedback on success )
    HELD: Job was successfully submitted but is pending some user action before being QUEUED

=cut

sub job : Path('job') : Args(0) {
    #TODO
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
