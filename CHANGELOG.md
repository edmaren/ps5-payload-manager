## v0.2.0

### 🚀 Features & UX Improvements
* **Sidebar State Persistence**: The sidebar's expanded/collapsed state is now persisted in `localStorage` across page reloads. ([7570084](https://github.com/itsPLK/ps5_next_menu/commit/7570084))
* **Settings Page Redesign**: Updated `SettingsView` layout to a responsive grid for better visual alignment and UI consistency. ([2e7de34](https://github.com/itsPLK/ps5_next_menu/commit/2e7de34))
* **UX & Navigation Enhancements**:
  * Added automatic scrolling to the **USB Storage** section when clicking the redirect button in the Autoload section. ([6d14acf](https://github.com/itsPLK/ps5_next_menu/commit/6d14acf))
  * Added automatic scrolling to the top of the main container when changing views. ([75b20ce](https://github.com/itsPLK/ps5_next_menu/commit/75b20ce))
* **Visual Polish**:
  * Added dedicated favicon and application icons. ([c8c380b](https://github.com/itsPLK/ps5_next_menu/commit/c8c380b))
  * Fixed alignment and spacing on the `DonateView`. ([10c4233](https://github.com/itsPLK/ps5_next_menu/commit/10c4233))
  * Refined download modal title. ([7dee294](https://github.com/itsPLK/ps5_next_menu/commit/7dee294))

### 🛠️ Backend & Bug Fixes
* **Directory Cleanup**: Empty directories are now automatically cleaned up after deleting a payload (fixes [#24](https://github.com/itsPLK/ps5-payload-manager/issues/24)). ([5ff5295](https://github.com/itsPLK/ps5_next_menu/commit/5ff5295))
* **USB Payload Loading**: Fixed loading and scanning payloads from the root directory of a USB drive, limiting root scans strictly to the root level. ([bfc4d09](https://github.com/itsPLK/ps5_next_menu/commit/bfc4d09))
* **Daemon Reliability**: Daemon startup now safely replaces existing instances. ([a34ecff](https://github.com/itsPLK/ps5_next_menu/commit/a34ecff))
* **Error Reporting**: Improved launch error reporting back to the user when a payload fails to execute. ([38b1124](https://github.com/itsPLK/ps5_next_menu/commit/38b1124))
* **Log Reduction**: Removed verbose payload scanning status logs under normal operating conditions to prevent spam. ([0380757](https://github.com/itsPLK/ps5_next_menu/commit/0380757))

### ⚙️ CI/CD & Build System
* **GitHub Releases**: Added an on-demand automated release workflow (`release.yml`) to compile, package, and upload the build ELF binary. ([10b786b](https://github.com/itsPLK/ps5_next_menu/commit/10b786b))
* **Docker Build Strategy**: Migrated the SDK image reference to a dedicated `ps5-payload-sdk-pldmgr` tag to avoid image conflicts. ([cfba6b8](https://github.com/itsPLK/ps5_next_menu/commit/cfba6b8))
* **Build Portability**: Made frontend build scripts (`sed` commands) compatible and portable across macOS and Linux environment hosts. ([54c2728](https://github.com/itsPLK/ps5_next_menu/commit/54c2728))
* **Script Housekeeping**: Removed deprecated curl shutdown steps from `deploy.sh`. ([1ebcf98](https://github.com/itsPLK/ps5_next_menu/commit/1ebcf98))

**Full Changelog**: [v0.1.1...v0.2.0](https://github.com/itsPLK/ps5_next_menu/compare/v0.1.1...v0.2.0)

## v0.1.1

- Resolved legacy WebKit (PS5 4.03 / Safari 12) compatibility bugs.
- Improved autoload countdown synchronization.


## v0.1.0

- Initial release
