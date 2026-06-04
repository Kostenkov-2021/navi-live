package com.navilive.android.i18n

import java.util.Locale

object AppLanguages {
    const val SystemLanguageTag = ""

    val supportedLanguageTags = listOf(
        "en",
        "sq",
        "ar",
        "be",
        "bn",
        "bg",
        "bs",
        "ca",
        "ckb",
        "cs",
        "cy",
        "da",
        "de",
        "el",
        "es",
        "et",
        "eu",
        "fa",
        "fi",
        "fo",
        "fr",
        "ga",
        "gl",
        "hi",
        "hr",
        "hu",
        "hy",
        "is",
        "id",
        "it",
        "ja",
        "ka",
        "ko",
        "lb",
        "lt",
        "lv",
        "mk",
        "mt",
        "nb",
        "nl",
        "pl",
        "pt",
        "ro",
        "ru",
        "sk",
        "sl",
        "sr",
        "sv",
        "tr",
        "uk",
        "vi",
        "zh-Hans",
    )

    fun normalize(languageTag: String?): String {
        val trimmed = languageTag.orEmpty().trim()
        if (trimmed.isEmpty()) return SystemLanguageTag
        return supportedLanguageTags.firstOrNull { it.equals(trimmed, ignoreCase = true) } ?: SystemLanguageTag
    }

    fun displayName(languageTag: String, displayLocale: Locale = Locale.getDefault()): String {
        val locale = Locale.forLanguageTag(languageTag)
        val fallback = languageTag
        val displayName = locale.getDisplayName(displayLocale).ifBlank { fallback }
        return displayName.replaceFirstChar { char ->
            if (char.isLowerCase()) {
                char.titlecase(displayLocale)
            } else {
                char.toString()
            }
        }
    }
}
