//
//  OpenSourceViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 5/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

final class OpenSourceViewModel {

    private static let mitLicenseText = { (copyright: String) in
        """
        MIT License

        \(copyright)

        Permission is hereby granted, free of charge, to any person obtaining a copy \
        of this software and associated documentation files (the "Software"), to deal \
        in the Software without restriction, including without limitation the rights \
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell \
        copies of the Software, and to permit persons to whom the Software is \
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all \
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE \
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE \
        SOFTWARE.
        """
    }

    private static let apacheLicenseText = """
        Apache License
        Version 2.0, January 2004
        https://www.apache.org/licenses/LICENSE-2.0

        Licensed under the Apache License, Version 2.0 (the "License"); \
        you may not use this file except in compliance with the License. \
        You may obtain a copy of the License at

            https://www.apache.org/licenses/LICENSE-2.0

        Unless required by applicable law or agreed to in writing, software \
        distributed under the License is distributed on an "AS IS" BASIS, \
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. \
        See the License for the specific language governing permissions and \
        limitations under the License.
        """

    private static let zlibLicenseText = """
        zlib License

        Copyright (c) 2011 Petteri Aimonen <jpa@nanopb.mail.kapsi.fi>

        This software is provided 'as-is', without any express or implied \
        warranty. In no event will the authors be held liable for any damages \
        arising from the use of this software.

        Permission is granted to anyone to use this software for any purpose, \
        including commercial applications, and to alter it and redistribute it \
        freely, subject to the following restrictions:

        1. The origin of this software must not be misrepresented; you must not \
        claim that you wrote the original software. If you use this software \
        in a product, an acknowledgment in the product documentation would be \
        appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must not be \
        misrepresented as being the original software.

        3. This notice may not be removed or altered from any source distribution.
        """

    // MARK: - 라이선스 추가 시 여기만 수정
    let licenses: [OpenSourceLicense] = [
        OpenSourceLicense(
            name: "Alamofire",
            url: "https://github.com/Alamofire/Alamofire",
            copyright: "Copyright (c) 2014-2022 Alamofire Software Foundation (http://alamofire.org/)",
            licenseType: "MIT License",
            licenseText: mitLicenseText("Copyright (c) 2014-2022 Alamofire Software Foundation (http://alamofire.org/)")
        ),
        OpenSourceLicense(
            name: "Moya",
            url: "https://github.com/Moya/Moya",
            copyright: "Copyright (c) 2014-2022 Ash Furrow",
            licenseType: "MIT License",
            licenseText: mitLicenseText("Copyright (c) 2014-2022 Ash Furrow")
        ),
        OpenSourceLicense(
            name: "CombineMoya",
            url: "https://github.com/Moya/Moya",
            copyright: "Copyright (c) 2014-2022 Ash Furrow",
            licenseType: "MIT License",
            licenseText: mitLicenseText("Copyright (c) 2014-2022 Ash Furrow")
        ),
        OpenSourceLicense(
            name: "SnapKit",
            url: "https://github.com/SnapKit/SnapKit",
            copyright: "Copyright (c) 2011-2019 SnapKit Team",
            licenseType: "MIT License",
            licenseText: mitLicenseText("Copyright (c) 2011-2019 SnapKit Team")
        ),
        OpenSourceLicense(
            name: "Firebase iOS SDK",
            url: "https://github.com/firebase/firebase-ios-sdk",
            copyright: "Copyright Google LLC",
            licenseType: "Apache License 2.0",
            licenseText: apacheLicenseText
        ),
        OpenSourceLicense(
            name: "GoogleUtilities",
            url: "https://github.com/google/GoogleUtilities",
            copyright: "Copyright 2018 Google LLC",
            licenseType: "Apache License 2.0",
            licenseText: apacheLicenseText
        ),
        OpenSourceLicense(
            name: "Promises",
            url: "https://github.com/google/promises",
            copyright: "Copyright 2018 Google Inc.",
            licenseType: "Apache License 2.0",
            licenseText: apacheLicenseText
        ),
        OpenSourceLicense(
            name: "nanopb",
            url: "https://github.com/nanopb/nanopb",
            copyright: "Copyright (c) 2011 Petteri Aimonen",
            licenseType: "zlib License",
            licenseText: zlibLicenseText
        )
    ]
}
