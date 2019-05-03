source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!
inhibit_all_warnings!

def shared
    pod 'SnapKit'
end

target 'Phonetic' do
    shared
    pod 'Device'
    pod 'Reveal-SDK', '20' , :configurations => ['Debug']
end

target 'Components' do
    shared
end
