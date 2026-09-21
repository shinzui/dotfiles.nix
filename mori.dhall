let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/3522f4a51181d73c9c90fc27a7c0838bd29ae95f/package.dhall
        sha256:dcb19e2312e790bad14e622cc98a1281cd2298c5b564a2f0d0534d3c718d8803

in  Schema.Project::{
    , project = Schema.ProjectIdentity::{
      , name = "dotfiles.nix"
      , namespace = "shinzui"
      , stableId = Some "project_01m32deg9mesb9h3z54gpwa3z6"
      , type = Schema.PackageType.Other "configuration"
      , language = Schema.Language.Nix
      , lifecycle = Schema.Lifecycle.Active
      , description = Some
          "Personal macOS system configuration: nix-darwin for the system, home-manager for the user environment, wired together with flake-parts"
      , domains = [ "Nix", "Darwin", "Workstation" ]
      }
    , repos =
      [ Schema.Repo::{
        , name = "dotfiles.nix"
        , github = Some "shinzui/dotfiles.nix"
        }
      ]
    , packages = ./mori/packages.dhall
    , dependencies = [ "hercules-ci/flake-parts" ]
    , dependencyRefs =
      [ Schema.MoriRef::{ namespace = "hercules-ci", name = "flake-parts" } ]
    }
