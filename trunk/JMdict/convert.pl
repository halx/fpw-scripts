my $error = 0;

foreach my $lang (@JMdict_lang) {
  $ENV{'DICT_LANG'} = $lang;

  $error = buildall();
}

!$error;
