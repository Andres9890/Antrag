# Antrag

[![GitHub Release](https://img.shields.io/github/v/release/khcrysalis/antrag?include_prereleases)](https://github.com/khcrysalis/protokolle/releases)
[![GitHub License](https://img.shields.io/github/license/khcrysalis/antrag?color=%23C96FAD)](https://github.com/khcrysalis/protokolle/blob/main/LICENSE)

An app to list iOS/iPadOS apps. This version relies on [TrollStore](https://github.com/opa334/TrollStore) to access installed apps directly on device.

### Features

- List "System" & "User" apps
- Basic filtering

## Download

Visit [releases](https://github.com/khcrysalis/Antrag/releases) and get the latest `.ipa`.

## How does it work?

- Establish a heartbeat with a TCP provider for compatibility with older setups.
- When installed through TrollStore, the app reads the application list directly from the device's TrollStore container without needing pairing files.

This version does not require external pairing files. Instead, make sure the app is installed through TrollStore to enable local management of applications.

## Building

#### Minimum requirements

- Xcode 16
- Swift 5.9
- iOS 16

1. Clone repository
    ```sh
    git clone https://github.com/khcrysalis/Antrag
    ```

2. Compile
    ```sh
    cd Antrag
    gmake
    ```

3. Updating
    ```sh
    git pull
    ```

Using the makefile will automatically create an adhoc ipa inside the packages directory, using this to debug or report issues is not recommend. When making a pull request or reporting issues, it's generally advised you've used Xcode to debug your changes properly.

## Sponsors

| Thanks to all my [sponsors](https://github.com/sponsors/khcrysalis)!! |
|:-:|
| <img src="https://raw.githubusercontent.com/khcrysalis/github-sponsor-graph/main/graph.png"> |
| _**"samara is cute" - Vendicated**_ |

## Acknowledgements

- [Samara](https://github.com/khcrysalis) - The maker
- [TrollStore](https://github.com/opa334/TrollStore) - Provides access to installed apps and installation management.

## License 

This project is licensed under the GPL-3.0 license. You can see the full details of the license [here](https://github.com/khcrysalis/Feather/blob/main/LICENSE). Code from Antoine is going to be under MIT, if you figure out where that is.

By contributing to this project, you agree to license your code under the GPL-3.0 license as well (including agreeing to license exceptions), ensuring that your work, like all other contributions, remains freely accessible and open.
