[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://nimble.directory/pkg/procwatch)

[![Language](https://img.shields.io/badge/language-Nim-orange.svg?style=plastic)](https://nim-lang.org/)

[![GitHub](https://img.shields.io/badge/license-GPL--3.0-informational?style=plastic)](https://www.gnu.org/licenses/gpl-3.0.txt)
[![Liberapay patrons](https://img.shields.io/liberapay/patrons/Akito?style=plastic)](https://liberapay.com/Akito/)

## What
Uses the `/proc` pseudo-filesystem, to notify of completed Linux processes.

## Why
Compiling Gentoo or compiling Linux on a Raspberry Pi 0 W can take days.
If you do not want to check, when the compilation has finally finished, but instead be automatically notified on completion, this is the app for you.

## How
Send an e-mail, when process with the PID `314` exits.

```bash
procwatch --pid 314 --to mail@boom.me
```

Watch all processes of the name `appy`. Dispatch a desktop notification, instead of an e-mail.

```bash
procwatch --command appy --notify
```

For more advanced possibilities, check the `help` on the command line.

```bash
procwatch --help
```

## Where
For now, you can download pre-compiled binaries in the Releases section of this repository.
It is planned to package this properly, once it has reached a rather stable state.

## Goals
* Reliability
* Get process watching done. Do not overload with unnecessary features.

## Project Status
Before Pre-Alpha

## TODO
* Reach Stability.

## License
Copyright © 2022  Akito <the@akito.ooo>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.