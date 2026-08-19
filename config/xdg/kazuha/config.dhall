-- kazuha configuration. See `kazuha help configuration` and `kazuha help aliases`.
-- Both top-level fields are required; `None` leaves the built-in defaults in place.
let CommitConfig =
      { provider : Optional Text, model : Optional Text, thinking : Optional Text }

let Commands = { commit : Optional CommitConfig }

in  { commands = None Commands
    , aliases = Some (toMap { gc = "git commit" })
    }
