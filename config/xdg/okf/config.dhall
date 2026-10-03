-- okf configuration. See `okf config show` for the effective values,
-- and `okf config agent` for how each agent setting was resolved.
let Provider = < Claude | Codex >

let Effort = < Minimal | Low | Medium | High | XHigh | Max >

in  { kit =
        { repoUrl = "https://github.com/shinzui/okf-kit.git"
        , providers = [ Provider.Claude ]
        }
    , agent =
        -- Shared defaults for every agent-launching command.
        { provider = None Provider
        , model = None Text
        , effort = None Effort
        , systemPrompt = None Text
        -- Per-command settings; these win over the shared defaults above.
        , assist =
            { provider = None Provider
            , model = None Text
            , effort = None Effort
            , systemPrompt = None Text
            }
        }
    , profiles =
        { registries =
            [ "https://raw.githubusercontent.com/shinzui/okf-profiles/v0.14.0/package.dhall sha256:87d2e4076b2491ee608ac1c7a28b24156ba2634f2b09de49ad4ba79f039acf50"
            ]
        }
    -- Shortcuts: the first argument after `okf` expands to the text, split on
    -- whitespace, so no expansion may need a space inside one argument.
    , aliases = toMap
        { irs =
            "concepts docs/improvement-requests --where status!=completed --show requestId --show status --sort requestId"
        , bugs =
            "concepts docs/bug-reports --where status!=fixed --where status!=duplicate --show bugId --show status --show severity --sort bugId"
        }
    }
