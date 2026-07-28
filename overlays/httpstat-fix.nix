# httpstat 1.3.2's setup.py reads its version via `ast.Str.s`, which was
# removed in Python 3.12. nixpkgs now defaults python3 to 3.14, so the build
# dies with `AttributeError: 'Constant' object has no attribute 's'`.
final: prev: {
  httpstat = prev.httpstat.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace setup.py \
        --replace-fail 'ast.parse(line).body[0].value.s' 'ast.parse(line).body[0].value.value'
    '';
  });
}
