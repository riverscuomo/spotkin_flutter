# spotkin_flutter [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://makeapullrequest.com)

(in development)

A Flutter web front-end for [Spotkin](<https://github.com/riverscuomo/spotkin>) currently deployed at <https://spotkin.web.app>

 Right now, you can:

- log into Spotify through our website.
- set a target playlist. Choose one of your own or have the app create one for you. 
- set any number of public playlists to source from, and the quantity of tracks to pull.
- exclude any artists, songs, or genres by going to the Settings page.
- click a button to update your playlist with the tracks from the source playlists.
- the server will autoupdate your Spotify playlist every day at 5 am UTC.


## Getting Started

To run locally,  I use these launch settings in vscode:

```
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Spotkin Flutter Web Client",
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

## DEPLOYMENT

Any push to the main branch will trigger a GitHub Actions workflow that will build the app and deploy it to Firebase Hosting.
