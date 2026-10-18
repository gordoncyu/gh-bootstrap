{
    description = "Get GitHub SSH credentials onto a fresh machine (Bitwarden or new key + gh)";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    outputs = { nixpkgs, ... }:
        let
            forAll = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        in
        {
            packages = forAll (system:
                let pkgs = nixpkgs.legacyPackages.${system}; in
                {
                    default = pkgs.writeShellApplication {
                        name = "gh-creds";
                        runtimeInputs = [ pkgs.gh pkgs.bitwarden-cli pkgs.jq pkgs.openssh pkgs.coreutils pkgs.gnugrep pkgs.hostname ];
                        text = builtins.readFile ./gh-creds.sh;
                    };
                });
        };
}
