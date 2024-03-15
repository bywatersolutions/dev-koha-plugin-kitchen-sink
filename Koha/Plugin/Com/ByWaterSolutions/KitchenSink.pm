package Koha::Plugin::Com::ByWaterSolutions::KitchenSink;

## It's good practice to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Auth;
use C4::Context;

use Koha::Account::Lines;
use Koha::Account;
use Koha::DateUtils qw( dt_from_string );
use Koha::Libraries;
use Koha::Patron::Categories;
use Koha::Patron;

use Cwd qw(abs_path);
use Data::Dumper;
use LWP::UserAgent;
use MARC::Record;
use Mojo::JSON qw(decode_json);;
use URI::Escape qw(uri_unescape);

use Koha::Plugin::Com::ByWaterSolutions::KitchenSink::Greeter;

## Here we set our plugin version
our $VERSION = "{VERSION}";
our $MINIMUM_VERSION = "{MINIMUM_VERSION}";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'Example Kitchen-Sink Plugin',
    author          => 'Kyle M Hall',
    date_authored   => '2009-01-27',
    date_updated    => "1900-01-01",
    minimum_version => $MINIMUM_VERSION,
    maximum_version => undef,
    version         => $VERSION,
    description     => 'This plugin implements every available feature '
      . 'of the plugin system and is meant '
      . 'to be documentation and a starting point for writing your own plugins!',
    namespace       => 'kitchensink',
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

## The existance of a 'report' subroutine means the plugin is capable
## of running a report. This example report can output a list of patrons
## either as HTML or as a CSV file. Technically, you could put all your code
## in the report method, but that would be a really poor way to write code
## for all but the simplest reports
sub report {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('output') ) {
        $self->report_step1();
    }
    else {
        $self->report_step2();
    }
}

## The existance of a 'tool' subroutine means the plugin is capable
## of running a tool. The difference between a tool and a report is
## primarily semantic, but in general any plugin that modifies the
## Koha database should be considered a tool
sub tool {
    my ( $self, $args ) = @_;

    my $cgi = $self->{'cgi'};

    if ( $cgi->param('submitted') ) {
        $self->tool_step2();
    }
    elsif ( $cgi->param('greet') ) {
        $self->schedule_greets();
    }
    else {
        $self->tool_step1();
    }
}

## The existance of an 'admin' subroutine means the plugin has some functionality that
## should only be available to Koha librarians with administrative privileges.
##
## Such plugins will be displayed in the admin page and work in a similar way to the 'tool'
## system above.
sub admin {
    my ( $self, $args ) = @_;

    my $cgi = $self->{'cgi'};

    my $template = $self->get_template( { file => 'admin_example.tt' } );

    $self->output_html( $template->output() );
    return;
}

## The existiance of a 'to_marc' subroutine means the plugin is capable
## of converting some type of file to MARC for use from the stage records
## for import tool
##
## This example takes a text file of the arbtrary format:
## First name:Middle initial:Last name:Year of birth:Title
## and converts each line to a very very basic MARC record
sub to_marc {
    my ( $self, $args ) = @_;

    my $data = $args->{data};

    my $batch = q{};

    foreach my $line ( split( /\n/, $data ) ) {
        my $record = MARC::Record->new();
        my ( $firstname, $initial, $lastname, $year, $title ) = split(/:/, $line );

        ## create an author field.
        my $author_field = MARC::Field->new(
            '100', 1, '',
            a => "$lastname, $firstname $initial.",
            d => "$year-"
        );

        ## create a title field.
        my $title_field = MARC::Field->new(
            '245', '1', '4',
            a => "$title",
            c => "$firstname $initial. $lastname",
        );

        $record->append_fields( $author_field, $title_field );

        $batch .= $record->as_usmarc() . "\x1D";
    }

    return $batch;
}

## If your plugin can process payments online,
## and that feature of the plugin is enabled,
## this method will return true
sub opac_online_payment {
    my ( $self, $args ) = @_;

    return $self->retrieve_data('enable_opac_payments') eq 'Yes';
}

## This method triggers the beginning of the payment process
## It could result in a form displayed to the patron the is submitted
## or go straight to a redirect to the payment service ala paypal
sub opac_online_payment_begin {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my ( $template, $borrowernumber ) = get_template_and_user(
        {   template_name   => abs_path( $self->mbf_path( 'opac_online_payment_begin.tt' ) ),
            query           => $cgi,
            type            => 'opac',
            authnotrequired => 0,
            is_plugin       => 1,
        }
    );

    my @accountline_ids = $cgi->multi_param('accountline');

    my $rs = Koha::Database->new()->schema()->resultset('Accountline');
    my @accountlines = map { $rs->find($_) } @accountline_ids;

    $template->param(
        borrower             => scalar Koha::Patrons->find($borrowernumber),
        payment_method       => scalar $cgi->param('payment_method'),
        enable_opac_payments => $self->retrieve_data('enable_opac_payments'),
        accountlines         => \@accountlines,
    );


    $self->output_html( $template->output() );
}

## This method triggers the end of the payment process
## Should should result in displaying a page indicating
## the success or failure of the payment.
sub opac_online_payment_end {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my ( $template, $borrowernumber ) = get_template_and_user(
        {
            template_name =>
              abs_path( $self->mbf_path('opac_online_payment_end.tt') ),
            query           => $cgi,
            type            => 'opac',
            authnotrequired => 0,
            is_plugin       => 1,
        }
    );

    my $m;
    my $v;

    my $amount          = $cgi->param('amount');
    my @accountline_ids = $cgi->multi_param('accountlines_id');

    $m = "no_amount"       unless $amount;
    $m = "no_accountlines" unless @accountline_ids;

    if ( $amount && @accountline_ids ) {
        my $account = Koha::Account->new( { patron_id => $borrowernumber } );
        my @accountlines = Koha::Account::Lines->search(
            {
                accountlines_id => { -in => \@accountline_ids }
            }
        )->as_list();
        foreach my $id (@accountline_ids) {
            $account->pay(
                {
                    amount => $amount,
                    lines  => \@accountlines,
                    note   => "Paid via KitchenSink ImaginaryPay",
                }
            );
        }

        $m = 'valid_payment';
        $v = $amount;
    }

    $template->param(
        borrower      => scalar Koha::Patrons->find($borrowernumber),
        message       => $m,
        message_value => $v,
    );

    $self->output_html( $template->output() );
}

## If your plugin needs to add some CSS to the OPAC, you'll want
## to return that CSS here. Don't forget to wrap your CSS in <style>
## tags. By not adding them automatically for you, you'll have a chance
## to include external CSS files as well!
sub opac_head {
    my ( $self ) = @_;

    return q|
        <style>
          body {
            background-color: orange;
          }
        </style>
    |;
}

## If your plugin needs to add some javascript in the OPAC, you'll want
## to return that javascript here. Don't forget to wrap your javascript in
## <script> tags. By not adding them automatically for you, you'll have a
## chance to include other javascript files if necessary.
sub opac_js {
    my ( $self ) = @_;

    return q|
        <script>console.log("Thanks for testing the kitchen sink plugin!");</script>
    |;
}


## If your plugin needs to add some CSS to the staff intranet, you'll want
## to return that CSS here. Don't forget to wrap your CSS in <style>
## tags. By not adding them automatically for you, you'll have a chance
## to include external CSS files as well!
sub intranet_head {
    my ( $self ) = @_;

    return q|
        <style>
          body {
            background-color: orange;
          }
        </style>
    |;
}

## If your plugin needs to add some javascript in the staff intranet, you'll want
## to return that javascript here. Don't forget to wrap your javascript in
## <script> tags. By not adding them automatically for you, you'll have a
## chance to include other javascript files if necessary.
sub intranet_js {
    my ( $self ) = @_;

    return q|
        <script>console.log("Thanks for testing the kitchen sink plugin!");</script>
    |;
}

## This method allows you to add new html elements to the catalogue toolbar.
## You'll want to return a string of raw html here, most likely a button or other
## toolbar element of some form. See bug 20968 for more details.
sub intranet_catalog_biblio_enhancements_toolbar_button {
    my ( $self ) = @_;

    return q|
        <a class="btn btn-default btn-sm" onclick="alert('Peace and long life');">
          <i class="fa fa-hand-spock-o" aria-hidden="true"></i>
          Live long and prosper
        </a>
    |;
}

## If your tool is complicated enough to needs it's own setting/configuration
## you will want to add a 'configure' method to your plugin like so.
## Here I am throwing all the logic into the 'configure' method, but it could
## be split up like the 'report' method is.
sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template({ file => 'configure.tt' });

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            enable_opac_payments => $self->retrieve_data('enable_opac_payments'),
            foo             => $self->retrieve_data('foo'),
            bar             => $self->retrieve_data('bar'),
            last_upgraded   => $self->retrieve_data('last_upgraded'),
        );

        $self->output_html( $template->output() );
    }
    else {
        $self->store_data(
            {
                enable_opac_payments => $cgi->param('enable_opac_payments'),
                foo                => $cgi->param('foo'),
                bar                => $cgi->param('bar'),
                last_configured_by => C4::Context->userenv->{'number'},
            }
        );
        $self->go_home();
    }
}

## This is the 'install' method. Any database tables or other setup that should
## be done when the plugin if first installed should be executed in this method.
## The installation method should always return true if the installation succeeded
## or false if it failed.
sub install() {
    my ( $self, $args ) = @_;

    my $table = $self->get_qualified_table_name('mytable');

    return C4::Context->dbh->do( "
        CREATE TABLE IF NOT EXISTS $table (
            `borrowernumber` INT( 11 ) NOT NULL
        ) ENGINE = INNODB;
    " );
}

## This is the 'upgrade' method. It will be triggered when a newer version of a
## plugin is installed over an existing older version of a plugin
sub upgrade {
    my ( $self, $args ) = @_;

    my $dt = dt_from_string();
    $self->store_data( { last_upgraded => $dt->ymd('-') . ' ' . $dt->hms(':') } );

    return 1;
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;

    my $table = $self->get_qualified_table_name('mytable');

    return C4::Context->dbh->do("DROP TABLE IF EXISTS $table");
}

## These are helper functions that are specific to this plugin
## You can manage the control flow of your plugin any
## way you wish, but I find this is a good approach
sub report_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'report-step1.tt' });

    my @libraries = Koha::Libraries->search;
    my @categories = Koha::Patron::Categories->search({}, {order_by => ['description']});
    $template->param(
        libraries => \@libraries,
        categories => \@categories,
    );

    $self->output_html( $template->output() );
}

sub report_step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $dbh = C4::Context->dbh;

    my $branch                = $cgi->param('branch');
    my $category_code         = $cgi->param('categorycode');
    my $borrower_municipality = $cgi->param('borrower_municipality');
    my $output                = $cgi->param('output');

    my $fromDay   = $cgi->param('fromDay');
    my $fromMonth = $cgi->param('fromMonth');
    my $fromYear  = $cgi->param('fromYear');

    my $toDay   = $cgi->param('toDay');
    my $toMonth = $cgi->param('toMonth');
    my $toYear  = $cgi->param('toYear');

    my ( $fromDate, $toDate );
    if ( $fromDay && $fromMonth && $fromYear && $toDay && $toMonth && $toYear )
    {
        $fromDate = "$fromYear-$fromMonth-$fromDay";
        $toDate   = "$toYear-$toMonth-$toDay";
    }

    my $query = "
        SELECT firstname, surname, address, city, zipcode, city, zipcode, dateexpiry FROM borrowers 
        WHERE branchcode LIKE '$branch'
        AND categorycode LIKE '$category_code'
    ";

    if ( $fromDate && $toDate ) {
        $query .= "
            AND DATE( dateexpiry ) >= DATE( '$fromDate' )
            AND DATE( dateexpiry ) <= DATE( '$toDate' )  
        ";
    }

    my $sth = $dbh->prepare($query);
    $sth->execute();

    my @results;
    while ( my $row = $sth->fetchrow_hashref() ) {
        push( @results, $row );
    }

    my $filename;
    if ( $output eq "csv" ) {
        print $cgi->header( -attachment => 'borrowers.csv' );
        $filename = 'report-step2-csv.tt';
    }
    else {
        print $cgi->header();
        $filename = 'report-step2-html.tt';
    }

    my $template = $self->get_template({ file => $filename });

    $template->param(
        date_ran     => dt_from_string(),
        results_loop => \@results,
        branch       => GetBranchName($branch),
    );

    unless ( $category_code eq '%' ) {
        $template->param( category_code => $category_code );
    }

    print $template->output();
}

sub tool_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'tool-step1.tt' });

    $self->output_html( $template->output() );
}

sub tool_step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'tool-step2.tt' });

    my $borrowernumber = C4::Context->userenv->{'number'};
    my $borrower = Koha::Patrons->find( $borrowernumber );
    $template->param( 'victim' => $borrower->unblessed() );
    $template->param( 'victim' => $borrower );

    $borrower->firstname('Bob')->store;

    my $dbh = C4::Context->dbh;

    my $table = $self->get_qualified_table_name('mytable');

    my $sth   = $dbh->prepare("SELECT DISTINCT(borrowernumber) FROM $table");
    $sth->execute();
    my @victims;
    while ( my $r = $sth->fetchrow_hashref() ) {
        my $brw = Koha::Patrons->find( $r->{'borrowernumber'} )->unblessed();
        push( @victims, ( $brw ) );
    }
    $template->param( 'victims' => \@victims );

    $dbh->do( "INSERT INTO $table ( borrowernumber ) VALUES ( ? )",
        undef, ($borrowernumber) );

    $self->output_html( $template->output() );
}

sub schedule_greets {
    my ($self) = @_;

    my $cgi   = $self->{cgi};
    my $count = $cgi->param('count');

    Koha::Plugin::Com::ByWaterSolutions::KitchenSink::Greeter->new->enqueue( { size => $count } );

    my $template = $self->get_template( { file => 'greets_scheduled.tt' } );
    $template->param( count => $count );

    $self->output_html( $template->output() );
}

## API methods
# If your plugin implements API routes, then the 'api_routes' method needs
# to be implemented, returning valid OpenAPI 2.0 paths serialized as a hashref.
# It is a good practice to actually write OpenAPI 2.0 path specs in JSON on the
# plugin and read it here. This allows to use the spec for mainline Koha later,
# thus making this a good prototyping tool.

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ( $self ) = @_;
    
    return 'kitchensink';
}

sub static_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('staticapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

=head3 opac_detail_xslt_variables

Plugin hook injecting variables to the OPAC detail XSLT

=cut

sub opac_detail_xslt_variables {
    my ( $self, $params ) = @_;

    return { nice_message => 'We love Koha /' };
}

=head3 opac_results_xslt_variables

Plugin hook injecting variables to the OPAC results XSLT

=cut

sub opac_results_xslt_variables {
    my ( $self, $params ) = @_;

    return { nice_message => 'We love Koha /' };
}

=head3 cronjob_nightly

Plugin hook running code from a cron job

=cut

sub cronjob_nightly {
    my ( $self ) = @_;

    print "Remember to clean the kitchen\n";
}

=head3 before_send_messages

Plugin hook that runs right before the message queue is processed
in process_message_queue.pl

=cut

sub before_send_messages {
    my ( $self, $params ) = @_;

    print "Plugin hook before_send_message called with the params: " . Data::Dumper::Dumper( $params );
}

=head3 item_barcode_transform

Plugin hook that transforms input string anywhere that item barcodes are scanned in

=cut

sub item_barcode_transform {
    my ( $self, $barcode_ref ) = @_;

    # Second arg is a ref to barcode value, for recursive call
    # this ref needs to be altered, no need to return new value
    $$barcode_ref = "I".$$barcode_ref;
}

=head3 patron_barcode_transform

Plugin hook that transforms input string anywhere that patron barcodes are scanned in

=cut

sub patron_barcode_transform {
    my ( $self, $barcode_ref ) = @_;

    # Second arg is a ref to barcode value, for recursive call
    # this ref needs to be altered, no need to return new value
    $$barcode_ref = "P".$$barcode_ref;
}

=head3 intranet_catalog_biblio_tab

Plugin hook that adds new tabs to the staff record details page
with whatever content you create.

https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=23050

=cut

sub intranet_catalog_biblio_tab {
    my @tabs;
    push @tabs,
      Koha::Plugins::Tab->new(
        {
            title   => 'Tab 1',
            content => 'This is content for tab 1'
        }
      );

    push @tabs,
      Koha::Plugins::Tab->new(
        {
            title   => 'Tab 2',
            content => 'This is content for tab 2'
        }
      );

    return @tabs;
}

=head3 background_tasks

Plugin hook used to register new background_job types

=cut

sub background_tasks {
    return {
        greeter => 'Koha::Plugin::Com::ByWaterSolutions::KitchenSink::Greeter'
    };
}

=head3 transform_prepared_letter

Plugin hook used to modify prepared slips and notices

=cut

sub transform_prepared_letter {
    my ( $self, $params ) = @_;
    my $linebreak = $params->{letter}->{is_html} ? '<p>' : "\n";
    $params->{letter}->{content} .= $linebreak . "Thanks for using your local library!";
}

1;
