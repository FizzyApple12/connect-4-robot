These configs are verbose to enable bootstrapping the NixOS server from scratch. To build the server:
1. Run `cd /etc/nixos && rm -r .`
2. Run `git init && git remote add origin https://github.com/FizzyApple12/connect-4-robot`
3. Run `git fetch origin && git checkout origin/main -- control-server-nix-configs`
  1. You should now have populated the `/etc/nixos` folder. Rerun Step 3 as needed.
4. Run `sudo nixos-rebuild switch` and let the configuration build
5. Run `sudo nixos-rebuild switch --flake .#c4-server`
6. Spill

These commands may be slightly redundant, but as long as the server builds the steps can be optimized later.
This repo is private at time of writing. To pull the control-server flake, step 5 needs to be modified.
Run the following command, replacing `...` with a Github PAT with the "Contents" Read-Only permission.
- Run `sudo NIX_CONFIG="extra-access-tokens = github.com=..." nixos-rebuild switch --flake .#c4-server`
