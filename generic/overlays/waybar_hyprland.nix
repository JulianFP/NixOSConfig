final: prev:
{
  waybar = prev.waybar.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      (prev.fetchpatch {
        url = "https://github.com/Alexays/Waybar/pull/3180.patch";
        hash = "sha256-OWC8ZBzKRn7WfSjKsvVvTGenEUtqkg5M+Gx1jO/cobs=";
      })
    ];
  });
}
