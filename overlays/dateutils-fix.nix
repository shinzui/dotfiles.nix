final: prev: {
  dateutils = prev.dateutils.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      final.bison
      final.flex
    ];
    postPatch = (old.postPatch or "") + ''

      substituteInPlace src/dexpr-parser.y src/dexpr-scanner.l \
        --replace-fail 'extern int yyparse();' 'extern int yyparse(dexpr_t *cur);'
    '';
  });
}
