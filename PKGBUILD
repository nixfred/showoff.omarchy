# Maintainer: Fred Nix <frednix@gmail.com>

pkgname=showoff-omarchy
pkgver=0.1.0
pkgrel=1
pkgdesc='Show Omarchy off to a Windows or Mac person: a takeover show with live theme picking. Esc twice to stop.'
arch=('any')
url='https://github.com/nixfred/showoff.omarchy'
license=('MIT')
# quickshell runs the app; omarchy supplies every omarchy-* command the acts drive;
# hyprland supplies hyprctl; jq parses its JSON; bash runs the launcher and acts.
depends=('bash' 'hyprland' 'jq' 'omarchy' 'quickshell')
optdepends=('btop: the one-line install act (offered on screen if missing)'
            'cava: terminal aquarium'
            'cmatrix: terminal aquarium'
            'asciiquarium: terminal aquarium'
            'fastfetch: the under-the-hood act'
            'ttfx: the screensaver act'
            'neovim: the editor act (SHOWOFF_FLAGS=dev)'
            'ollama: the local AI act')
# Empty on purpose: with no source array makepkg builds from $startdir, so a clone is the source.
source=()

package() {
  local share="$pkgdir/usr/share/$pkgname"
  install -d "$share/app/ui" "$share/app/assets" "$share/bin"
  install -m644 "$startdir"/app/*.qml "$startdir"/app/*.js "$share/app/"
  install -m644 "$startdir"/app/ui/*.qml "$share/app/ui/"
  install -m644 "$startdir"/app/assets/*.png "$share/app/assets/"
  install -m755 "$startdir"/bin/showoff "$startdir"/bin/showoff-hypr "$share/bin/"
  # One command on PATH. The launcher resolves its own symlink to find app/ and
  # puts its bin/ (showoff-hypr) on PATH itself, so nothing else lands in /usr/bin.
  install -d "$pkgdir/usr/bin"
  ln -s "/usr/share/$pkgname/bin/showoff" "$pkgdir/usr/bin/showoff"
  install -Dm644 "$startdir"/showoff-omarchy.desktop "$pkgdir/usr/share/applications/showoff-omarchy.desktop"
  install -Dm644 "$startdir"/LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
