foreach my $lang in (@JMdict_lang) {
  $ENV{'DICT_LANG'} = $lang;
  buildall();
}

1;
