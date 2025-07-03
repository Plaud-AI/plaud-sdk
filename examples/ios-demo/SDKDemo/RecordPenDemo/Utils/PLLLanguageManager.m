- (void)setupDefaultLanguage {
    NSNumber *savedLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:kLanguageKey];
    if (!savedLanguage) {
        // Set English as default language
        self.currentLanguage = PLLanguageTypeEnglish;
        [self saveLanguageSelection];
    } else {
        self.currentLanguage = (PLLanguageType)[savedLanguage integerValue];
    }
    
    // Set the app's language
    [self applyCurrentLanguage];
} 