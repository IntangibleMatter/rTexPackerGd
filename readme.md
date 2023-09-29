# rTexPacker Importer for Godot

This is just a simple plugin that lets you import rTexPacker sheets in Godot.

## Functionality:

- [x] Importing sheets as `AtlasTextures`
- [x] Importing `.rtpa`, and `.rtpb` files
- [x] Importing JSON
- [x] Importing XML

The JSON and XML importers are disabled by default, but can be enabled in
project settings.

## Use

Just output the rTexturePacker data and sheets wherever you want them in the
project, and watch as they get exported to a subfolder of the folder you
placed the file in, named after the file that was imported.
