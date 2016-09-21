=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::ViewConfig::Gene::Compara_Alignments;

use strict;
use previous qw(init_cacheable);

## EG - reduce flanking from 600 to 60
sub init_cacheable {
  my $self = shift;
  $self->PREV::init_cacheable(@_);

  $self->set_defaults({
    flank5_display => 60,
    flank3_display => 60,
  });
}

1;
