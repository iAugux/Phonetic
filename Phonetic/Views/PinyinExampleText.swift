import SwiftUI

struct PinyinExampleText: View {
    @AppStorage(kUseTones) private var useTones = kUseTonesDefaultBool
    @AppStorage(kUpcasePinyin) private var upcasePinyin = kUpcasePinyinDefaultBool
    @AppStorage(kAlwaysSeparatePinyin) private var separatePinyin = kAlwaysSeparatePinyinDefaultBool

    var body: some View {
        Text(verbatim: Phonetic.exampleName(useTones: useTones, separated: separatePinyin, upcase: upcasePinyin))
    }
}
