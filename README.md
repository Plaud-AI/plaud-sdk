# Welcome to PLAUD SDK

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)](https://github.com/Plaud-AI/plaud-sdk)
[![API](https://img.shields.io/badge/API-21%2B-brightgreen.svg?style=flat)](https://android-arsenal.com/api?level=21)
[![iOS](https://img.shields.io/badge/iOS-13.0%2B-brightgreen.svg?style=flat)](https://developer.apple.com/ios/)


This is the official hub for the PLAUD SDK. 

## Table of Contents

- [Introduction](#-Introduction)
- [System Architecture](#-system-architecture)
- [Supported Platforms](#-supported-platforms)
- [Core Features](#-core-features)
- [Integration](#-Integration)
- [Examples](#-examples)
- [FAQ](#-FAQ)
- [Support](#-support)
- [License](#-license)

## Introduction
You can use this SDK to integrate PLAUD's AI-powered hardware and software services into your applications or products, including but not limited to:

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
| iOS      | ✅ Available | iOS 13.0+ |
| Android  | ✅ Available | API 21+ |
| Web      | 🚧 In Development | - |
| macOS    | 🚧 In Development | - |
| Windows  | 🚧 In Development | - |

## Core Features

### Device Management
- 📡 Scan and discover nearby devices
- 🔗 Bind and connect to target devices
- 📊 Retrieve real-time device status
- 💾 Check device storage capacity
- 🔋 Monitor battery level and charging status

### Recording Operations
- ⏺️ Start/pause/resume/stop recordings
- 📋 Get recording item lists with metadata
- ⬇️ Download recordings with progress tracking
- 🗑️ Delete specific recordings
- 🧹 Clear all recording items

### Network Configuration
- 📶 Configure device Wi-Fi settings:
  - ➕ Add Wi-Fi networks
  - ➖ Remove Wi-Fi networks
  - 🔧 Update Wi-Fi configurations
  - 📝 Retrieve saved Wi-Fi lists
  - ☁️ Configure upload destinations

### Cloud Services
- 🤖 AI-powered processing:
  - 🎯 Automatic transcription
  - 📝 Smart summarization
  - ⚙️ Customizable templates
  - 🌐 Multi-language support

## Integration

See the [SDK Integration Guide](https://github.com/Plaud-AI/plaud-sdk/blob/main/docs/sdk-integration-guide.md)

## Examples

Check out our example applications:

- [iOS Demo App](https://github.com/Plaud-AI/plaud-sdk/tree/main/examples/ios-demo)
- [Android Demo App](https://github.com/Plaud-AI/plaud-sdk/tree/main/examples/android-demo)

## FAQ

### How to get a PLAUD device?
PLAUD devices are available for purchase through our [official website](https://www.plaud.ai/) or other authorized online retailers.

### How to test PLAUD devices with my system?
An appKey is required for secure device connection and access. If you don't have one, contact support@plaud.ai to request a test key, including your company name and intended use case. Then begin testing by following these steps:  
1. Build and run the Demo app in the `examples` folder.  
2. Enter your appKey (generated above).  
3. Scan for available devices and connect to yours.

### Can I test without a physical device?
NO，​a physical devices is currently a necessity.

### What audio formats are supported?
The SDK supports MP3, WAV formats currently.

### Is offline mode supported?
Yes, basic device operations work offline. Cloud features require an internet connection.


## Try Playground App
Coming soon

## Support

- 📧 Email: support@plaud.ai
- 📖 Documentation: [plaud.mintlify.app](https://plaud.mintlify.app)
- 🐛 Issues: [GitHub Issues](https://github.com/Plaud-AI/plaud-sdk/issues)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ by the PLAUD Team
</p> 
