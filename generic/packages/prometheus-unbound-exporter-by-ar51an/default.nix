{
  lib,
  buildGoModule,
  fetchFromGitHub
}:

buildGoModule {
  pname = "unbound-exporter";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "ar51an";
    repo = "unbound-exporter";
    rev = "25f963c2bf23de4fcd7910040807888b78ed3859";
    hash = "sha256-Xua5lSb8XkDuq8VvTivOHXKAejov92V8V4gqioetSGk=";
  };

  vendorHash = "sha256-KmJbi3ZFmhUnCxZazqBGm0A+YBEuUkvCzHZb/Nh5tXU=";

  meta = {
    description = "Alternative Prometheus exporter for Unbound DNS resolver tailored for ar51ans Grafana unbound-dashboard";
    mainProgram = "unbound-exporter";
    homepage = "https://github.com/letsencrypt/unbound_exporter";
    license = lib.licenses.asl20;
  };
}
