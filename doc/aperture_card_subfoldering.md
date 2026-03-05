# Subdivide aperture card image folders on Windows 11

This project includes a Ruby script to split each parent folder of images into range-based subfolders of fixed size.

## Script location

`script/subdivide_aperture_card_folders.rb`

## What it does

Given a root directory like:

- `D:\ApertureCards\IALVIP_Series1_Box1`
- `D:\ApertureCards\IALVIP_Series1_Box2`

It will process each immediate child folder (`IALVIP_Series1_Box1`, etc.), find image files directly inside that folder, sort them by filename, and move them into subfolders of 100 files each (by default).

Example output subfolders inside `IALVIP_Series1_Box1`:

- `IALVIP_Series1_Box1_000001_to_000100`
- `IALVIP_Series1_Box1_000101_to_000200`
- ...

If filenames end in numeric indexes (like `..._000009.jpg`), the script uses those index values for the range names.

## Requirements

1. Ruby installed on Windows 11.
2. Your folders available on a local drive (for example `D:`).

## Install Ruby on Windows 11

If Ruby is not installed, use [RubyInstaller for Windows](https://rubyinstaller.org/):

1. Download and install Ruby+Devkit.
2. During install, allow it to add Ruby to your PATH.
3. Open a new PowerShell window and verify:

```powershell
ruby -v
```

## Run the script

Open PowerShell in the repository folder and run:

```powershell
ruby script/subdivide_aperture_card_folders.rb --root "D:/ApertureCards" --dry-run
```

Review the planned folder creation and moves.

If everything looks correct, run without `--dry-run`:

```powershell
ruby script/subdivide_aperture_card_folders.rb --root "D:/ApertureCards"
```

## Optional flags

- `--files-per-folder 100` (default is 100)
- `--extensions .jpg,.jpeg` (default includes `.jpg` and `.jpeg`)
- `--dry-run` (preview only)

Example with explicit options:

```powershell
ruby script/subdivide_aperture_card_folders.rb --root "D:/ApertureCards" --files-per-folder 100 --extensions .jpg,.jpeg
```

## Safety notes

- Start with `--dry-run` first.
- Keep a backup before large file operations.
- The script only processes files directly inside each parent folder (not nested subfolders).
