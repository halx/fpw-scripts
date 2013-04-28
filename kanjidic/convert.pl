my $error = 0;

foreach my $lang in (@kanjidic_lang) {
  $ENV{'DICT_LANG'} = $lang;

  $error = buildall();
}

$error;
