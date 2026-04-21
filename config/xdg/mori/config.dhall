{ aliases = toMap
    { rs = "registry show --full"
    , rl = "registry list"
    , rlo = "registry list --observed"
    , s = "show --full"
    , od = "registry open-doc"
    , abc = "agent bootstrap --corpus"
    , aa = "agent assist"
    , sm = "schema migrate --apply"
    , smc = "schema migrate --file mori/cookbook.dhall --apply"
    }
}
