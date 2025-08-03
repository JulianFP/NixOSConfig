{
  python3Packages,
}:
python3Packages.buildPythonPackage rec {
  pname = "hass_ldap_auth";
  version = "0.1.0";
  pyproject = true;

  src = ./.;

  build-system = [ python3Packages.setuptools ];

  nativeBuildInputs = with python3Packages; [ setuptools-scm ];

  propagatedBuildInputs = with python3Packages; [
    bonsai
  ];

  pythonImportsCheck = [ pname ];
}
