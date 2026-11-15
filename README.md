# Phonetic

[![Build iOS](https://github.com/iAugux/Phonetic/actions/workflows/build_ios.yml/badge.svg?branch=master)](https://github.com/iAugux/Phonetic/actions/workflows/build_ios.yml)
![Language](https://img.shields.io/badge/language-Swift%206-orange.svg)
[![License](https://img.shields.io/badge/License-CC%20Attribution--NonCommercial-E5EC00.svg)](https://creativecommons.org/licenses/by-nc/4.0/)
[![Homepage](https://img.shields.io/badge/Homepage-iAugus-9021C5.svg)](https://iaugus.com)
[![𝕏](https://img.shields.io/badge/%F0%9D%95%8F-%40iAugux-000000.svg)](https://x.com/iaugux)

Phonetic adds pinyin to Chinese contact names for alphabetical sorting and easier search, even when your iPhone uses a non-Chinese system language. It supports both Simplified and Traditional Chinese names and is built with SwiftUI.

## App Store

<div>
<a href="https://itunes.apple.com/app/id1078961574">
  <img src="https://raw.githubusercontent.com/iAugux/ProjectScreenshots/master/Phonetic/AppStore.png" alt="Download Phonetic on the App Store" width="110">
</a>
</div>

## Features

- **Pinyin for contact names:** Add pronunciation to Chinese first and last names, with options for tone marks, syllable spacing, and capitalization.
- **Polyphonic surname corrections:** Choose pronunciation corrections for supported characters in family names. These corrections do not apply to given names.
- **Search initials:** Store initials such as `LMQ` for `林沐晴` in Nickname or another supported contact field.
- **Whitelist:** Leave selected contacts unchanged during batch pinyin generation and field clearing.
- **Clear contact fields:** Review a confirmation before clearing Chinese phonetic names and the optional fields selected in settings.
- **Version History:** Review recorded changes and selectively restore earlier field values while those versions remain available on the device.
- **Progress and cancellation:** Follow processing progress and stop further changes when needed. On iOS 26+, Phonetic can also show system background progress.

Version History records fields changed by Phonetic. Older history is removed automatically to stay within its storage limit. See [Contact version history](docs/contact-version-history.md) for recovery behavior and limitations.

## Requirements

- iOS 17.0+
- Swift 6
- Xcode 27+

## Development

Open `Phonetic.xcodeproj`, select the `Phonetic` scheme, and run on an iOS simulator or a device configured for signing. The shared scheme also includes the `PhoneticTests` target.

Contact-processing tests use fake contact sources and temporary history storage. See [Test coverage](docs/test-coverage.md) for the recorded coverage snapshot, remaining gaps, and commands for running tests with coverage.

Bug reports and contributions are welcome. For pronunciation corrections, include the character or surname and the expected pinyin.

## Previews from an older version

> **All screenshots, GIFs, and videos below show an older version of Phonetic.** The current app has a redesigned SwiftUI interface; the layouts and interaction instructions in these previews are outdated.

### Videos

[Watch on YouTube](https://youtu.be/337O4xr7Mj4) or [Bilibili](https://www.bilibili.com/video/av3775904).

<div>
<a href="https://youtu.be/337O4xr7Mj4">
  <img src="https://raw.githubusercontent.com/iAugux/ProjectScreenshots/master/Phonetic/0.png" alt="Video preview of an older version of Phonetic" width="272" height="480">
</a>
</div>

### Screenshots and animations

<div>
<img src="https://raw.githubusercontent.com/iAugux/ProjectScreenshots/master/Phonetic/nickname.gif" alt="Search initials in an older version" width="272" height="480">
</div>

<div>
<img src="https://raw.githubusercontent.com/iAugux/ProjectScreenshots/master/Phonetic/execute.gif" alt="Adding pinyin in an older version" width="272" height="480">
</div>

<div>
<img src="https://raw.githubusercontent.com/iAugux/ProjectScreenshots/master/Phonetic/revoke.gif" alt="Clearing fields in an older version" width="272" height="480">
</div>

<div>
<img src="https://raw.githubusercontent.com/iAugux/ProjectScreenshots/master/Phonetic/1.png" alt="Older Phonetic interface, screen 1" width="272" height="480">
</div>

<div>
<img src="https://raw.githubusercontent.com/iAugux/ProjectScreenshots/master/Phonetic/2.png" alt="Older Phonetic interface, screen 2" width="272" height="1045">
</div>

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=iAugux/Phonetic&type=Date)](https://star-history.com/#iAugux/Phonetic&Date)

## Thanks to

[PhoneticContacts](https://github.com/lexrus/PhoneticContacts) by Lexrus inspired this project.

## License

Phonetic is available under the [Creative Commons Attribution-NonCommercial 4.0 license](https://creativecommons.org/licenses/by-nc/4.0/).

Please do not repackage this project and submit it to the App Store.

Copyright © 2019 iAugus
