{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # CLI Applications
    amdgpu_top
  ];
}
