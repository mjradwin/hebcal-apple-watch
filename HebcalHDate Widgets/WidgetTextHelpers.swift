//
//  WidgetTextHelpers.swift
//  HebcalHDate Widgets
//
//  Abbreviation tables and small string helpers used when rendering
//  complications. The pixel budgets were tuned for each watch face
//  family on the legacy ClockKit complications and carried over here.
//

import Foundation

// Two-line stack abbreviations (graphic circular, modular small, etc.).
// nil means "the full name fits, no abbreviation needed".
let monthAbbrev: [String: String?] = [
    "Adar": nil,
    "Adar I": "Adar1",
    "Adar II": "Adar2",
    "Av": nil,
    "Cheshvan": "Chesh",
    "Elul": nil,
    "Iyyar": "Iyar",
    "Kislev": nil,
    "Nisan": nil,
    "Sh'vat": "Shvat",
    "Sivan": nil,
    "Tamuz": nil,
    "Tevet": nil,
    "Tishrei": "Tishr",
]

// Tighter abbreviations used by the extra-large equivalent
// (now: same fallback when even the short form is too wide).
let monthAbbrevTiny: [String: String] = [
    "Adar": "Adar",
    "Adar I": "Ad 1",
    "Adar II": "Ad 2",
    "Av": "Av",
    "Cheshvan": "Chsh",
    "Elul": "Elul",
    "Iyyar": "Iyar",
    "Kislev": "Kis",
    "Nisan": "Nis",
    "Sh'vat": "Shvt",
    "Sivan": "Siv",
    "Tamuz": "Tam",
    "Tevet": "Tev",
    "Tishrei": "Tish",
]

let parshaHyphenate: [String: [String]?] = [
    "Achrei Mot": nil,
    "Balak": nil,
    "Bamidbar": ["Bamid", "bar"],
    "Bechukotai": ["Bechu", "kotai"],
    "Beha'alotcha": ["Behaa", "lotcha"],
    "Behar": nil,
    "Bereshit": ["Bere-", "sheet"],
    "Beshalach": ["Besha", "lach"],
    "Bo": nil,
    "Chayei Sara": nil,
    "Chukat": nil,
    "Devarim": ["Deva-", "rim"],
    "Eikev": nil,
    "Emor": nil,
    "Ha'Azinu": ["Ha-", "Azinu"],
    "Kedoshim": ["Kedo-", "shim"],
    "Ki Tavo": nil,
    "Ki Teitzei": nil,
    "Ki Tisa": nil,
    "Korach": nil,
    "Lech-Lecha": nil,
    "Masei": nil,
    "Matot": nil,
    "Metzora": ["Metz-", "ora"],
    "Miketz": ["Mi-", "ketz"],
    "Mishpatim": ["Mish-", "patim"],
    "Nasso": nil,
    "Nitzavim": ["Nitz-", "avim"],
    "Noach": nil,
    "Pekudei": ["Peku-", "dei"],
    "Pinchas": ["Pin-", "chas"],
    "Re'eh": nil,
    "Sh'lach": ["Sh'", "lach"],
    "Shemot": nil,
    "Shmini": nil,
    "Shoftim": ["Shof-", "tim"],
    "Tazria": nil,
    "Terumah": ["Teru-", "mah"],
    "Tetzaveh": ["Tet-", "zaveh"],
    "Toldot": ["Tol-", "dot"],
    "Tzav": nil,
    "Vaera": nil,
    "Vaetchanan": ["Vaet-", "chanan"],
    "Vayakhel": ["Vaya-", "khel"],
    "Vayechi": nil,
    "Vayeilech": ["Vayei", "lech"],
    "Vayera": nil,
    "Vayeshev": ["Vaye-", "shev"],
    "Vayetzei": ["Vaye-", "tzei"],
    "Vayigash": ["Vayi-", "gash"],
    "Vayikra": ["Vayi-", "kra"],
    "Vayishlach": ["Vayish", "lach"],
    "Yitro": nil,
    // ashk
    "Bechukosai": ["Bechu", "kosai"],
    "Beha'aloscha": ["Behaa", "loscha"],
    "Bereshis": ["Bere-", "shis"],
    "Toldos": ["Tol-", "dos"],
    "Vaeschanan": ["Vaes-", "chanan"],
]

private let space: Character = " "
private let dash: Character = "-"
private let maqaf: Character = "־"

func splitFirstChar(str: String, char: Character) -> [String] {
    if let idx = str.firstIndex(of: char) {
        let firstWord = String(str[..<idx])
        let afterIdx = str.index(idx, offsetBy: 1)
        let remainder = String(str[afterIdx...])
        return [firstWord, remainder]
    } else {
        return [str]
    }
}

// Split a parsha string into one or two lines for stacked layouts.
// Returns either [name] or [first, second].
func splitParsha(parsha: String) -> [String] {
    for delim in [dash, maqaf, space] {
        if parsha.firstIndex(of: delim) != nil {
            return splitFirstChar(str: parsha, char: delim)
        }
    }
    if let hyphenated = parshaHyphenate[parsha] {
        if let pair = hyphenated {
            return [pair[0], pair[1]]
        }
        return [parsha]
    }
    return [parsha]
}
