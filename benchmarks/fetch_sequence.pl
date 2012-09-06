use strict;
use warnings;
use feature 'say';
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Registry;

use strict;
use warnings;
use Cwd;
my $file = $ARGV[0];
my $iterations = $ARGV[1];

my @ids;
open my $fh, '<', $file or die "Cannot open $file: $!";
while(my $line = <$fh>) {
  chomp $line;
  my ($id) = $line =~ /^http:\/\/beta.rest.ensembl.org\/sequence\/id\/(.+)\?/;
  my ($type) = $line =~ /type=([a-z]+)$/;
  push(@ids, [$id, $type]);
}
close $fh;

$iterations ||= 10;

Bio::EnsEMBL::Registry->no_version_check(1);
Bio::EnsEMBL::Registry->no_cache_warnings(1);
Bio::EnsEMBL::Registry->load_registry_from_db(
  -HOST => 'useastdb.ensembl.org', -PORT => 5306, -USER => 'anonymous',
  -NO_CACHE => 1,
);

foreach my $iter (1..$iterations) {
  my $array = $ids[rand($#ids)];
  my ($stable_id, $type) = @{$array};
  my ( $species, $object_type, $db_type ) = Bio::EnsEMBL::Registry->get_species_and_object_type($stable_id);
  my $adaptor = Bio::EnsEMBL::Registry->get_adaptor($species, $db_type, $object_type);
  my $object = $adaptor->fetch_by_stable_id($stable_id);
  my $ref = ref($object);
  if($ref eq 'Bio::EnsEMBL::Translation') {
    $object->transcript()->translate()->seq();
  }
  #Transcripts
  elsif($ref eq 'Bio::EnsEMBL::Transcript') {
    if($type eq 'cdna') {
      $object->spliced_seq();
    }
    elsif($type eq 'cds') {
      $object->translateable_seq();
    }
    else {
      $object->feature_Slice()->seq();
    }
  }
  # Anything else
  else {
    $object->feature_Slice()->seq();
  }
}