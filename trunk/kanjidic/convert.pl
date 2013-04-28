foreach my $lang in (@kanjidic_lang) {
  $ENV{'DICT_LANG'} = $lang;
  buildall();
}

1;
