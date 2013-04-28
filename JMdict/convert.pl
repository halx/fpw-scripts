my $error = 0;

foreach my $lang in (@JMdict_lang) {
  $ENV{'DICT_LANG'} = $lang;

  $error = buildall();
}

$error;
