import Firebase
import FirebaseFirestore
//
//  LoginViewModel.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 3/24/24.
//
import SwiftUI

typealias FirestoreFieldValue = FirebaseFirestore.FieldValue

class LoginViewModel: ObservableObject {

    @Published var phNo = ""
    @Published var code = ""
    @Published var selectedCountryCode: String = ""
    @Published var searchText = ""

    // Country data structure
    struct Country: Hashable {
        let name: String
        let code: String
        let flag: String
    }

    // Complete list of countries with flags
    private let allCountries: [Country] = [
        Country(name: "Afghanistan", code: "93", flag: "🇦🇫"),
        Country(name: "Albania", code: "355", flag: "🇦🇱"),
        Country(name: "Algeria", code: "213", flag: "🇩🇿"),
        Country(name: "American Samoa", code: "1", flag: "🇦🇸"),
        Country(name: "Andorra", code: "376", flag: "🇦🇩"),
        Country(name: "Angola", code: "244", flag: "🇦🇴"),
        Country(name: "Anguilla", code: "1", flag: "🇦🇮"),
        Country(name: "Antigua and Barbuda", code: "1", flag: "🇦🇬"),
        Country(name: "Argentina", code: "54", flag: "🇦🇷"),
        Country(name: "Armenia", code: "374", flag: "🇦🇲"),
        Country(name: "Aruba", code: "297", flag: "🇦🇼"),
        Country(name: "Australia", code: "61", flag: "🇦🇺"),
        Country(name: "Austria", code: "43", flag: "🇦🇹"),
        Country(name: "Azerbaijan", code: "994", flag: "🇦🇿"),
        Country(name: "Bahamas", code: "1", flag: "🇧🇸"),
        Country(name: "Bahrain", code: "973", flag: "🇧🇭"),
        Country(name: "Bangladesh", code: "880", flag: "🇧🇩"),
        Country(name: "Barbados", code: "1", flag: "🇧🇧"),
        Country(name: "Belarus", code: "375", flag: "🇧🇾"),
        Country(name: "Belgium", code: "32", flag: "🇧🇪"),
        Country(name: "Belize", code: "501", flag: "🇧🇿"),
        Country(name: "Benin", code: "229", flag: "🇧🇯"),
        Country(name: "Bermuda", code: "1", flag: "🇧🇲"),
        Country(name: "Bhutan", code: "975", flag: "🇧🇹"),
        Country(name: "Bosnia and Herzegovina", code: "387", flag: "🇧🇦"),
        Country(name: "Botswana", code: "267", flag: "🇧🇼"),
        Country(name: "Brazil", code: "55", flag: "🇧🇷"),
        Country(name: "British Indian Ocean Territory", code: "246", flag: "🇮🇴"),
        Country(name: "Bulgaria", code: "359", flag: "🇧🇬"),
        Country(name: "Burkina Faso", code: "226", flag: "🇧🇫"),
        Country(name: "Burundi", code: "257", flag: "🇧🇮"),
        Country(name: "Cambodia", code: "855", flag: "🇰🇭"),
        Country(name: "Cameroon", code: "237", flag: "🇨🇲"),
        Country(name: "Canada", code: "1", flag: "🇨🇦"),
        Country(name: "Cape Verde", code: "238", flag: "🇨🇻"),
        Country(name: "Cayman Islands", code: "345", flag: "🇰🇾"),
        Country(name: "Central African Republic", code: "236", flag: "🇨🇫"),
        Country(name: "Chad", code: "235", flag: "🇹🇩"),
        Country(name: "Chile", code: "56", flag: "🇨🇱"),
        Country(name: "China", code: "86", flag: "🇨🇳"),
        Country(name: "Christmas Island", code: "61", flag: "🇨🇽"),
        Country(name: "Colombia", code: "57", flag: "🇨🇴"),
        Country(name: "Comoros", code: "269", flag: "🇰🇲"),
        Country(name: "Congo", code: "242", flag: "🇨🇬"),
        Country(name: "Cook Islands", code: "682", flag: "🇨🇰"),
        Country(name: "Costa Rica", code: "506", flag: "🇨🇷"),
        Country(name: "Croatia", code: "385", flag: "🇭🇷"),
        Country(name: "Cuba", code: "53", flag: "🇨🇺"),
        Country(name: "Cyprus", code: "537", flag: "🇨🇾"),
        Country(name: "Czech Republic", code: "420", flag: "🇨🇿"),
        Country(name: "Denmark", code: "45", flag: "🇩🇰"),
        Country(name: "Djibouti", code: "253", flag: "🇩🇯"),
        Country(name: "Dominica", code: "1", flag: "🇩🇲"),
        Country(name: "Dominican Republic", code: "1", flag: "🇩🇴"),
        Country(name: "Ecuador", code: "593", flag: "🇪🇨"),
        Country(name: "Egypt", code: "20", flag: "🇪🇬"),
        Country(name: "El Salvador", code: "503", flag: "🇸🇻"),
        Country(name: "Equatorial Guinea", code: "240", flag: "🇬🇶"),
        Country(name: "Eritrea", code: "291", flag: "🇪🇷"),
        Country(name: "Estonia", code: "372", flag: "🇪🇪"),
        Country(name: "Ethiopia", code: "251", flag: "🇪🇹"),
        Country(name: "Faroe Islands", code: "298", flag: "🇫🇴"),
        Country(name: "Fiji", code: "679", flag: "🇫🇯"),
        Country(name: "Finland", code: "358", flag: "🇫🇮"),
        Country(name: "France", code: "33", flag: "🇫🇷"),
        Country(name: "French Guiana", code: "594", flag: "🇬🇫"),
        Country(name: "French Polynesia", code: "689", flag: "🇵🇫"),
        Country(name: "Gabon", code: "241", flag: "🇬🇦"),
        Country(name: "Gambia", code: "220", flag: "🇬🇲"),
        Country(name: "Georgia", code: "995", flag: "🇬🇪"),
        Country(name: "Germany", code: "49", flag: "🇩🇪"),
        Country(name: "Ghana", code: "233", flag: "🇬🇭"),
        Country(name: "Gibraltar", code: "350", flag: "🇬🇮"),
        Country(name: "Greece", code: "30", flag: "🇬🇷"),
        Country(name: "Greenland", code: "299", flag: "🇬🇱"),
        Country(name: "Grenada", code: "1", flag: "🇬🇩"),
        Country(name: "Guadeloupe", code: "590", flag: "🇬🇵"),
        Country(name: "Guam", code: "1", flag: "🇬🇺"),
        Country(name: "Guatemala", code: "502", flag: "🇬🇹"),
        Country(name: "Guinea", code: "224", flag: "🇬🇳"),
        Country(name: "Guinea-Bissau", code: "245", flag: "🇬🇼"),
        Country(name: "Guyana", code: "595", flag: "🇬🇾"),
        Country(name: "Haiti", code: "509", flag: "🇭🇹"),
        Country(name: "Honduras", code: "504", flag: "🇭🇳"),
        Country(name: "Hungary", code: "36", flag: "🇭🇺"),
        Country(name: "Iceland", code: "354", flag: "🇮🇸"),
        Country(name: "India", code: "91", flag: "🇮🇳"),
        Country(name: "Indonesia", code: "62", flag: "🇮🇩"),
        Country(name: "Iraq", code: "964", flag: "🇮🇶"),
        Country(name: "Ireland", code: "353", flag: "🇮🇪"),
        Country(name: "Israel", code: "972", flag: "🇮🇱"),
        Country(name: "Italy", code: "39", flag: "🇮🇹"),
        Country(name: "Jamaica", code: "1", flag: "🇯🇲"),
        Country(name: "Japan", code: "81", flag: "🇯🇵"),
        Country(name: "Jordan", code: "962", flag: "🇯🇴"),
        Country(name: "Kazakhstan", code: "77", flag: "🇰🇿"),
        Country(name: "Kenya", code: "254", flag: "🇰🇪"),
        Country(name: "Kiribati", code: "686", flag: "🇰🇮"),
        Country(name: "Kuwait", code: "965", flag: "🇰🇼"),
        Country(name: "Kyrgyzstan", code: "996", flag: "🇰🇬"),
        Country(name: "Latvia", code: "371", flag: "🇱🇻"),
        Country(name: "Lebanon", code: "961", flag: "🇱🇧"),
        Country(name: "Lesotho", code: "266", flag: "🇱🇸"),
        Country(name: "Liberia", code: "231", flag: "🇱🇷"),
        Country(name: "Liechtenstein", code: "423", flag: "🇱🇮"),
        Country(name: "Lithuania", code: "370", flag: "🇱🇹"),
        Country(name: "Luxembourg", code: "352", flag: "🇱🇺"),
        Country(name: "Madagascar", code: "261", flag: "🇲🇬"),
        Country(name: "Malawi", code: "265", flag: "🇲🇼"),
        Country(name: "Malaysia", code: "60", flag: "🇲🇾"),
        Country(name: "Maldives", code: "960", flag: "🇲🇻"),
        Country(name: "Mali", code: "223", flag: "🇲🇱"),
        Country(name: "Malta", code: "356", flag: "🇲🇹"),
        Country(name: "Marshall Islands", code: "692", flag: "🇲🇭"),
        Country(name: "Martinique", code: "596", flag: "🇲🇶"),
        Country(name: "Mauritania", code: "222", flag: "🇲🇷"),
        Country(name: "Mauritius", code: "230", flag: "🇲🇺"),
        Country(name: "Mayotte", code: "262", flag: "🇾🇹"),
        Country(name: "Mexico", code: "52", flag: "🇲🇽"),
        Country(name: "Monaco", code: "377", flag: "🇲🇨"),
        Country(name: "Mongolia", code: "976", flag: "🇲🇳"),
        Country(name: "Montenegro", code: "382", flag: "🇲🇪"),
        Country(name: "Montserrat", code: "1", flag: "🇲🇸"),
        Country(name: "Morocco", code: "212", flag: "🇲🇦"),
        Country(name: "Myanmar", code: "95", flag: "🇲🇲"),
        Country(name: "Namibia", code: "264", flag: "🇳🇦"),
        Country(name: "Nauru", code: "674", flag: "🇳🇷"),
        Country(name: "Nepal", code: "977", flag: "🇳🇵"),
        Country(name: "Netherlands", code: "31", flag: "🇳🇱"),
        Country(name: "Netherlands Antilles", code: "599", flag: "🇧🇶"),
        Country(name: "New Caledonia", code: "687", flag: "🇳🇨"),
        Country(name: "New Zealand", code: "64", flag: "🇳🇿"),
        Country(name: "Nicaragua", code: "505", flag: "🇳🇮"),
        Country(name: "Niger", code: "227", flag: "🇳🇪"),
        Country(name: "Nigeria", code: "234", flag: "🇳🇬"),
        Country(name: "Niue", code: "683", flag: "🇳🇺"),
        Country(name: "Norfolk Island", code: "672", flag: "🇳🇫"),
        Country(name: "Northern Mariana Islands", code: "1", flag: "🇲🇵"),
        Country(name: "Norway", code: "47", flag: "🇳🇴"),
        Country(name: "Oman", code: "968", flag: "🇴🇲"),
        Country(name: "Pakistan", code: "92", flag: "🇵🇰"),
        Country(name: "Palau", code: "680", flag: "🇵🇼"),
        Country(name: "Panama", code: "507", flag: "🇵🇦"),
        Country(name: "Papua New Guinea", code: "675", flag: "🇵🇬"),
        Country(name: "Paraguay", code: "595", flag: "🇵🇾"),
        Country(name: "Peru", code: "51", flag: "🇵🇪"),
        Country(name: "Philippines", code: "63", flag: "🇵🇭"),
        Country(name: "Poland", code: "48", flag: "🇵🇱"),
        Country(name: "Portugal", code: "351", flag: "🇵🇹"),
        Country(name: "Puerto Rico", code: "1", flag: "🇵🇷"),
        Country(name: "Qatar", code: "974", flag: "🇶🇦"),
        Country(name: "Romania", code: "40", flag: "🇷🇴"),
        Country(name: "Rwanda", code: "250", flag: "🇷🇼"),
        Country(name: "Samoa", code: "685", flag: "🇼🇸"),
        Country(name: "San Marino", code: "378", flag: "🇸🇲"),
        Country(name: "Saudi Arabia", code: "966", flag: "🇸🇦"),
        Country(name: "Senegal", code: "221", flag: "🇸🇳"),
        Country(name: "Serbia", code: "381", flag: "🇷🇸"),
        Country(name: "Seychelles", code: "248", flag: "🇸🇨"),
        Country(name: "Sierra Leone", code: "232", flag: "🇸🇱"),
        Country(name: "Singapore", code: "65", flag: "🇸🇬"),
        Country(name: "Slovakia", code: "421", flag: "🇸🇰"),
        Country(name: "Slovenia", code: "386", flag: "🇸🇮"),
        Country(name: "Solomon Islands", code: "677", flag: "🇸🇧"),
        Country(name: "South Africa", code: "27", flag: "🇿🇦"),
        Country(name: "South Georgia", code: "500", flag: "🇬🇸"),
        Country(name: "Spain", code: "34", flag: "🇪🇸"),
        Country(name: "Sri Lanka", code: "94", flag: "🇱🇰"),
        Country(name: "Sudan", code: "249", flag: "🇸🇩"),
        Country(name: "Suriname", code: "597", flag: "🇸🇷"),
        Country(name: "Swaziland", code: "268", flag: "🇸🇿"),
        Country(name: "Sweden", code: "46", flag: "🇸🇪"),
        Country(name: "Switzerland", code: "41", flag: "🇨🇭"),
        Country(name: "Tajikistan", code: "992", flag: "🇹🇯"),
        Country(name: "Thailand", code: "66", flag: "🇹🇭"),
        Country(name: "Togo", code: "228", flag: "🇹🇬"),
        Country(name: "Tokelau", code: "690", flag: "🇹🇰"),
        Country(name: "Tonga", code: "676", flag: "🇹🇴"),
        Country(name: "Trinidad and Tobago", code: "1", flag: "🇹🇹"),
        Country(name: "Tunisia", code: "216", flag: "🇹🇳"),
        Country(name: "Turkey", code: "90", flag: "🇹🇷"),
        Country(name: "Turkmenistan", code: "993", flag: "🇹🇲"),
        Country(name: "Turks and Caicos Islands", code: "1", flag: "🇹🇨"),
        Country(name: "Tuvalu", code: "688", flag: "🇹🇻"),
        Country(name: "Uganda", code: "256", flag: "🇺🇬"),
        Country(name: "Ukraine", code: "380", flag: "🇺🇦"),
        Country(name: "United Arab Emirates", code: "971", flag: "🇦🇪"),
        Country(name: "United Kingdom", code: "44", flag: "🇬🇧"),
        Country(name: "United States", code: "1", flag: "🇺🇸"),
        Country(name: "Uruguay", code: "598", flag: "🇺🇾"),
        Country(name: "Uzbekistan", code: "998", flag: "🇺🇿"),
        Country(name: "Vanuatu", code: "678", flag: "🇻🇺"),
        Country(name: "Wallis and Futuna", code: "681", flag: "🇼🇫"),
        Country(name: "Yemen", code: "967", flag: "🇾🇪"),
        Country(name: "Zambia", code: "260", flag: "🇿🇲"),
        Country(name: "Zimbabwe", code: "263", flag: "🇿🇼"),
        Country(name: "Bolivia", code: "591", flag: "🇧🇴"),
        Country(name: "Brunei", code: "673", flag: "🇧🇳"),
        Country(name: "Cocos Islands", code: "61", flag: "🇨🇨"),
        Country(name: "Democratic Republic of the Congo", code: "243", flag: "🇨🇩"),
        Country(name: "Ivory Coast", code: "225", flag: "🇨🇮"),
        Country(name: "Falkland Islands", code: "500", flag: "🇫🇰"),
        Country(name: "Guernsey", code: "44", flag: "🇬🇬"),
        Country(name: "Vatican City", code: "379", flag: "🇻🇦"),
        Country(name: "Hong Kong", code: "852", flag: "🇭🇰"),
        Country(name: "Iran", code: "98", flag: "🇮🇷"),
        Country(name: "Isle of Man", code: "44", flag: "🇮🇲"),
        Country(name: "Jersey", code: "44", flag: "🇯🇪"),
        Country(name: "North Korea", code: "850", flag: "🇰🇵"),
        Country(name: "South Korea", code: "82", flag: "🇰🇷"),
        Country(name: "Laos", code: "856", flag: "🇱🇦"),
        Country(name: "Libya", code: "218", flag: "🇱🇾"),
        Country(name: "Macau", code: "853", flag: "🇲🇴"),
        Country(name: "Macedonia", code: "389", flag: "🇲🇰"),
        Country(name: "Micronesia", code: "691", flag: "🇫🇲"),
        Country(name: "Moldova", code: "373", flag: "🇲🇩"),
        Country(name: "Mozambique", code: "258", flag: "🇲🇿"),
        Country(name: "Palestine", code: "970", flag: "🇵🇸"),
        Country(name: "Pitcairn", code: "872", flag: "🇵🇳"),
        Country(name: "Reunion", code: "262", flag: "🇷🇪"),
        Country(name: "Russia", code: "7", flag: "🇷🇺"),
        Country(name: "Saint Barthelemy", code: "590", flag: "🇧🇱"),
        Country(name: "Saint Helena", code: "290", flag: "🇸🇭"),
        Country(name: "Saint Kitts and Nevis", code: "1", flag: "🇰🇳"),
        Country(name: "Saint Lucia", code: "1", flag: "🇱🇨"),
        Country(name: "Saint Martin", code: "590", flag: "🇲🇫"),
        Country(name: "Saint Pierre and Miquelon", code: "508", flag: "🇵🇲"),
        Country(name: "Saint Vincent and the Grenadines", code: "1", flag: "🇻🇨"),
        Country(name: "Sao Tome and Principe", code: "239", flag: "🇸🇹"),
        Country(name: "Somalia", code: "252", flag: "🇸🇴"),
        Country(name: "Svalbard and Jan Mayen", code: "47", flag: "🇸🇯"),
        Country(name: "Syria", code: "963", flag: "🇸🇾"),
        Country(name: "Taiwan", code: "886", flag: "🇹🇼"),
        Country(name: "Tanzania", code: "255", flag: "🇹🇿"),
        Country(name: "Timor-Leste", code: "670", flag: "🇹🇱"),
        Country(name: "Venezuela", code: "58", flag: "🇻🇪"),
        Country(name: "Vietnam", code: "84", flag: "🇻🇳"),
        Country(name: "British Virgin Islands", code: "284", flag: "🇻🇬"),
        Country(name: "U.S. Virgin Islands", code: "340", flag: "🇻🇮"),
    ]

    // Country code mapping for region detection
    private let countries: [String: String] = [
        "US": "1", "CA": "1", "MX": "52", "GB": "44", "DE": "49", "FR": "33", "IT": "39",
        "ES": "34",
        "AU": "61", "JP": "81", "CN": "86", "IN": "91", "BR": "55", "RU": "7", "KR": "82",
        "CA": "1",
        "MX": "52", "AR": "54", "CL": "56", "CO": "57", "PE": "51", "VE": "58", "EC": "593",
        "BO": "591",
        "PY": "595", "UY": "598", "GY": "592", "SR": "597", "GF": "594", "FK": "500", "GS": "500",
        "TC": "1", "VG": "1", "VI": "1", "PR": "1", "DO": "1", "HT": "509", "JM": "1", "BB": "1",
        "TT": "1", "GD": "1", "LC": "1", "VC": "1", "AG": "1", "KN": "1", "DM": "1", "MS": "1",
        "AW": "297", "CW": "599", "SX": "1", "BQ": "599", "AI": "1", "BM": "1", "IO": "246",
        "KY": "1",
        "TC": "1", "VG": "1", "VI": "1", "PR": "1", "DO": "1", "HT": "509", "JM": "1", "BB": "1",
        "TT": "1", "GD": "1", "LC": "1", "VC": "1", "AG": "1", "KN": "1", "DM": "1", "MS": "1",
    ]

    // Computed property for filtered countries based on search
    var filteredCountries: [Country] {
        if searchText.isEmpty {
            return allCountries
        } else {
            return allCountries.filter { country in
                country.name.lowercased().contains(searchText.lowercased())
                    || country.code.contains(searchText) || country.flag.contains(searchText)
            }
        }
    }

    // DataModel For Error View...
    @Published var errorMsg = ""
    @Published var error = false

    // storing CODE for verification...
    @Published var CODE = ""

    @Published var gotoVerify = false

    // User Logged Status
    @AppStorage("log_Status") var status = false

    // Loading View....
    @Published var loading = false
    @Published var fullPhoneNumber: String = ""

    // Default test verification code for simulator
    private let testVerificationCode = "123456"

    init() {
        // Initialize with user's detected country code
        selectedCountryCode = getDetectedCountryCode()
    }

    var isPhoneNumberValid: Bool {
        // Example: Check for minimum length of 10 digits
        return phNo.count >= 10
    }

    func getDetectedCountryCode() -> String {
        let regionCode = Locale.current.regionCode ?? ""
        return countries[regionCode] ?? "1"  // Default to US (+1)
    }

    func getCountryCode() -> String {
        // If user has selected a country code, use it; otherwise use detected country
        if !selectedCountryCode.isEmpty {
            return selectedCountryCode
        }
        return getDetectedCountryCode()
    }

    // sending Code To User....

    func sendCode() {
        #if targetEnvironment(simulator)
            // For simulator testing
            Auth.auth().settings?.isAppVerificationDisabledForTesting = true
            let number = "+\(getCountryCode())\(phNo)"
            self.fullPhoneNumber = number

            // Use a test verification ID for simulator
            self.CODE = "test-verification-id"
            self.gotoVerify = true
            self.errorMsg = "Test verification code: \(testVerificationCode)"
            withAnimation { self.error.toggle() }
        #else
            // For real device
            Auth.auth().settings?.isAppVerificationDisabledForTesting = false
            let number = "+\(getCountryCode())\(phNo)"
            self.fullPhoneNumber = number

            PhoneAuthProvider.provider().verifyPhoneNumber(number, uiDelegate: nil) { (CODE, err) in
                if let error = err {
                    self.errorMsg = error.localizedDescription
                    withAnimation { self.error.toggle() }
                    return
                }
                self.CODE = CODE ?? ""
                self.gotoVerify = true
                self.errorMsg = "Code sent successfully!"
                withAnimation { self.error.toggle() }
            }
        #endif
    }

    func verifyCode() {
        loading = true

        #if targetEnvironment(simulator)
            // For simulator testing
            if code == testVerificationCode {
                // Create a test user account for simulator
                let testUID = "simulator-test-user-\(UUID().uuidString)"
                let db = Firestore.firestore()
                let userRef = db.collection("Users").document(testUID)

                userRef.setData([
                    "phoneNumber": self.fullPhoneNumber,
                    "CallCount": 0,
                    "createdAt": FieldValue.serverTimestamp(),
                    "isSimulatorUser": true,
                ]) { error in
                    if let error = error {
                        self.errorMsg = "Error creating test user: \(error.localizedDescription)"
                        withAnimation {
                            self.error.toggle()
                            self.loading = false
                        }
                        return
                    }

                    // Successfully created test user
                    withAnimation {
                        self.status = true
                        self.loading = false
                    }

                    print(
                        "✅ Simulator test user created successfully with phone: \(self.fullPhoneNumber)"
                    )
                }
            } else {
                self.errorMsg = "Invalid verification code. Use: \(testVerificationCode)"
                withAnimation {
                    self.error.toggle()
                    self.loading = false
                }
            }
        #else
            // For real device
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: self.CODE,
                verificationCode: code
            )

            Auth.auth().signIn(with: credential) { (result, err) in
                self.loading = false

                if let error = err {
                    self.errorMsg = error.localizedDescription
                    withAnimation { self.error.toggle() }
                    return
                }
                withAnimation { self.status = true }
                // Firestore: Link phone number to UID
                if let user = Auth.auth().currentUser {
                    let db = Firestore.firestore()
                    let userRef = db.collection("Users").document(user.uid)
                    let phoneNumber = user.phoneNumber ?? self.fullPhoneNumber
                    userRef.setData(
                        [
                            "phoneNumber": phoneNumber,
                            "CallCount": 0,
                        ], merge: true)
                }
            }
        #endif
    }

    func requestCode() {
        sendCode()
    }
}
