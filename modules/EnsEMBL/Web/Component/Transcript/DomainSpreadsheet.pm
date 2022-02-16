=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Transcript::DomainSpreadsheet;

use strict;

# replaced domain->analysis->db with domain->analysis->display_label
# added separate table for MS peptides

sub content {
  my $self        = shift;
  my $object      = $self->object;
  my $translation = $object->translation_object;
  
  return $self->non_coding_error unless $translation;
  
  my $hub      = $self->hub;
  my $analyses = $object->table_info($object->get_db, 'protein_feature')->{'analyses'} || {};
## EG  
  my (@domains, @ms_domains, @others);
##

  foreach (keys %$analyses) {
    if ($analyses->{$_}{'web'}{'type'} eq 'domain') {
      push @domains, @{$translation->get_all_ProteinFeatures($_)};
## EG
    } elsif ($analyses->{$_}{'web'}{'type'} eq 'ms_domain') {
      push @ms_domains, @{$translation->get_all_ProteinFeatures($_)};
##
    } else {
      push @others,  @{$translation->get_all_ProteinFeatures($_)};
    }
  }
  
  my @domain_keys = grep { $analyses->{$_}{'web'}{'type'} eq 'domain' } keys %$analyses;
  my @ms_domain_keys = grep { $analyses->{$_}{'web'}{'type'} eq 'ms_domain' } keys %$analyses;
  my @other_keys     = grep { $analyses->{$_}{'web'}{'type'} ne 'domain' } keys %$analyses;
  my @domains     = map  { @{$translation->get_all_ProteinFeatures($_)} } @domain_keys;
  my @ms_domains     = map  { @{$translation->get_all_ProteinFeatures($_)} } @ms_domain_keys;
  my @others      = map  { @{$translation->get_all_ProteinFeatures($_)} } @other_keys;

  return unless @domains || @ms_domains || @others;

  my $html = '';
  
  if (@domains) {
    my $table = $self->new_table([], [], { data_table => 1 });
    
    $table->add_columns(
      { key => 'type',     title => 'Domain source', width => '15%', sort => 'string', help => 'Original project that identified the domain' },
      { key => 'start',    title => 'Start',       width => '10%',   sort => 'numeric', hidden_key => '_loc' },
      { key => 'end',      title => 'End',         width => '10%',   sort => 'numeric'                       },
      { key => 'desc',     title => 'Description', width => '15%',   sort => 'string'                        },
      { key => 'acc',      title => 'Accession',   width => '10%',   sort => 'html'                          },
      { key => 'interpro', title => 'InterPro',    width => '40%',   sort => 'html'                          }
    );
    
    foreach my $domain (
      sort {
        $a->idesc cmp $b->idesc || 
        $a->start <=> $b->start || 
        $a->end   <=> $b->end   || 
        $a->analysis->db cmp $b->analysis->db 
      } @domains
    ) {
      my $db            = $domain->analysis->db;
      my $display_label            = $domain->analysis->display_label;
      my $id            = $domain->hseqname;
      my $interpro_acc  = $domain->interpro_ac;
      my $interpro_link = $hub->get_ExtURL_link($interpro_acc,'INTERPRO',$interpro_acc);
      my $other_urls;
      
      if ($interpro_acc) {
        my $url     = $hub->url({ action => 'Domains/Genes', domain => $interpro_acc });
        $other_urls = qq{ [<a href="$url">Display all genes with this domain</a>]};
      } else {
        $interpro_link = '-';
        $other_urls = '';
      }

      my $acc = $hub->get_ExtURL_link($id, uc $db, $id);
      if ($db eq 'Gene3D' && $id=~/:/){
        my ($prefix, $ext_id) = split(/:/, $id);
        $acc = $hub->get_ExtURL_link($id, uc $db, $ext_id) if $ext_id;
      }
      
      $table->add_row({
        type     => $display_label,
        desc     => $domain->idesc || '-',
        acc      => $acc,
        start    => $domain->start,
        end      => $domain->end,
        interpro => $interpro_link.$other_urls,
        _loc     => join('::', $domain->start, $domain->end),
      });
    }
    
    $html .= '<h2>Domains</h2>' . $table->render;
  }

## EG  
  if (@ms_domains) {
    my $table = $self->new_table([], [], { data_table => 1 });
    
    $table->add_columns(
      { key => 'source', title => 'Peptide source', width => '15%', sort => 'string'                        },
      { key => 'start',  title => 'Start',          width => '10%', sort => 'numeric', hidden_key => '_loc' },
      { key => 'end',    title => 'End',            width => '10%', sort => 'numeric'                       },
      { key => 'desc',   title => 'Description',    width => '45%', sort => 'string'                        },
      { key => 'acc',    title => 'Accession',      width => '20%', sort => 'string'                        },
    );
    
    foreach my $ms_domain (
      sort {
        $a->idesc cmp $b->idesc || 
        $a->start <=> $b->start || 
        $a->end   <=> $b->end   || 
        $a->analysis->display_label cmp $b->analysis->display_label 
      } @ms_domains
    ) {
      
      $table->add_row({
        source => $ms_domain->analysis->display_label,
        desc   => $ms_domain->analysis->description,
        acc    => $ms_domain->hseqname,
        start  => $ms_domain->start,
        end    => $ms_domain->end,
        _loc   => join('::', $ms_domain->start, $ms_domain->end),
      });
    }
    
    $html .= '<h2>Mass spectrometry peptides</h2>' . $table->render;
  }
##
  
  if (@others) {
    my $table = $self->new_table([], [], { data_table => 1 });
    
    $table->add_columns(
      { key => 'type',  title => 'Feature type', width => '40%', sort => 'string'                        },
      { key => 'start', title => 'Start',        width => '30%', sort => 'numeric', hidden_key => '_loc' },
      { key => 'end',   title => 'End',          width => '30%', sort => 'numeric'                       }
    );
    
    foreach my $domain (
      sort { $a->[0] cmp $b->[0] || $a->[1]->start <=> $b->[1]->start || $a->[1]->end <=> $b->[1]->end }
      map {[ $_->analysis->db || $_->analysis->logic_name || 'unknown', $_ ]}
      @others
    ) {
      (my $domain_type = $domain->[0]) =~ s/_/ /g;
      
      $table->add_row({
        type  => ucfirst $domain_type,
        start => $domain->[1]->start,
        end   => $domain->[1]->end,
        _loc  => join('::', $domain->[1]->start, $domain->[1]->end),
      });
    }
    
    $html .= '<h2>Other features</h2>' . $table->render;
  }
  
  return $html;
}

1;

