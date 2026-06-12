# graphify — turn a folder of code/docs/media into a queryable knowledge graph.
# Published on PyPI as `graphifyy`; the binary it installs is `graphify`.
#
# graphify lists ~26 tree-sitter grammars as dependencies but loads each one
# lazily (`importlib.import_module` guarded by `except ImportError`), so a
# missing grammar only disables that one language. nixpkgs ships 7 of them; we
# additionally build the common ones (TypeScript, Go, Java, C, C++, Ruby) from
# their PyPI sdists. The remaining grammars are intentionally omitted — adding
# them later is just another `mkGrammar` entry.
{
  lib,
  python3Packages,
  fetchPypi,
  fetchFromGitHub,
}:
let
  inherit (python3Packages)
    buildPythonPackage
    buildPythonApplication
    setuptools
    tree-sitter
    networkx
    numpy
    rapidfuzz
    mcp
    neo4j
    pypdf
    markdownify
    watchdog
    ;

  # tree-sitter grammar bindings are uniform: setuptools compiles the vendored
  # parser C into an abi3 extension exposing `language*()`. tree-sitter itself
  # is only a runtime ("core" extra) dependency, not needed to build or import.
  #
  # We fetch from GitHub rather than the PyPI sdist: several grammar sdists
  # (java, typescript, cpp, ruby) omit the generated src/tree_sitter/*.h headers,
  # so they fail to compile; the tagged repos vendor them.
  mkGrammar =
    {
      pname,
      version,
      hash,
    }:
    let
      module = lib.replaceStrings [ "-" ] [ "_" ] pname;
    in
    buildPythonPackage {
      inherit pname version;
      pyproject = true;

      src = fetchFromGitHub {
        owner = "tree-sitter";
        repo = pname;
        tag = "v${version}";
        inherit hash;
      };

      build-system = [ setuptools ];
      optional-dependencies.core = [ tree-sitter ];

      doCheck = false; # grammar repos ship no Python tests
      pythonImportsCheck = [ module ];

      meta = {
        description = "${lib.removePrefix "tree-sitter-" pname} grammar for tree-sitter";
        homepage = "https://github.com/tree-sitter/${pname}";
        license = lib.licenses.mit;
      };
    };

  extraGrammars = lib.mapAttrs (_: mkGrammar) {
    tree-sitter-typescript = {
      pname = "tree-sitter-typescript";
      version = "0.23.2";
      hash = "sha256-CU55+YoFJb6zWbJnbd38B7iEGkhukSVpBN7sli6GkGY=";
    };
    tree-sitter-go = {
      pname = "tree-sitter-go";
      version = "0.25.0";
      hash = "sha256-y7bTET8ypPczPnMVlCaiZuswcA7vFrDOc2jlbfVk5Sk=";
    };
    tree-sitter-java = {
      pname = "tree-sitter-java";
      version = "0.23.5";
      hash = "sha256-OvEO1BLZLjP3jt4gar18kiXderksFKO0WFXDQqGLRIY=";
    };
    tree-sitter-c = {
      pname = "tree-sitter-c";
      version = "0.24.2";
      hash = "sha256-Juuf57GQI7OAP6O03KtSzyKJAoXtGKjyYJ+sTM1A4mU=";
    };
    tree-sitter-cpp = {
      pname = "tree-sitter-cpp";
      version = "0.23.4";
      hash = "sha256-tP5Tu747V8QMCEBYwOEmMQUm8OjojpJdlRmjcJTbe2k=";
    };
    tree-sitter-ruby = {
      pname = "tree-sitter-ruby";
      version = "0.23.1";
      hash = "sha256-iu3MVJl0Qr/Ba+aOttmEzMiVY6EouGi5wGOx5ofROzA=";
    };
  };
in
buildPythonApplication rec {
  pname = "graphify";
  version = "0.8.37";
  pyproject = true;

  src = fetchPypi {
    pname = "graphifyy";
    inherit version;
    sha256 = "e470d73d87f5fd4124f8c71dc86b1c43703686eaa5df4641dd217a2e1e88b751";
  };

  build-system = [ setuptools ];

  # The dist metadata pins ~26 grammars we don't all ship; graphify tolerates
  # their absence at runtime, so skip the installed-deps completeness check.
  dontCheckRuntimeDeps = true;

  dependencies = [
    networkx
    numpy
    rapidfuzz
    tree-sitter
    # grammars from nixpkgs
    python3Packages.tree-sitter-python
    python3Packages.tree-sitter-javascript
    python3Packages.tree-sitter-rust
    python3Packages.tree-sitter-c-sharp
    python3Packages.tree-sitter-json
    # enabled feature extras
    mcp
    neo4j
    pypdf
    markdownify
    watchdog
  ]
  ++ lib.attrValues extraGrammars;

  pythonImportsCheck = [ "graphify" ];

  passthru.grammars = extraGrammars;

  meta = {
    description = "Turn a folder of code, docs, papers, images, or videos into a queryable knowledge graph";
    homepage = "https://github.com/safishamsi/graphify";
    changelog = "https://github.com/safishamsi/graphify/releases";
    license = lib.licenses.mit;
    mainProgram = "graphify";
  };
}
