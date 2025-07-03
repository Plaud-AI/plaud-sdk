#ifndef LocalizationMacros_h
#define LocalizationMacros_h

#define LocalizedString(key) [LocalizationHelper localizedString:key]
#define LocalizedStringWithFormat(key, ...) [LocalizationHelper localizedStringWithFormat:key, ##__VA_ARGS__]

#endif /* LocalizationMacros_h */ 