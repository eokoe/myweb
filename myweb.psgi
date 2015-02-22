use strict;
use warnings;

use lib 'lib';
use MyWeb;


my $app = MyWeb->apply_default_middlewares(MyWeb->psgi_app);
$app;

