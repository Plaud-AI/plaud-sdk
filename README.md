# Welcome to PLAUD SDK

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)](https://github.com/Plaud-AI/plaud-sdk)
[![API](https://img.shields.io/badge/API-21%2B-brightgreen.svg?style=flat)](https://android-arsenal.com/api?level=21)
[![iOS](https://img.shields.io/badge/iOS-13.0%2B-brightgreen.svg?style=flat)](https://developer.apple.com/ios/)


This is the official hub for the PLAUD SDK. Use this SDK to integrate PLAUD's AI-powered hardware and software services into your applications or products, including but not limited to:

- 🔌&nbsp;Connecting to PLAUD devices
- 📊&nbsp;Monitoring device settings and status
- 🎮&nbsp;Controlling device operations such as starting, stopping, and more
- ⚙️&nbsp;Modifying device configurations to meet your requirements
- 📥&nbsp;Retrieving recordings produced by devices after obtaining authorization
- 🔄&nbsp;Integrating with your workflow via PLAUD Cloud or self-hosted services

## System Architecture

- **PLAUD SDK**: A software development kit enabling third-party applications to integrate with PLAUD's AI-powered hardware and software services
- **Client Host App**: The client's app that integrates the PLAUD SDK to access PLAUD's hardware and software services
- **PLAUD Template App**: A pre-built template app provided by PLAUD, enabling enterprises to rapidly customize and deploy private-branded solutions via APIs and Apps

<p align="center">
  <img  src="/assets/outline-light.png">
</p>

## Supported Platforms

PLAUD SDK is designed to work across all platforms. ​Support for Android and iOS is now available, and additional platforms are currently under development.

| Platform | Status | Min Version |
|----------|--------|-------------|
| Android  | ✅ Available | API 21+ |
| iOS      | ✅ Available | iOS 13.0+ |
| Web      | 🚧 In Development | - |
| macOS    | 🚧 In Development | - |
| Windows  | 🚧 In Development | - |

## Core Features

-  📡&nbsp;Scan and discover nearby devices
-  🔗&nbsp;Bind and connect to target devices
-  📊&nbsp;Retrieve device status
-  💾&nbsp;Check device storage capacity
-  🔋&nbsp;Monitor device power status
-  ⏺️&nbsp;Start/pause/resume/stop recordings
-  📋&nbsp;Get recording item lists
-  ⬇️&nbsp;Start/cancel recording downloads
-  🗑️&nbsp;Delete specific recordings
-  🧹&nbsp;Clear all recording items
-  📶&nbsp;Configure device Wi-Fi Sync:
    - ➕&nbsp;Add Wi-Fi networks
    - ➖&nbsp;Remove Wi-Fi networks
    - 🔧&nbsp;Update Wi-Fi configurations
    - 📝&nbsp;Retrieve saved Wi-Fi lists
    - ☁️&nbsp;Configure upload destinations
-  🤖&nbsp;Cloud Processing Service:
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
