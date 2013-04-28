my $error = 0;

foreach my $lang (@kanjidic_lang) {
  $ENV{'DICT_LANG'} = $lang;

  $error = buildall();
}

!$error;
