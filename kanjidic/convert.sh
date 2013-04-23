for lang in $kanjidic_lang; do
  export DICT_LANG=$lang

  buildall
done
