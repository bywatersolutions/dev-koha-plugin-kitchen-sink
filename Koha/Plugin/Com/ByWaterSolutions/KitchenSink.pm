package Koha::Plugin::Com::ByWaterSolutions::KitchenSink;

## It's good practive to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use C4::Branch;
use C4::Members;
use C4::Auth;
use MARC::Record;

## Here we set our plugin version
our $VERSION = 2.00;

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Example Kitchen-Sink Plugin',
    author => 'Kyle M Hall',
    description =>
'This plugin implements every available feature of the plugin system and is mean to be documentation and a starting point for writing your own plugins!',
    date_authored   => '2009-01-27',
    date_updated    => '2009-01-27',
    minimum_version => '3.0100107',
    maximum_version => undef,
    version         => $VERSION,
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

    unless ( $cgi->param('submitted') ) {
        $self->tool_step1();
    }
    else {
        $self->tool_step2();
    }

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
            foo => $self->retrieve_data('foo'),
            bar => $self->retrieve_data('bar'),
        );

        print $cgi->header();
        print $template->output();
    }
    else {
        $self->store_data(
            {
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
        CREATE TABLE  $table (
            `borrowernumber` INT( 11 ) NOT NULL
        ) ENGINE = INNODB;
    " );
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;

    my $table = $self->get_qualified_table_name('mytable');

    return C4::Context->dbh->do("DROP TABLE $table");
}

## These are helper functions that are specific to this plugin
## You can manage the control flow of your plugin any
## way you wish, but I find this is a good approach
sub report_step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'report-step1.tt' });

    $template->param(
        branches_loop   => GetBranchesLoop(),
        categories_loop => GetBorrowercategoryList(),
    );

    print $cgi->header();
    print $template->output();
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
        $row->{'dateexpiry'} =
          C4::Dates->new( $row->{'dateexpiry'}, 'iso' )->output();
        push( @results, $row );
    }

    my $date = C4::Dates->new();

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
        date_ran     => C4::Dates->new()->output(),
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

    print $cgi->header();
    print $template->output();
}

sub tool_step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'tool-step2.tt' });

    my $borrowernumber = C4::Context->userenv->{'number'};
    my $borrower = GetMember( borrowernumber => $borrowernumber );
    $template->param( 'victim' => $borrower );

    ModMember( borrowernumber => $borrowernumber, firstname => 'Bob' );

    my $dbh = C4::Context->dbh;

    my $table = $self->get_qualified_table_name('mytable');

    my $sth   = $dbh->prepare("SELECT DISTINCT(borrowernumber) FROM $table");
    $sth->execute();
    my @victims;
    while ( my $r = $sth->fetchrow_hashref() ) {
        push( @victims, GetMember( borrowernumber => $r->{'borrowernumber'} ) );
    }
    $template->param( 'victims' => \@victims );
    
    $dbh->do( "INSERT INTO $table ( borrowernumber ) VALUES ( ? )",
        undef, ($borrowernumber) );

    print $cgi->header();
    print $template->output();
}

1;
