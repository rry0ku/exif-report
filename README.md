# exif-report

A fast and human-readable EXIF metadata inspector for the terminal.

`exif-report` parses image metadata using `exiftool`, extracts critical camera, exposure, location, and file details into formatted sections, and provides a colour-coded view of all raw metadata tags.

## Features

- Clean summary sections for File Information, Camera and Hardware, Exposure and Settings, Date and Timestamp, Geolocation, Color Profiles, and Embedded Thumbnails.
- Formatted photography settings (shutter speed, aperture, ISO, exposure mode).
- Human-readable relative time calculations (e.g. 2 years, 3 months ago).
- Geolocation mapping links (Google Maps, OpenStreetMap, Bing Maps, Wikimapia, and Google Street View).
- Embedded thumbnail detection and security warning.
- Colour-coded raw metadata output grouped by ExifTool tag category.

## Requirements and Installation

The script requires Bash 4+, ExifTool, Python 3, GNU Coreutils, and Awk.

### Debian / Ubuntu / Linux Mint / Pop!_OS

```bash
sudo apt update
sudo apt install libimage-exiftool-perl python3 coreutils gawk
```

### Arch Linux / Manjaro / EndeavourOS

```bash
sudo pacman -S perl-image-exiftool python coreutils gawk
```

### Fedora / RHEL / Rocky Linux / AlmaLinux

```bash
sudo dnf install perl-Image-ExifTool python3 coreutils gawk
```

### openSUSE (Tumbleweed / Leap)

```bash
sudo zypper install perl-Image-ExifTool python3 coreutils gawk
```

### Alpine Linux

```bash
sudo apk update
sudo apk add bash exiftool python3 coreutils gawk
```

### Void Linux

```bash
sudo xbps-install -S exiftool python3 coreutils gawk
```

### Gentoo Linux

```bash
sudo emerge --ask media-libs/exiftool dev-lang/python sys-apps/coreutils sys-apps/gawk
```

### NixOS / Nix Package Manager

Run directly in a Nix shell:
```bash
nix-shell -p exiftool python3 coreutils gawk
```

Or install to user profile:
```bash
nix-env -iA nixpkgs.exiftool nixpkgs.python3 nixpkgs.coreutils nixpkgs.gawk
```

### macOS (Homebrew)

```bash
brew install exiftool python3 coreutils gawk
```

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/exif-report.git
cd exif-report
```

2. Make the script executable:
```bash
chmod +x exif-report.sh
```

3. Run the report on an image:
```bash
./exif-report.sh path/to/image.jpg
```

Optional: Install system-wide to `/usr/local/bin`:
```bash
sudo cp exif-report.sh /usr/local/bin/exif-report
sudo chmod +x /usr/local/bin/exif-report
```

Then run anywhere:
```bash
exif-report photo.jpg
```

## Usage

```bash
exif-report.sh <image-file>
```

Supported formats include JPEG, PNG, TIFF, WebP, HEIC, RAW formats (CR2, NEF, ARW, DNG), and any media format supported by ExifTool.
