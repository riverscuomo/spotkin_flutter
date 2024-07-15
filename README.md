# spotkin_flutter

A Flutter web front-end for Spotkin. <https://github.com/riverscuomo/spotkin>
It should replace the spreadsheet method <https://docs.google.com/spreadsheets/d/1z5MejG6EKg8rf8vYKeFhw9XT_3PxkDFOrPSEKT_jYqI/edit?gid=1936655481#gid=1936655481>

Currently deployed at <https://spotkin-fd416.web.app> and jobs are hardcoded to update a sample playlist <https://open.spotify.com/playlist/7Li5tNS13DgGF0FAgwjATf?si=d7a5093ab6a94da5>
I run it with these launch settings in vscode:

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

## Getting Started
