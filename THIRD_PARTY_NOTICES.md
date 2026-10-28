# Third-party source notices

This distribution contains source trees under `third_party/` so a user can run RTL-SecCheck without cloning the two analysis projects separately.

## VerilogLAVD

- Upstream: <https://github.com/Chip-Security-Lab/VerilogLAVD>
- Purpose: RTL parsing, Neo4j graph construction and CWE-oriented detection.
- License: the upstream README identifies the project as MIT licensed. The upstream checkout included here does not contain a separate `LICENSE` file, so copy the current upstream license file into the distribution before publishing it.

## VeriPVD

- Upstream: <https://github.com/anwen0724/VeriPVD>
- Purpose: permission and information-flow analysis.
- License: follow the license and attribution terms published by the upstream repository. Verify those terms before publishing a redistributed package; the included checkout does not provide a separate license file.

The dependency lists in `requirements-lavd.txt` and `requirements-pvd.txt` are maintained separately because each engine uses its own virtual environment. The root `requirements.txt` is only for the RTL-SecCheck FastAPI backend.
