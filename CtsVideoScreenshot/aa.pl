
my $path = "/lekan/content/video/10/00/26/1/E1/";

my ($rel_path) = $path =~ /(\/(\w+\/)+(\d+))/;
print "$rel_path\n";
