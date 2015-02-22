
package MyWeb::Model::DB;
use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config( schema_class => 'MyWeb::Schema', );

