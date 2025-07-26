//
//  CountryPicker.swift
//  SnoozeLane
//
//  Created by Elombe Kisala on 7/13/25.
//

import SwiftUI

struct CountryPicker: View {
    @Binding var selectedCountryCode: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    // Enhanced countries data with country names
    private let countriesData: [(String, String, String)] = [
        ("🇺🇸", "United States", "1"), ("🇨🇦", "Canada", "1"), ("🇬🇧", "United Kingdom", "44"),
        ("🇩🇪", "Germany", "49"), ("🇫🇷", "France", "33"), ("🇮🇹", "Italy", "39"),
        ("🇪🇸", "Spain", "34"), ("🇳🇱", "Netherlands", "31"), ("🇧🇪", "Belgium", "32"),
        ("🇨🇭", "Switzerland", "41"), ("🇦🇹", "Austria", "43"), ("🇸🇪", "Sweden", "46"),
        ("🇳🇴", "Norway", "47"), ("🇩🇰", "Denmark", "45"), ("🇫🇮", "Finland", "358"),
        ("🇵🇱", "Poland", "48"), ("🇨🇿", "Czech Republic", "420"), ("🇭🇺", "Hungary", "36"),
        ("🇷🇴", "Romania", "40"), ("🇧🇬", "Bulgaria", "359"), ("🇭🇷", "Croatia", "385"),
        ("🇸🇮", "Slovenia", "386"), ("🇸🇰", "Slovakia", "421"), ("🇱🇹", "Lithuania", "370"),
        ("🇱🇻", "Latvia", "371"), ("🇪🇪", "Estonia", "372"), ("🇮🇪", "Ireland", "353"),
        ("🇵🇹", "Portugal", "351"), ("🇬🇷", "Greece", "30"), ("🇨🇾", "Cyprus", "537"),
        ("🇲🇹", "Malta", "356"), ("🇱🇺", "Luxembourg", "352"), ("🇮🇸", "Iceland", "354"),
        ("🇱🇮", "Liechtenstein", "423"), ("🇲🇨", "Monaco", "377"), ("🇦🇩", "Andorra", "376"),
        ("🇸🇲", "San Marino", "378"), ("🇻🇦", "Vatican City", "379"), ("🇦🇺", "Australia", "61"),
        ("🇳🇿", "New Zealand", "64"), ("🇯🇵", "Japan", "81"), ("🇰🇷", "South Korea", "82"),
        ("🇨🇳", "China", "86"), ("🇮🇳", "India", "91"), ("🇸🇬", "Singapore", "65"),
        ("🇲🇾", "Malaysia", "60"), ("🇹🇭", "Thailand", "66"), ("🇵🇭", "Philippines", "63"),
        ("🇮🇩", "Indonesia", "62"), ("🇻🇳", "Vietnam", "84"), ("🇧🇷", "Brazil", "55"),
        ("🇦🇷", "Argentina", "54"), ("🇲🇽", "Mexico", "52"), ("🇨🇴", "Colombia", "57"),
        ("🇵🇪", "Peru", "51"), ("🇨🇱", "Chile", "56"), ("🇻🇪", "Venezuela", "58"),
        ("🇪🇨", "Ecuador", "593"), ("🇧🇴", "Bolivia", "591"), ("🇵🇾", "Paraguay", "595"),
        ("🇺🇾", "Uruguay", "598"), ("🇨🇷", "Costa Rica", "506"), ("🇵🇦", "Panama", "507"),
        ("🇬🇹", "Guatemala", "502"), ("🇸🇻", "El Salvador", "503"), ("🇭🇳", "Honduras", "504"),
        ("🇳🇮", "Nicaragua", "505"), ("🇧🇿", "Belize", "501"), ("🇬🇾", "Guyana", "595"),
        ("🇸🇷", "Suriname", "597"), ("🇬🇫", "French Guiana", "594"), ("🇵🇫", "French Polynesia", "689"),
        ("🇳🇨", "New Caledonia", "687"), ("🇷🇪", "Réunion", "262"), ("🇿🇦", "South Africa", "27"),
        ("🇪🇬", "Egypt", "20"), ("🇳🇬", "Nigeria", "234"), ("🇰🇪", "Kenya", "254"),
        ("🇬🇭", "Ghana", "233"), ("🇺🇬", "Uganda", "256"), ("🇹🇿", "Tanzania", "255"),
        ("🇿🇲", "Zambia", "260"), ("🇿🇼", "Zimbabwe", "263"), ("🇧🇼", "Botswana", "267"),
        ("🇳🇦", "Namibia", "264"), ("🇱🇸", "Lesotho", "266"), ("🇸🇿", "Eswatini", "268"),
        ("🇲🇬", "Madagascar", "261"), ("🇲🇺", "Mauritius", "230"), ("🇸🇨", "Seychelles", "248"),
        ("🇰🇲", "Comoros", "269"), ("🇲🇼", "Malawi", "265"), ("🇲🇿", "Mozambique", "258"),
        ("🇦🇴", "Angola", "244"), ("🇨🇻", "Cape Verde", "238"), ("🇬🇲", "Gambia", "220"),
        ("🇬🇳", "Guinea", "224"), ("🇬🇼", "Guinea-Bissau", "245"), ("🇸🇱", "Sierra Leone", "232"),
        ("🇱🇷", "Liberia", "231"), ("🇨🇮", "Ivory Coast", "225"), ("🇧🇫", "Burkina Faso", "226"),
        ("🇲🇱", "Mali", "223"), ("🇳🇪", "Niger", "227"), ("🇹🇩", "Chad", "235"),
        ("🇸🇩", "Sudan", "249"), ("🇪🇷", "Eritrea", "291"), ("🇩🇯", "Djibouti", "253"),
        ("🇸🇴", "Somalia", "252"), ("🇪🇹", "Ethiopia", "251"), ("🇸🇸", "South Sudan", "211"),
        ("🇨🇫", "Central African Republic", "236"), ("🇨🇬", "Republic of the Congo", "242"),
        ("🇨🇩", "Democratic Republic of the Congo", "243"), ("🇬🇦", "Gabon", "241"),
        ("🇬🇶", "Equatorial Guinea", "240"), ("🇨🇲", "Cameroon", "237"),
        ("🇸🇹", "São Tomé and Príncipe", "239"),
        ("🇸🇦", "Saudi Arabia", "966"), ("🇦🇪", "United Arab Emirates", "971"),
        ("🇶🇦", "Qatar", "974"), ("🇧🇭", "Bahrain", "973"), ("🇰🇼", "Kuwait", "965"),
        ("🇴🇲", "Oman", "968"), ("🇯🇴", "Jordan", "962"), ("🇱🇧", "Lebanon", "961"),
        ("🇸🇾", "Syria", "963"), ("🇮🇶", "Iraq", "964"), ("🇮🇷", "Iran", "98"),
        ("🇹🇷", "Turkey", "90"), ("🇮🇱", "Israel", "972"), ("🇵🇸", "Palestine", "970"),
        ("🇷🇺", "Russia", "7"), ("🇺🇦", "Ukraine", "380"), ("🇧🇾", "Belarus", "375"),
        ("🇲🇩", "Moldova", "373"), ("🇬🇪", "Georgia", "995"), ("🇦🇲", "Armenia", "374"),
        ("🇦🇿", "Azerbaijan", "994"), ("🇰🇿", "Kazakhstan", "77"), ("🇺🇿", "Uzbekistan", "998"),
        ("🇹🇲", "Turkmenistan", "993"), ("🇹🇯", "Tajikistan", "992"), ("🇰🇬", "Kyrgyzstan", "996"),
        ("🇲🇳", "Mongolia", "976"), ("🇹🇼", "Taiwan", "886"), ("🇭🇰", "Hong Kong", "852"),
        ("🇲🇴", "Macau", "853"), ("🇱🇦", "Laos", "856"), ("🇰🇭", "Cambodia", "855"),
        ("🇲🇲", "Myanmar", "95"), ("🇧🇳", "Brunei", "673"), ("🇹🇱", "Timor-Leste", "670"),
        ("🇵🇬", "Papua New Guinea", "675"), ("🇫🇯", "Fiji", "679"), ("🇻🇺", "Vanuatu", "678"),
        ("🇼🇸", "Samoa", "685"), ("🇹🇴", "Tonga", "676"), ("🇰🇮", "Kiribati", "686"),
        ("🇹🇻", "Tuvalu", "688"), ("🇳🇷", "Nauru", "674"), ("🇵🇼", "Palau", "680"),
        ("🇫🇲", "Micronesia", "691"), ("🇲🇭", "Marshall Islands", "692"),
        ("🇸🇧", "Solomon Islands", "677"),
    ]

    private var filteredCountries: [(String, String, String)] {
        if searchText.isEmpty {
            return countriesData
        } else {
            return countriesData.filter { country in
                country.1.localizedCaseInsensitiveContains(searchText)
                    || country.2.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search countries...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.top)

                List {
                    ForEach(filteredCountries, id: \.1) { flag, countryName, phoneCode in
                        Button(action: {
                            selectedCountryCode = phoneCode
                            dismiss()
                        }) {
                            HStack {
                                Text(flag)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(countryName)
                                        .foregroundColor(.primary)
                                        .font(.body)
                                    Text("+\(phoneCode)")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }

                                Spacer()

                                if selectedCountryCode == phoneCode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Select Country")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                #endif
            }
        }
    }
}

struct CountryPicker_Previews: PreviewProvider {
    static var previews: some View {
        CountryPicker(selectedCountryCode: .constant("1"))
    }
}
