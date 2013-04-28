my $error = 0;

foreach my $s (0, 1) {
  $ENV{'SHORT'} = $s;

  $error = buildall();
}

!$error;
