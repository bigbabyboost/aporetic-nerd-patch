{
  description = "Nerd-font patched Aporetic fonts (ttf-unhinted only)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system}.default = pkgs.stdenv.mkDerivation rec {
        pname = "patched-aporetic-fonts";
        version = "1.2.0";

        src = pkgs.fetchFromGitHub {
          owner = "protesilaos";
          repo = "aporetic";
          rev = version;
          sha256 = "sha256-1BbuC/mWEcXJxzDppvsukhNtdOLz0QosD6QqI/93Khc=";
        };

        nativeBuildInputs = with pkgs; [
          fontforge
          python3
          nerd-font-patcher
          findutils
        ];

        patchPhase = ''
          set -euo pipefail
          mkdir -p patched

          echo "🔍 Searching for all TTF-Unhinted folders under aporetic-*..."

          find . -type d -iname "ttf-unhinted" | while read dir; do
            echo "📂 Found: $dir"

            find "$dir" -type f -iname "*.ttf" | while read font; do
              if echo "$font" | grep -iq "mono"; then
                echo "🎯 Patching $font (mono)"
                nerd-font-patcher "$font" --complete --quiet --output patched
              else
                echo "🎯 Patching $font propo with --variable-width-glyphs"
                nerd-font-patcher "$font" --complete --quiet --variable-width-glyphs --output patched
              fi
            done
          done

          echo "✅ Finished patching fonts. Contents of ./patched:"
          ls -lh patched
        '';

        installPhase = ''
          set -euo pipefail
          dst=$out/share/fonts/truetype/aporetic-nerd
          mkdir -p "$dst"

          if ls patched/*.ttf > /dev/null 2>&1; then
            cp patched/*.ttf "$dst/"
          else
            echo "⚠️ No patched fonts found to install!"
            exit 1
          fi
        '';

        meta = with pkgs.lib; {
          description = "Nerd-font patched Aporetic fonts (ttf-unhinted only)";
          license = licenses.ofl;
          platforms = platforms.all;
        };
      };
    };
}
