# spotkin_flutter

(in development)

A Flutter web front-end for [Spotkin](<https://github.com/riverscuomo/spotkin>) currently deployed at <https://spotkin-fd416.web.app>

 Right now, you can:

- log into Spotify through our website.
- set a target playlist (must be a playlist you own)
- set any number of public playlists to source from, and the quantity of tracks to pull.
- click a button to update your playlist with the tracks from the source playlists.

## Getting Started

To run locally,  I use these launch settings in vscode:

```
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter Web",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--web-port",
        "8888"
      ]
    }
  ]
}
```

## Note

Essentially, this front end replaces the old spreadsheet method of storing and editing Spotkin jobs. <https://docs.google.com/spreadsheets/d/1z5MejG6EKg8rf8vYKeFhw9XT_3PxkDFOrPSEKT_jYqI/edit?gid=1936655481#gid=1936655481>
