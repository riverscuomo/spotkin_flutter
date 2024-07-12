# spotkin_flutter

A Flutter web front-end for Spotkin. <https://github.com/riverscuomo/spotkin>
It should replace the spreadsheet method <https://docs.google.com/spreadsheets/d/1z5MejG6EKg8rf8vYKeFhw9XT_3PxkDFOrPSEKT_jYqI/edit?gid=1936655481#gid=1936655481>

Currently deployed at <https://spotkin-fd416.web.app> though the Spotify login is not working (due to the redirect URI not being set up correctly?).
Running locally works, however.
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
