# Zip aperture card subfolders on Windows 11

Use this script after you have already split each box folder into subfolders (for example `..._000001_to_000100`).

## Script location

`script/zip_aperture_card_subfolders.rb`

## What it does

Given a root folder like:

- `D:\ApertureCards\IALVIP_Series1_Box1`
- `D:\ApertureCards\IALVIP_Series1_Box2`

The script will:

1. Enter each box folder under `--root`.
2. Find each immediate subfolder in that box.
3. Create a zip for each subfolder.
4. Write zips to `C:\Users\benwb\Documents\ApertureCards\<box-folder>\` by default.

Example output zip path:

- `C:\Users\benwb\Documents\ApertureCards\IALVIP_Series1_Box1\IALVIP_Series1_Box1_000001_to_000100.zip`

## Requirements

1. Ruby installed on Windows 11.
2. PowerShell (included with Windows 11).

## Run (preview first)

```powershell
ruby script/zip_aperture_card_subfolders.rb --root "D:/ApertureCards" --dry-run
```

## Run for real

```powershell
ruby script/zip_aperture_card_subfolders.rb --root "D:/ApertureCards"
```

## Optional flags

- `--output-root "C:/Users/benwb/Documents/ApertureCards"` (default shown)
- `--overwrite` to replace existing zips
- `--dry-run` for preview only

Example:

```powershell
ruby script/zip_aperture_card_subfolders.rb --root "D:/ApertureCards" --output-root "C:/Users/benwb/Documents/ApertureCards" --overwrite
```

## Safety notes

- Use `--dry-run` first.
- Keep backup copies before large batch jobs.
- The script zips immediate subfolders only (not deeper nested folders).
