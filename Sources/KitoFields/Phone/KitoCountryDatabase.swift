//
//  KitoCountryDatabase.swift
//  KitoFields
//
//  Created by Wycliff Njenga on 16/09/2026.
//  Copyright © 2026 Wycliff Njenga. All rights reserved.
//

import Foundation

/// Built-in metadata for every ITU calling region.
public enum KitoCountryDatabase {

    /// All regions sorted by English name.
    public static let all: [KitoCountry] = countries.sorted { $0.englishName < $1.englishName }

    private static let byISO: [String: KitoCountry] = Dictionary(uniqueKeysWithValues: countries.map { ($0.isoCode, $0) })

    private static let byDialCode: [String: [KitoCountry]] = {
        var map: [String: [KitoCountry]] = [:]
        for c in countries { map[c.dialCode, default: []].append(c) }
        return map
    }()

    public static func country(isoCode: String) -> KitoCountry? {
        byISO[isoCode.uppercased()]
    }

    /// Every region using a dial code, main region first.
    public static func countries(dialCode: String) -> [KitoCountry] {
        (byDialCode[dialCode] ?? []).sorted { $0.isMainCountryForDialCode && !$1.isMainCountryForDialCode }
    }

    public static var dialCodes: [String] { Array(byDialCode.keys) }

    /// The region for the device's locale, defaulting to the United States.
    public static var current: KitoCountry {
        let code: String?
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *) {
            code = Locale.autoupdatingCurrent.region?.identifier
        } else {
            code = Locale.autoupdatingCurrent.regionCode
        }
        return code.flatMap(country(isoCode:)) ?? byISO["US"]!
    }

    /// Splits international digits (no "+") into (country, national digits) by matching the longest
    /// dial code, then disambiguating shared codes via leading digits.
    public static func match(internationalDigits digits: String) -> (country: KitoCountry, nationalNumber: String)? {
        for length in stride(from: min(3, digits.count), through: 1, by: -1) {
            let code = String(digits.prefix(length))
            guard let candidates = byDialCode[code], !candidates.isEmpty else { continue }
            let national = String(digits.dropFirst(length))
            let specific = candidates.first { country in
                !country.isMainCountryForDialCode && country.leadingDigits.contains { national.hasPrefix($0) }
            }
            let country = specific ?? candidates.first { $0.isMainCountryForDialCode } ?? candidates[0]
            return (country, national)
        }
        return nil
    }

    // MARK: - Data

    private static func c(_ iso: String, _ dial: String, _ name: String, _ formats: [String] = [], lengths: ClosedRange<Int>? = nil, trunk: String? = nil, example: String? = nil, leading: [String] = [], main: Bool = true) -> KitoCountry {
        KitoCountry(isoCode: iso, dialCode: dial, englishName: name, formats: formats, nationalNumberLengths: lengths, trunkPrefix: trunk, exampleNumber: example, leadingDigits: leading, isMainCountryForDialCode: main)
    }

    /// North American Numbering Plan member (+1) identified by area codes.
    private static func nanp(_ iso: String, _ name: String, areaCodes: [String]) -> KitoCountry {
        c(iso, "1", name, ["(###) ###-####"], example: (areaCodes.first ?? "201") + "5550123", leading: areaCodes, main: false)
    }

    private static let countries: [KitoCountry] = [
        // MARK: +1 NANP
        c("US", "1", "United States", ["(###) ###-####"], example: "2015550123"),
        nanp("CA", "Canada", areaCodes: ["204","226","236","249","250","263","289","306","343","354","365","367","368","382","387","403","416","418","431","437","438","450","468","474","506","514","519","548","579","581","584","587","604","613","639","647","672","683","705","709","742","753","778","780","782","807","819","825","867","873","879","902","905"]),
        nanp("AG", "Antigua and Barbuda", areaCodes: ["268"]),
        nanp("AI", "Anguilla", areaCodes: ["264"]),
        nanp("AS", "American Samoa", areaCodes: ["684"]),
        nanp("BB", "Barbados", areaCodes: ["246"]),
        nanp("BM", "Bermuda", areaCodes: ["441"]),
        nanp("BS", "Bahamas", areaCodes: ["242"]),
        nanp("DM", "Dominica", areaCodes: ["767"]),
        nanp("DO", "Dominican Republic", areaCodes: ["809","829","849"]),
        nanp("GD", "Grenada", areaCodes: ["473"]),
        nanp("GU", "Guam", areaCodes: ["671"]),
        nanp("JM", "Jamaica", areaCodes: ["876","658"]),
        nanp("KN", "Saint Kitts and Nevis", areaCodes: ["869"]),
        nanp("KY", "Cayman Islands", areaCodes: ["345"]),
        nanp("LC", "Saint Lucia", areaCodes: ["758"]),
        nanp("MP", "Northern Mariana Islands", areaCodes: ["670"]),
        nanp("MS", "Montserrat", areaCodes: ["664"]),
        nanp("PR", "Puerto Rico", areaCodes: ["787","939"]),
        nanp("SX", "Sint Maarten", areaCodes: ["721"]),
        nanp("TC", "Turks and Caicos Islands", areaCodes: ["649"]),
        nanp("TT", "Trinidad and Tobago", areaCodes: ["868"]),
        nanp("VC", "Saint Vincent and the Grenadines", areaCodes: ["784"]),
        nanp("VG", "British Virgin Islands", areaCodes: ["284"]),
        nanp("VI", "U.S. Virgin Islands", areaCodes: ["340"]),

        // MARK: +7
        c("RU", "7", "Russia", ["(###) ###-##-##"], trunk: "8", example: "9123456789"),
        c("KZ", "7", "Kazakhstan", ["(###) ###-##-##"], trunk: "8", example: "7710009998", leading: ["6", "7"], main: false),

        // MARK: Europe
        c("AD", "376", "Andorra", ["### ###"], lengths: 6...9, example: "312345"),
        c("AL", "355", "Albania", ["## ### ####"], lengths: 9...9, trunk: "0", example: "662123456"),
        c("AM", "374", "Armenia", ["## ######"], lengths: 8...8, trunk: "0", example: "77123456"),
        c("AT", "43", "Austria", ["### ######", "### #######"], lengths: 4...13, trunk: "0", example: "664123456"),
        c("AX", "358", "Åland Islands", ["## ### ####"], lengths: 5...12, trunk: "0", example: "181234567", leading: ["18"], main: false),
        c("AZ", "994", "Azerbaijan", ["## ### ## ##"], lengths: 9...9, trunk: "0", example: "401234567"),
        c("BA", "387", "Bosnia and Herzegovina", ["## ### ###"], lengths: 8...9, trunk: "0", example: "61123456"),
        c("BE", "32", "Belgium", ["### ## ## ##"], lengths: 8...9, trunk: "0", example: "470123456"),
        c("BG", "359", "Bulgaria", ["### ### ###"], lengths: 7...9, trunk: "0", example: "43012345"),
        c("BY", "375", "Belarus", ["## ###-##-##"], lengths: 9...9, trunk: "8", example: "294911911"),
        c("CH", "41", "Switzerland", ["## ### ## ##"], lengths: 9...9, trunk: "0", example: "781234567"),
        c("CY", "357", "Cyprus", ["## ######"], lengths: 8...8, example: "96123456"),
        c("CZ", "420", "Czech Republic", ["### ### ###"], lengths: 9...9, example: "601123456"),
        c("DE", "49", "Germany", ["### #######", "#### ########"], lengths: 5...13, trunk: "0", example: "15123456789"),
        c("DK", "45", "Denmark", ["## ## ## ##"], lengths: 8...8, example: "32123456"),
        c("EE", "372", "Estonia", ["#### ####"], lengths: 7...8, example: "51234567"),
        c("ES", "34", "Spain", ["### ## ## ##"], lengths: 9...9, example: "612345678"),
        c("FI", "358", "Finland", ["## ### ####"], lengths: 5...12, trunk: "0", example: "412345678"),
        c("FO", "298", "Faroe Islands", ["######"], lengths: 6...6, example: "211234"),
        c("FR", "33", "France", ["# ## ## ## ##"], lengths: 9...9, trunk: "0", example: "612345678"),
        c("GB", "44", "United Kingdom", ["#### ######"], lengths: 9...10, trunk: "0", example: "7400123456"),
        c("GG", "44", "Guernsey", ["#### ######"], lengths: 10...10, trunk: "0", example: "7781123456", leading: ["1481", "7781", "7839", "7911"], main: false),
        c("GI", "350", "Gibraltar", ["### #####"], lengths: 8...8, example: "57123456"),
        c("GR", "30", "Greece", ["### ### ####"], lengths: 10...10, example: "6912345678"),
        c("HR", "385", "Croatia", ["## ### ####"], lengths: 8...9, trunk: "0", example: "921234567"),
        c("HU", "36", "Hungary", ["## ### ####"], lengths: 8...9, trunk: "06", example: "201234567"),
        c("IE", "353", "Ireland", ["## ### ####"], lengths: 7...9, trunk: "0", example: "850123456"),
        c("IM", "44", "Isle of Man", ["#### ######"], lengths: 10...10, trunk: "0", example: "7924123456", leading: ["1624", "7524", "7624", "7924"], main: false),
        c("IS", "354", "Iceland", ["### ####"], lengths: 7...9, example: "6111234"),
        c("IT", "39", "Italy", ["### ### ####"], lengths: 6...11, example: "3123456789"),
        c("JE", "44", "Jersey", ["#### ######"], lengths: 10...10, trunk: "0", example: "7797712345", leading: ["1534", "7509", "7700", "7797", "7829", "7937"], main: false),
        c("LI", "423", "Liechtenstein", ["### ####"], lengths: 7...9, example: "6601234"),
        c("LT", "370", "Lithuania", ["### #####"], lengths: 8...8, trunk: "8", example: "61234567"),
        c("LU", "352", "Luxembourg", ["### ### ###"], lengths: 4...11, example: "628123456"),
        c("LV", "371", "Latvia", ["## ### ###"], lengths: 8...8, example: "21234567"),
        c("MC", "377", "Monaco", ["# ## ## ## ##"], lengths: 8...9, example: "612345678"),
        c("MD", "373", "Moldova", ["### ## ###"], lengths: 8...8, trunk: "0", example: "62112345"),
        c("ME", "382", "Montenegro", ["## ### ###"], lengths: 8...9, trunk: "0", example: "67622901"),
        c("MK", "389", "North Macedonia", ["## ### ###"], lengths: 8...8, trunk: "0", example: "72345678"),
        c("MT", "356", "Malta", ["#### ####"], lengths: 8...8, example: "96961234"),
        c("NL", "31", "Netherlands", ["# ########"], lengths: 9...9, trunk: "0", example: "612345678"),
        c("NO", "47", "Norway", ["### ## ###"], lengths: 8...8, example: "40612345"),
        c("PL", "48", "Poland", ["### ### ###"], lengths: 9...9, example: "512345678"),
        c("PT", "351", "Portugal", ["### ### ###"], lengths: 9...9, example: "912345678"),
        c("RO", "40", "Romania", ["### ### ###"], lengths: 9...9, trunk: "0", example: "712034567"),
        c("RS", "381", "Serbia", ["## #######"], lengths: 8...9, trunk: "0", example: "601234567"),
        c("SE", "46", "Sweden", ["##-### ## ##"], lengths: 7...10, trunk: "0", example: "701234567"),
        c("SI", "386", "Slovenia", ["## ### ###"], lengths: 8...8, trunk: "0", example: "31234567"),
        c("SJ", "47", "Svalbard and Jan Mayen", ["### ## ###"], lengths: 8...8, example: "79123456", leading: ["79"], main: false),
        c("SK", "421", "Slovakia", ["### ### ###"], lengths: 9...9, trunk: "0", example: "912123456"),
        c("SM", "378", "San Marino", ["## ## ## ##"], lengths: 6...10, example: "66661212"),
        c("UA", "380", "Ukraine", ["## ### ####"], lengths: 9...9, trunk: "0", example: "501234567"),
        c("VA", "39", "Vatican City", ["## ### #####"], lengths: 6...11, example: "0669812345", leading: ["06698"], main: false),
        c("XK", "383", "Kosovo", ["## ### ###"], lengths: 8...9, trunk: "0", example: "43201234"),

        // MARK: Africa
        c("AO", "244", "Angola", ["### ### ###"], lengths: 9...9, example: "923123456"),
        c("BF", "226", "Burkina Faso", ["## ## ## ##"], lengths: 8...8, example: "70123456"),
        c("BI", "257", "Burundi", ["## ## ## ##"], lengths: 8...8, example: "79561234"),
        c("BJ", "229", "Benin", ["## ## ## ##"], lengths: 8...10, example: "90011234"),
        c("BW", "267", "Botswana", ["## ### ###"], lengths: 7...8, example: "71123456"),
        c("CD", "243", "DR Congo", ["### ### ###"], lengths: 9...9, trunk: "0", example: "991234567"),
        c("CF", "236", "Central African Republic", ["## ## ## ##"], lengths: 8...8, example: "70012345"),
        c("CG", "242", "Congo", ["## ### ####"], lengths: 9...9, example: "061234567"),
        c("CI", "225", "Côte d'Ivoire", ["## ## ## ## ##"], lengths: 10...10, example: "0123456789"),
        c("CM", "237", "Cameroon", ["# ## ## ## ##"], lengths: 9...9, example: "671234567"),
        c("CV", "238", "Cape Verde", ["### ## ##"], lengths: 7...7, example: "9911234"),
        c("DJ", "253", "Djibouti", ["## ## ## ##"], lengths: 8...8, example: "77831001"),
        c("DZ", "213", "Algeria", ["### ## ## ##"], lengths: 8...9, trunk: "0", example: "551234567"),
        c("EG", "20", "Egypt", ["### ### ####"], lengths: 9...10, trunk: "0", example: "1001234567"),
        c("EH", "212", "Western Sahara", ["##-####-###"], lengths: 9...9, trunk: "0", example: "528812345", leading: ["5288", "5289"], main: false),
        c("ER", "291", "Eritrea", ["# ### ###"], lengths: 7...7, trunk: "0", example: "7123456"),
        c("ET", "251", "Ethiopia", ["## ### ####"], lengths: 9...9, trunk: "0", example: "911234567"),
        c("GA", "241", "Gabon", ["## ## ## ##"], lengths: 7...8, example: "06031234"),
        c("GH", "233", "Ghana", ["## ### ####"], lengths: 9...9, trunk: "0", example: "231234567"),
        c("GM", "220", "Gambia", ["### ####"], lengths: 7...7, example: "3012345"),
        c("GN", "224", "Guinea", ["### ## ## ##"], lengths: 8...9, example: "601123456"),
        c("GQ", "240", "Equatorial Guinea", ["### ### ###"], lengths: 9...9, example: "222123456"),
        c("GW", "245", "Guinea-Bissau", ["### ### ###"], lengths: 7...9, example: "955012345"),
        c("KE", "254", "Kenya", ["### ### ###"], lengths: 9...9, trunk: "0", example: "712345678"),
        c("KM", "269", "Comoros", ["### ## ##"], lengths: 7...7, example: "3212345"),
        c("LR", "231", "Liberia", ["## ### ####"], lengths: 7...9, trunk: "0", example: "770123456"),
        c("LS", "266", "Lesotho", ["#### ####"], lengths: 8...8, example: "50123456"),
        c("LY", "218", "Libya", ["##-#######"], lengths: 9...9, trunk: "0", example: "912345678"),
        c("MA", "212", "Morocco", ["##-####-###"], lengths: 9...9, trunk: "0", example: "650123456"),
        c("MG", "261", "Madagascar", ["## ## ### ##"], lengths: 9...9, trunk: "0", example: "321234567"),
        c("ML", "223", "Mali", ["## ## ## ##"], lengths: 8...8, example: "65012345"),
        c("MR", "222", "Mauritania", ["## ## ## ##"], lengths: 8...8, example: "22123456"),
        c("MU", "230", "Mauritius", ["#### ####"], lengths: 7...8, example: "52512345"),
        c("MW", "265", "Malawi", ["### ## ## ##"], lengths: 7...9, trunk: "0", example: "991234567"),
        c("MZ", "258", "Mozambique", ["## ### ####"], lengths: 8...9, example: "821234567"),
        c("NA", "264", "Namibia", ["## ### ####"], lengths: 8...9, trunk: "0", example: "811234567"),
        c("NE", "227", "Niger", ["## ## ## ##"], lengths: 8...8, example: "93123456"),
        c("NG", "234", "Nigeria", ["### ### ####"], lengths: 7...10, trunk: "0", example: "8021234567"),
        c("RE", "262", "Réunion", ["### ## ## ##"], lengths: 9...9, trunk: "0", example: "692123456"),
        c("RW", "250", "Rwanda", ["### ### ###"], lengths: 9...9, trunk: "0", example: "720123456"),
        c("SC", "248", "Seychelles", ["# ### ###"], lengths: 7...7, example: "2510123"),
        c("SD", "249", "Sudan", ["## ### ####"], lengths: 9...9, trunk: "0", example: "911231234"),
        c("SH", "290", "Saint Helena", ["#####"], lengths: 4...5, example: "51234"),
        c("SL", "232", "Sierra Leone", ["## ######"], lengths: 8...8, trunk: "0", example: "25123456"),
        c("SN", "221", "Senegal", ["## ### ## ##"], lengths: 9...9, example: "701234567"),
        c("SO", "252", "Somalia", ["## #######"], lengths: 7...9, trunk: "0", example: "71123456"),
        c("SS", "211", "South Sudan", ["## ### ####"], lengths: 9...9, trunk: "0", example: "977123456"),
        c("ST", "239", "São Tomé and Príncipe", ["### ####"], lengths: 7...7, example: "9812345"),
        c("SZ", "268", "Eswatini", ["#### ####"], lengths: 8...8, example: "76123456"),
        c("TD", "235", "Chad", ["## ## ## ##"], lengths: 8...8, example: "63012345"),
        c("TG", "228", "Togo", ["## ## ## ##"], lengths: 8...8, example: "90112345"),
        c("TN", "216", "Tunisia", ["## ### ###"], lengths: 8...8, example: "20123456"),
        c("TZ", "255", "Tanzania", ["### ### ###"], lengths: 9...9, trunk: "0", example: "621234567"),
        c("UG", "256", "Uganda", ["### ######"], lengths: 9...9, trunk: "0", example: "712345678"),
        c("YT", "262", "Mayotte", ["### ## ## ##"], lengths: 9...9, trunk: "0", example: "639012345", leading: ["269", "639"], main: false),
        c("ZA", "27", "South Africa", ["## ### ####"], lengths: 9...9, trunk: "0", example: "711234567"),
        c("ZM", "260", "Zambia", ["## #######"], lengths: 9...9, trunk: "0", example: "955123456"),
        c("ZW", "263", "Zimbabwe", ["## ### ####"], lengths: 9...9, trunk: "0", example: "712345678"),

        // MARK: Middle East
        c("AE", "971", "United Arab Emirates", ["## ### ####"], lengths: 9...9, trunk: "0", example: "501234567"),
        c("BH", "973", "Bahrain", ["#### ####"], lengths: 8...8, example: "36001234"),
        c("IL", "972", "Israel", ["##-###-####"], lengths: 8...9, trunk: "0", example: "502345678"),
        c("IQ", "964", "Iraq", ["### ### ####"], lengths: 10...10, trunk: "0", example: "7912345678"),
        c("IR", "98", "Iran", ["### ### ####"], lengths: 10...10, trunk: "0", example: "9123456789"),
        c("JO", "962", "Jordan", ["# #### ####"], lengths: 9...9, trunk: "0", example: "790123456"),
        c("KW", "965", "Kuwait", ["#### ####"], lengths: 8...8, example: "50012345"),
        c("LB", "961", "Lebanon", ["## ### ###"], lengths: 7...8, trunk: "0", example: "71123456"),
        c("OM", "968", "Oman", ["#### ####"], lengths: 8...8, example: "92123456"),
        c("PS", "970", "Palestine", ["### ### ###"], lengths: 9...9, trunk: "0", example: "599123456"),
        c("QA", "974", "Qatar", ["#### ####"], lengths: 8...8, example: "33123456"),
        c("SA", "966", "Saudi Arabia", ["## ### ####"], lengths: 9...9, trunk: "0", example: "512345678"),
        c("SY", "963", "Syria", ["### ### ###"], lengths: 9...9, trunk: "0", example: "944567890"),
        c("TR", "90", "Turkey", ["### ### ####"], lengths: 10...10, trunk: "0", example: "5012345678"),
        c("YE", "967", "Yemen", ["### ### ###"], lengths: 9...9, trunk: "0", example: "712345678"),

        // MARK: Asia
        c("AF", "93", "Afghanistan", ["## ### ####"], lengths: 9...9, trunk: "0", example: "701234567"),
        c("BD", "880", "Bangladesh", ["####-######"], lengths: 10...10, trunk: "0", example: "1812345678"),
        c("BN", "673", "Brunei", ["### ####"], lengths: 7...7, example: "7123456"),
        c("BT", "975", "Bhutan", ["## ## ## ##"], lengths: 8...8, example: "17123456"),
        c("CN", "86", "China", ["### #### ####"], lengths: 11...11, trunk: "0", example: "13123456789"),
        c("GE", "995", "Georgia", ["### ## ## ##"], lengths: 9...9, trunk: "0", example: "555123456"),
        c("HK", "852", "Hong Kong", ["#### ####"], lengths: 8...8, example: "51234567"),
        c("ID", "62", "Indonesia", ["###-###-####", "###-####-####"], lengths: 9...12, trunk: "0", example: "812345678"),
        c("IN", "91", "India", ["##### #####"], lengths: 10...10, trunk: "0", example: "8123456789"),
        c("JP", "81", "Japan", ["##-####-####"], lengths: 10...10, trunk: "0", example: "9012345678"),
        c("KG", "996", "Kyrgyzstan", ["### ### ###"], lengths: 9...9, trunk: "0", example: "700123456"),
        c("KH", "855", "Cambodia", ["## ### ####"], lengths: 8...9, trunk: "0", example: "91234567"),
        c("KP", "850", "North Korea", ["### #### ###"], lengths: 10...10, trunk: "0", example: "1921234567"),
        c("KR", "82", "South Korea", ["##-####-####"], lengths: 9...10, trunk: "0", example: "1012345678"),
        c("LA", "856", "Laos", ["## ## ### ###"], lengths: 9...10, trunk: "0", example: "2023123456"),
        c("LK", "94", "Sri Lanka", ["## ### ####"], lengths: 9...9, trunk: "0", example: "712345678"),
        c("MM", "95", "Myanmar", ["# ### ####", "## ### ####"], lengths: 7...10, trunk: "0", example: "92123456"),
        c("MN", "976", "Mongolia", ["#### ####"], lengths: 8...8, example: "88123456"),
        c("MO", "853", "Macao", ["#### ####"], lengths: 8...8, example: "66123456"),
        c("MV", "960", "Maldives", ["###-####"], lengths: 7...7, example: "7712345"),
        c("MY", "60", "Malaysia", ["##-### ####", "##-#### ####"], lengths: 9...10, trunk: "0", example: "123456789"),
        c("NP", "977", "Nepal", ["###-#######"], lengths: 10...10, trunk: "0", example: "9841234567"),
        c("PH", "63", "Philippines", ["### ### ####"], lengths: 10...10, trunk: "0", example: "9051234567"),
        c("PK", "92", "Pakistan", ["### #######"], lengths: 10...10, trunk: "0", example: "3012345678"),
        c("SG", "65", "Singapore", ["#### ####"], lengths: 8...8, example: "81234567"),
        c("TH", "66", "Thailand", ["## ### ####"], lengths: 9...9, trunk: "0", example: "812345678"),
        c("TJ", "992", "Tajikistan", ["### ## ####"], lengths: 9...9, example: "917123456"),
        c("TL", "670", "Timor-Leste", ["#### ####"], lengths: 7...8, example: "77212345"),
        c("TM", "993", "Turkmenistan", ["## ######"], lengths: 8...8, trunk: "8", example: "66123456"),
        c("TW", "886", "Taiwan", ["### ### ###"], lengths: 9...9, trunk: "0", example: "912345678"),
        c("UZ", "998", "Uzbekistan", ["## ### ## ##"], lengths: 9...9, example: "912345678"),
        c("VN", "84", "Vietnam", ["## ### ## ##"], lengths: 9...10, trunk: "0", example: "912345678"),

        // MARK: Americas
        c("AR", "54", "Argentina", ["## ####-####", "# ## ####-####"], lengths: 10...11, trunk: "0", example: "91123456789"),
        c("AW", "297", "Aruba", ["### ####"], lengths: 7...7, example: "5601234"),
        c("BO", "591", "Bolivia", ["########"], lengths: 8...8, example: "71234567"),
        c("BQ", "599", "Caribbean Netherlands", ["### ####"], lengths: 7...7, example: "3181234", leading: ["3", "4", "7"], main: false),
        c("BR", "55", "Brazil", ["(##) ####-####", "(##) #####-####"], lengths: 10...11, trunk: "0", example: "11961234567"),
        c("BZ", "501", "Belize", ["###-####"], lengths: 7...7, example: "6221234"),
        c("CL", "56", "Chile", ["# #### ####"], lengths: 9...9, example: "961234567"),
        c("CO", "57", "Colombia", ["### #######"], lengths: 10...10, example: "3211234567"),
        c("CR", "506", "Costa Rica", ["#### ####"], lengths: 8...8, example: "83123456"),
        c("CU", "53", "Cuba", ["# #######"], lengths: 6...8, trunk: "0", example: "51234567"),
        c("CW", "599", "Curaçao", ["# ### ####"], lengths: 7...8, example: "95181234"),
        c("EC", "593", "Ecuador", ["## ### ####"], lengths: 8...9, trunk: "0", example: "991234567"),
        c("FK", "500", "Falkland Islands", ["#####"], lengths: 5...5, example: "51234"),
        c("GF", "594", "French Guiana", ["### ## ## ##"], lengths: 9...9, trunk: "0", example: "694201234"),
        c("GL", "299", "Greenland", ["## ## ##"], lengths: 6...6, example: "221234"),
        c("GP", "590", "Guadeloupe", ["### ## ## ##"], lengths: 9...9, trunk: "0", example: "690001234"),
        c("GT", "502", "Guatemala", ["#### ####"], lengths: 8...8, example: "51234567"),
        c("GY", "592", "Guyana", ["### ####"], lengths: 7...7, example: "6091234"),
        c("HN", "504", "Honduras", ["####-####"], lengths: 8...8, example: "91234567"),
        c("HT", "509", "Haiti", ["## ## ####"], lengths: 8...8, example: "34101234"),
        c("MQ", "596", "Martinique", ["### ## ## ##"], lengths: 9...9, trunk: "0", example: "696201234"),
        c("MX", "52", "Mexico", ["## #### ####"], lengths: 10...10, example: "2221234567"),
        c("NI", "505", "Nicaragua", ["#### ####"], lengths: 8...8, example: "81234567"),
        c("PA", "507", "Panama", ["####-####"], lengths: 7...8, example: "61234567"),
        c("PE", "51", "Peru", ["### ### ###"], lengths: 9...9, trunk: "0", example: "912345678"),
        c("PM", "508", "Saint Pierre and Miquelon", ["## ## ##"], lengths: 6...6, trunk: "0", example: "551234"),
        c("PY", "595", "Paraguay", ["### ######"], lengths: 9...9, trunk: "0", example: "961456789"),
        c("SR", "597", "Suriname", ["###-####"], lengths: 6...7, example: "7412345"),
        c("SV", "503", "El Salvador", ["#### ####"], lengths: 8...8, example: "70123456"),
        c("UY", "598", "Uruguay", ["# ### ## ##"], lengths: 8...8, trunk: "0", example: "94231234"),
        c("VE", "58", "Venezuela", ["###-#######"], lengths: 10...10, trunk: "0", example: "4121234567"),
        c("BL", "590", "Saint Barthélemy", ["### ## ## ##"], lengths: 9...9, trunk: "0", example: "690271234", leading: ["69027", "69029"], main: false),
        c("MF", "590", "Saint Martin", ["### ## ## ##"], lengths: 9...9, trunk: "0", example: "690001234", leading: ["69000"], main: false),

        // MARK: Oceania
        c("AU", "61", "Australia", ["### ### ###"], lengths: 9...9, trunk: "0", example: "412345678"),
        c("CC", "61", "Cocos (Keeling) Islands", ["### ### ###"], lengths: 9...9, trunk: "0", example: "891621234", leading: ["89162"], main: false),
        c("CK", "682", "Cook Islands", ["## ###"], lengths: 5...5, example: "71234"),
        c("CX", "61", "Christmas Island", ["### ### ###"], lengths: 9...9, trunk: "0", example: "891641234", leading: ["89164"], main: false),
        c("FJ", "679", "Fiji", ["### ####"], lengths: 7...7, example: "7012345"),
        c("FM", "691", "Micronesia", ["### ####"], lengths: 7...7, example: "3501234"),
        c("KI", "686", "Kiribati", ["########"], lengths: 5...8, example: "72001234"),
        c("MH", "692", "Marshall Islands", ["###-####"], lengths: 7...7, example: "2351234"),
        c("NC", "687", "New Caledonia", ["##.##.##"], lengths: 6...6, example: "751234"),
        c("NF", "672", "Norfolk Island", ["# #####"], lengths: 6...6, example: "381234"),
        c("NR", "674", "Nauru", ["### ####"], lengths: 7...7, example: "5551234"),
        c("NU", "683", "Niue", ["### ####"], lengths: 4...7, example: "8884012"),
        c("NZ", "64", "New Zealand", ["## ### ####"], lengths: 8...10, trunk: "0", example: "211234567"),
        c("PF", "689", "French Polynesia", ["## ## ## ##"], lengths: 8...8, example: "87123456"),
        c("PG", "675", "Papua New Guinea", ["### ####"], lengths: 7...8, example: "70123456"),
        c("PW", "680", "Palau", ["### ####"], lengths: 7...7, example: "6201234"),
        c("SB", "677", "Solomon Islands", ["#######"], lengths: 5...7, example: "7421234"),
        c("TK", "690", "Tokelau", ["####"], lengths: 4...7, example: "7290"),
        c("TO", "676", "Tonga", ["### ####"], lengths: 5...7, example: "7715123"),
        c("TV", "688", "Tuvalu", ["######"], lengths: 5...7, example: "901234"),
        c("VU", "678", "Vanuatu", ["### ####"], lengths: 5...7, example: "5912345"),
        c("WF", "681", "Wallis and Futuna", ["## ## ##"], lengths: 6...6, example: "821234"),
        c("WS", "685", "Samoa", ["## #####"], lengths: 5...7, example: "7212345"),

        // MARK: Territories & remaining
        c("IO", "246", "British Indian Ocean Territory", ["### ####"], lengths: 7...7, example: "3801234"),
    ]
}
