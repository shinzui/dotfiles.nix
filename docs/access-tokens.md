# GitHub authentication for Nix

GitHub SSH keys authorize SSH Git operations. Nix's `github:` fetcher uses HTTPS
and needs a token for private repository archives. Configure this separately
from `gh` login; a successful SSH clone or prerequisite checker does not prove
all flake inputs can be downloaded on a clean machine.

Use a separate fine-grained token for each workstation, targeting `shinzui`,
with All repositories access and Contents read-only. Set an expiration and
rotate the token by encrypting its replacement and completing the same verified
handoff. Tokens cannot access repositories owned by a different resource owner;
organization access needs its own authorization.

The currently declared organization library inputs use SSH overrides, preserving
their existing source revisions and content hashes. A machine's registered SSH
key must also be authorized for those organization repositories. Review these
override revisions when updating the consuming tool inputs. This avoids requiring
an additional organization token for the current flake graph.

Store ciphertext and host-specific secret declarations in
`mori://shinzui/dotfiles-private.nix`. Yujin selects its dedicated private host
module; Sungkyung keeps the existing shared declaration. The public
[consumer](../darwin/secrets.nix) includes the installed agenix secret by path.
Never put the token value in Nix settings, a flake input URL, a command argument,
or tracked plaintext. Temporary `*-gh-token.tmp` files are ignored by both repos
and must be deleted after encryption and decrypt-to-comparison verification.

Before the first rebuild, use the [runbook's authentication phase](new-machine-bootstrap.md#6-bootstrap-nix-authentication--trusted-mac-then-new-mac).
`bin/bootstrap-nix-auth.py prepare` uses standalone age to create a protected
runtime credential. Its `run` command scopes authentication to a build and passes
the configuration file path explicitly for sudo switches. Its `verify` and
`cleanup` commands require normal user/root Nix configuration and the managed
agenix token to work before removing the bootstrap credential.

Nix supports `access-tokens`, configuration includes, and
`NIX_USER_CONF_FILES`: see the [Nix configuration reference](https://nix.dev/manual/nix/stable/command-ref/conf-file.html).
Fine-grained repository archive downloads require Contents read permission:
see [GitHub's archive API](https://docs.github.com/en/rest/repos/contents#download-a-repository-archive-tar).
