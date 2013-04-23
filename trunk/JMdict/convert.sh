for lang in $JMdict_lang; do
  export DICT_LANG=$lang
  buildall
done
