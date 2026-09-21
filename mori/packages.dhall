-- Packages this repository builds from source, as exposed by
-- `flake-modules/packages.nix` (`nix build .#<name>`).
--
-- Not listed here: `mina`, `shiki` and `okf`. Those attributes are
-- re-exports of flake inputs, owned by mori://shinzui/mina,
-- mori://shinzui/shiki and mori://shinzui/okf respectively.
--
-- `language` names the upstream implementation language, not the
-- packaging language -- every entry is a Nix derivation.

let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/3522f4a51181d73c9c90fc27a7c0838bd29ae95f/package.dhall
        sha256:dcb19e2312e790bad14e622cc98a1281cd2298c5b564a2f0d0534d3c718d8803

in  [ Schema.Package::{
      , name = "tmuxai"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.Go
      , path = Some "derivations/tmuxai.nix"
      , description = Some "AI assistant driving a tmux session (alvinunreal/tmuxai)"
      }
    , Schema.Package::{
      , name = "oq"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.Go
      , path = Some "derivations/oq.nix"
      , description = Some "Query and convert structured data formats (plutov/oq)"
      }
    , Schema.Package::{
      , name = "uuinfo"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.Rust
      , path = Some "derivations/uuinfo.nix"
      , description = Some "Decode and explain unique identifiers (racum/uuinfo)"
      }
    , Schema.Package::{
      , name = "ck"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.Rust
      , path = Some "derivations/ck.nix"
      , description = Some "Semantic grep over a codebase (BeaconBay/ck)"
      }
    , Schema.Package::{
      , name = "parqeye"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.Rust
      , path = Some "derivations/parqeye.nix"
      , description = Some
          "Parquet file inspector (kaushiksrini/parqeye); built against nixos-25.11 rustc"
      }
    , Schema.Package::{
      , name = "container"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.Swift
      , path = Some "derivations/apple-container.nix"
      , description = Some
          "Apple Container pinned ahead of nixpkgs; shadows nixpkgs' own `container`"
      }
    , Schema.Package::{
      , name = "pg_rman"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.Other "C"
      , path = Some "derivations/pg_rman.nix"
      , description = Some "Backup and recovery manager for PostgreSQL 18"
      }
    , Schema.Package::{
      , name = "beautiful-mermaid"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.TypeScript
      , path = Some "derivations/beautiful-mermaid"
      , description = Some "Mermaid diagram renderer CLI, built with bun2nix"
      }
    , Schema.Package::{
      , name = "markit"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.TypeScript
      , path = Some "derivations/markit"
      , description = Some "HTML-to-Markdown converter (Michaelliv/markit), built with bun2nix"
      }
    , Schema.Package::{
      , name = "defuddle"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.TypeScript
      , path = Some "derivations/defuddle"
      , description = Some "Article extraction from web pages, built with bun2nix"
      }
    , Schema.Package::{
      , name = "jaeger-ui"
      , type = Schema.PackageType.Application
      , language = Schema.Language.TypeScript
      , path = Some "derivations/jaeger-ui"
      , description = Some "Jaeger tracing web UI (jaegertracing/jaeger-ui)"
      }
    , Schema.Package::{
      , name = "hunk"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.Nix
      , path = Some "derivations/hunk"
      , description = Some
          "Interactive diff tool; repackages the prebuilt `hunkdiff` npm binaries"
      }
    , Schema.Package::{
      , name = "bootstrap-repos"
      , type = Schema.PackageType.Tool
      , language = Schema.Language.Shell
      , path = Some "derivations/bootstrap-repos"
      , description = Some
          "Clone every mori-registered project to the path the registry records"
      }
    ]
