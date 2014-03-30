use Test::More;
use Test::Mojo;

use FindBin;
require "$FindBin::Bin/../mojo.pl";


my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200);
$t->get_ok('/hello')->status_is(200)->content_like(qr/Hello World!/);
$t->get_ok('/hello/smonff')->status_is(200)->content_like(qr/smonff/);
$t->get_ok('/agent')->status_is(200);
$t->get_ok('/stash')->status_is(200)->content_like(qr/23\sand\s24/);;
$t->get_ok('/time')->status_is(200);
# Check a route that doesn't exists is 404
$t->get_ok('/404')->status_is(404);
$t->get_ok('/with_layout')->status_is(200);
$t->get_ok('/with_block')->status_is(200);
$t->get_ok('/secret')->status_is(200);

done_testing();













