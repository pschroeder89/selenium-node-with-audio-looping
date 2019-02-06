Selenium Chrome Node Debug Image with Audio Looping Support
================

This is a standard Selenium Chrome Node Debug image from SeleniumHQ, with some added audio driver magic to help test
speech recognition within client applications.

#### How It Works
Using PulseAudio, we create a virtual speaker, and a virtual microphone that accepts the speaker output as its input.
The virtual speaker "plays" the audio into the virtual microphone, as if a user is speaking the content of the audio file.

In addition to creating an output-to-input loop, we serve wav files from this repository's `media` folder using Python's
SimpleHTTPServer. In the container, the files can be accessed at `http://localhost:8000/`. Alternatively, if you want to
play audio files hosted on an external server, you can simply pass the URL into your tests instead of `localhost:8000`.

##### Why do we need to run a server on localhost to serve these audio files? Can't we just play the audio files straight from the directory?
Good questions! Chrome blocks access to local files by default due to security concerns. There is a flag you can set at launch,
`--allow-file-access`, that would allow us to directly use the local files. In fear of Google removing that flag
in the future, we set up a local server on port 8000 to prevent future work.

#### Creating Audio Files
Any audio file that Chrome supports should work fine. I personally use Audacity and save recordings as 16Mhz WAV files. 
Store your recorded files in the `media` folder of this repo, or on some external server.

#### To add to your Selenium project
In your Selenium configuration's Chrome desiredCapabilities, make sure you are sending an argument of `--use-fake-ui-for-media-stream`
to auto-allow the use of the browser's microphone. Do not send `--use-fake-device-for-media-stream`, as this will override
PulseAudio's audio setup and use Chrome's built-in fake device.

``` desiredCapabilities: {
        browserName: "chrome",
        'goog:chromeOptions': {
          args: [
            "use-fake-ui-for-media-stream",
            "window-size=1280,950"
            ]
        },
```

#### Calling the audio files from within your tests
We use Selenium's built-in `execute async script` command within our tests to play the audio. 
The following function / callback accepts the filename of a WAV file within this Docker image's `/media`
folder, and plays it via an injection of JavaScript to the browser's console. This creates an audio player object and play's the associated
file.

Nightwatch.js Custom Command example:

```javascript
exports.command = function(wavFilename, server = 'http://localhost:8000/') {
  this.executeAsync(
    (url, done) => { // Pass in the url, which is defined by the [server + wavFileName] array below, and a done callback
      const audio = new Audio(); // Create an audio object
      audio.src = url; // Add the URL of the audio file to the audio object's src
      audio.addEventListener('ended', () => {
        // Call executeAsync's done() callback when the audio's "ended" event is hit, so the command is considered "done" when the audio is done playing. 
        // This is why we use executeAsync and not execute! With execute, the audio would get played and the test would move on without waiting for completion.
        done();
      });
      audio.play(); // Play that funky music
    },
    [server + wavFilename], // This is the url parameter used by executeAsync above
    () => {
      console.log(' ♦ Played ' + wavFilename + ' into microphone.'); // Callback 
    }
  );
};
```
Nightwatch Usage:
```
   browser.speakIntoMicrophone('wavFile.wav');
```
to play audio from `http://localhost:8000` (located in the opt/media folder of the Docker container).

Or, you can reach an external server via:
```
   browser.speakIntoMicrophone('wavFile.wav', 'https://somewhere.com/media/');
```

Ruby / Rspec method example:
```ruby
def speak_into_mic(wav_file_name, server = 'http://localhost:8000/')
    @driver.execute_async_script(
      'const done = arguments[arguments.length - 1]; function speakIntoMic(url) { const audio = new Audio(); audio.src = url; audio.addEventListener("ended", function () {done()}); audio.play();}; speakIntoMic(arguments[0]);',
      server + wav_file_name, nil
    )
  end
```

#### Building this image
`docker build -t selenium-node-with-audio-looping-1 .`

#### Running the image locally
Create a docker network called grid:
`docker network create grid`

Get a Selenium Hub booted up:
`docker run -d -p 4444:4444 --name selenium-hub --net grid selenium/hub:latest`

Start up this image and attach it to the Hub:
`docker run -d --net grid -e HUB_HOST=selenium-hub -v /dev/shm:/dev/shm -p 5900:5900 selenium-node-with-audio-looping-1`

By forwarding port 5900, you can use VNC to remote into the node container at `localhost:5900` and watch / debug your tests.

To kill all running containers:
`docker rm -f $(docker ps -aq)`

#### Not using Docker Selenium / Linux for your Selenium Grid?
If you're using Mac hardware or Mac virtual machines, check out [Soundflower](https://github.com/mattingalls/Soundflower/releases/tag/2.0b2) to route audio output to input.

I dont use Windows, but I've read that [VoiceMeeter](https://www.vb-audio.com/Voicemeeter/index.htm) is comparable to Soundflower / PulseAudio.

Once you have your audio loop set up, you can [call your audio files from your tests](#calling-the-audio-files-from-within-your-tests).