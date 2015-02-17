# InstagramAssetsPicker

![Version](https://img.shields.io/cocoapods/v/InstagramAssetsPicker.svg)
![License](https://img.shields.io/cocoapods/l/InstagramAssetsPicker.svg)
![Platform](https://img.shields.io/cocoapods/p/InstagramAssetsPicker.svg)

Present Image Picker like Instagram, crop photo and video with GPUImage.

![GIF](https://github.com/JGINGIT/InstagramAssetsPicker/blob/master/screen.gif)


## Installation

With [CocoaPods](http://cocoapods.org/), add this line to your Podfile.

    pod 'InstagramAssetsPicker'

## Usage

``` objective-c
#import "IGAssetsPicker.h"
IGAssetsPickerViewController *picker = [[IGAssetsPickerViewController alloc] init];
picker.delegate = self;
[self presentViewController:picker animated:YES completion:NULL];
```
if you want crop the asset later,you should comment the `IG_CROP_IMMEDIATELY` define in `IGAssetsPicker.h`

## Author

[JG](https://github.com/JGINGIT)

## Reference
[InstagramPhotoPicker](https://github.com/wenzhaot/InstagramPhotoPicker)

[UzysAssetsPickerController](https://github.com/uzysjung/UzysAssetsPickerController)


## License

InstagramAssetsPicker is available under the MIT license. See the LICENSE file for more info.

