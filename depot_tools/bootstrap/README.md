# Windows binary tool bootstrap

This directory has the 'magic' for the `depot_tools` windows binary update
mechanisms.

A previous Python may actually be in use when it is run, preventing us
from replacing it outright without breaking running code. To accommodate this,
and Python cleanup, we handle Python in two stages:

1. Use CIPD to install Python.
2. Use "bootstrap.py" as a post-processor to install generated files and
   fix-ups.

## Software bootstrapped
  * Python 3 (https://www.python.org/)

## Mechanism

Any time a user runs `gclient` on windows, it will invoke the `depot_tools`
autoupdate script [depot_tools.bat](../../update_depot_tools.bat). This, in
turn, will run [win_tools.bat](./win_tools.bat), which does the bulk of the
work.

`win_tools.bat` will successively look to see if the local version of the binary
package is present, and if so, if it's the expected version. If either of those
cases is not true, it will download and unpack the respective binary.

Installation of Python is done by the [win_tools.bat](./win_tools.bat)
script, which uses CIPD (via the [cipd](/cipd.bat) bootstrap) to acquire and
install each package into the root of the `depot_tools` repository. Afterwards,
the [bootstrap.py](./bootstrap.py) Python script is invoked to install stubs,
wrappers, and support scripts into `depot_tools` for end-users. This includes
checking whether the current global Git config matches recommended settings.

### Manifest

The Python version is specified in [manifest.txt](./manifest.txt).

There is an associated file,
[manifest_bleeding_edge.txt](./manifest_bleeding_edge.txt), that can be used
to canary a new version on select bots. Any bots with a `.bleeding_edge` file
in their `depot_tools` root will automatically use the bleeding edge manifest.
This allows opt-in systems to test against new versions of Python. Once
the version has been verified correct, `manifest.txt` can be updated to the
same specification, which will cause the remainder of systems to update.

### Bundles

Python bundles are maintained by 3pp builders. See the
[3pp docs](https://chromium.googlesource.com/infra/infra/+/HEAD/3pp/README.md)
for more info.

Note that in order for the update to take effect, `gclient` currently needs to
run twice. The first time it will update the `depot_tools` repo, and the second
time it will see the new Python version and update to it. This is a bug that
should be fixed, in case you're reading this and this paragraph infuriates you
more than the rest of this README.

## Testing

After any modification to this script set, a test sequence should be run on a
Windows bot.

The post-processing will regenerate "python3.bat" to point to the current Python
instance. Any previous Python installations will stick around, but new
invocations will use the new instance. Old installations will die off either due
to processes terminating or systems restarting. When this happens, they will be
cleaned up by the post-processing script.

Testing
=======

For each of the following test scenarios, run these commands and verify that
they are working:

```bash
:: Assert that `gclient` invocation will update (and do the update).
gclient version

:: Assert that Python 3 fundamentally works.
python3 -c "import queue; print(dir(queue))"

:: Assert that Python scripts work from `cmd.exe`.
git map-branches

:: Assert that `git bash` works.
git bash

## (Within `git bash`) assert that Python 3 fundamentally works.
python3 -c "import queue; print(dir(queue))"
## (Within `git bash`) assert that Python scripts work.
git map-branches
```

Run this sequence through the following upgrade/downgrade procedures:

* Cold default installation.
  - Clean `depot_tools` via: `git clean -x -f -d .`
  - Run through test steps.
  - Test upgrade to bleeding edge (if it differs).
    - Run `python3.bat` in another shell, keep it open
    - Add `.bleeding_edge` to `depot_tools` root.
    - Run through test steps.
    - In the old `python3.bat` shell, run `import queue`, confirm that it
      works.
    - Close the Python shell, run `gclient version`, ensure that old directory
      is cleaned.
* Cold bleeding edge installation.
  - Clean `depot_tools` via: `git clean -x -f -d .`
  - Add `.bleeding_edge` to `depot_tools` root.
  - Run through test steps.
  - Test downgrade to default (if it differs).
    - Run `python3.bat` in another shell, keep it open
    - Delete `.bleeding_edge` from `depot_tools` root.
    - Run through test steps.
    - In the old `python3.bat` shell, run `import queue`, confirm that it
      works.
    - Close the Python shell, run `gclient version`, ensure that old directory
      is cleaned.
* Warm bleeding edge upgrade.
  - Clean `depot_tools` via: `git clean -x -f -d .`
  - Run `gclient version` to load defaults.
  - Run `python3.bat` in another shell, keep it open
  - Add `.bleeding_edge` to `depot_tools` root.
  - Run through test steps.
  - In the old `python3.bat` shell, run `import queue`, confirm that it
    works.
  - Close the Python shell, run `gclient version`, ensure that old directory is
    cleaned.
* Upgradable and Revertible.
  - Checkout current `HEAD`.
  - Run `gclient version` to load HEAD toolchain (initial).
  - Apply the candidate patch.
  - Run through test steps (upgrade).
  - Checkout current `HEAD` again.
  - Run `gclient version` to load HEAD toolchain (revert).
  - Run through test steps.

This will take some time, but will ensure that all affected bots and users
should not encounter any problems due to the change. As systems and users are
migrated off of this implicit bootstrap, the testing procedure will become less
critical.
