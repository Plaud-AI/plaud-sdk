# Welcome to PLAUD SDK

This is the official hub for the PLAUD SDK. Use this SDK to integrate PLAUD's AI-powered hardware and software services into your applications or products, including but not limited to:

- Connecting to PLAUD devices
- Monitoring device settings and status
- Controlling device operations such as starting, stopping, and more
- Modifying device configurations to meet your requirements
- Retrieving recordings produced by devices after obtaining authorization
- Integrating with your workflow via PLAUD Cloud or self-hosted services

## System Architecture   

*   PLAUD SDK: A software development kit enabling third-party applications to integrate with PLAUD's Al-powered hardware and software services
*   Client Host App: The client's app that integrates the PLAUD SDK to access PLAUD's hardware and software services
*   PLAUD Template App: A pre-built template app provided by PLAUD, enabling enterprises to rapidly customize and deploy private-branded solutions via APIs and Apps

<p align="center">
  <img  src="/assets/outline-light.png">
</p>

## Supported Platforms

PLAUD SDK is designed to work across all platforms. ​Support for Android and iOS is now available, and additional platforms are currently under development.

- [x] Android
- [x] iOS
- [ ] Web
- [ ] macOS
- [ ] Windows

## Core Features

- [x] 📡&nbsp;Scan and discover nearby devices
- [x] 🔗&nbsp;Bind and connect to target devices
- [x] 📊&nbsp;Retrieve device status
- [x] 💾&nbsp;Check device storage capacity
- [x] 🔋&nbsp;Monitor device power status
- [x] ⏺️&nbsp;Start/pause/resume/stop recordings
- [x] 📋&nbsp;Get recording item lists
- [x] ⬇️&nbsp;Start/cancel recording downloads
- [x] 🗑️&nbsp;Delete specific recordings
- [x] 🧹&nbsp;Clear all recording items
- [x] 📶&nbsp;Configure device Wi-Fi Sync:
    - ➕&nbsp;Add Wi-Fi networks
    - ➖&nbsp;Remove Wi-Fi networks
    - 🔧&nbsp;Update Wi-Fi configurations
    - 📝&nbsp;Retrieve saved Wi-Fi lists
    - ☁️&nbsp;Configure upload destinations
- [x] 🤖&nbsp;Cloud Processing Service:
    - 🎯&nbsp;AI-powered transcription & summarization
    - ⚙️&nbsp;Customizable processing preferences and templates

## Integrate the SDK

See the [SDK Integration Guide](https://github.com/Plaud-AI/plaud-sdk/blob/main/docs/sdk-integration-guide.md)


## FAQ

### How to get a PLAUD device?
PLAUD devices are available for purchase through our [official website](https://www.plaud.ai/) or other authorized online retailers.

### How to test PLAUD devices with my system?
An appKey is required for secure device connection and access. If you don't have one, contact support@plaud.ai to request a test key. Then you can begin testing:
1. Build and run the Demo app in the `examples` folder
2. Enter your above appKey 
3. Scan for and connect to your device

## Try Playground App
Coming soon
