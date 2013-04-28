foreach my $s (0, 1) {
  $ENV{'SHORT'} = $s;
  buildall();
}

1;
