import Foundation

/// 이모지 고르기 시트의 카테고리별 목록 (GH-64 R-40). 서버 없이 앱에 그대로 넣는다.
/// 기본 키보드의 이모지 입력은 쓰지 않으므로, 위시 아이콘으로 쓰기 좋은 것들을 카테고리마다 모았다
enum EmojiCategory: String, CaseIterable, Identifiable {
    case smileys
    case people
    case animals
    case food
    case activities
    case travel
    case objects
    case symbols
    case flags

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smileys: return Strings.EmojiPicker.Category.smileys
        case .people: return Strings.EmojiPicker.Category.people
        case .animals: return Strings.EmojiPicker.Category.animals
        case .food: return Strings.EmojiPicker.Category.food
        case .activities: return Strings.EmojiPicker.Category.activities
        case .travel: return Strings.EmojiPicker.Category.travel
        case .objects: return Strings.EmojiPicker.Category.objects
        case .symbols: return Strings.EmojiPicker.Category.symbols
        case .flags: return Strings.EmojiPicker.Category.flags
        }
    }

    var emojis: [String] {
        switch self {
        case .smileys:
            return EmojiCatalog.split("😀😃😄😁😆😅🤣😂🙂🙃😉😊😇🥰😍🤩😘😗😚😙😋😛😜🤪😝🤑🤗🤭🤫🤔🤐🤨😐😑😶😏😒🙄😬😌😔😪🤤😴😷🤒🤕🤢🤮🥵🥶🥴😵🤯🤠🥳😎🤓🧐😕😟🙁😮😯😲😳🥺😦😧😨😰😥😢😭😱😖😣😞😓😩😫🥱😤😡😠🤬😈👿💀👻👽🤖💩😺😸😹😻😼😽🙀😿😾")
        case .people:
            return EmojiCatalog.split("👋🤚🖐✋🖖👌🤌🤏✌🤞🤟🤘🤙👈👉👆👇☝👍👎✊👊🤛🤜👏🙌👐🤲🤝🙏✍💅🤳💪🦾🦵🦶👂🦻👃🧠🫀🫁🦷🦴👀👁👅👄👶🧒👦👧🧑👱👨🧔👩🧓👴👵🙍🙎🙅🙆💁🙋🧏🙇🤦🤷👮🕵💂🥷👷🤴👸👳👲🧕🤵👰🤰🤱👼🎅🤶🦸🦹🧙🧚🧛🧜🧝🧞🧟💆💇🚶🧍🧎🏃💃🕺👯🧖🧗🤺🏇⛷🏂🏌🏄🚣🏊⛹🏋🚴🚵🤸🤼🤽🤾🤹🧘🛀🛌👭👫👬💏💑👪")
        case .animals:
            return EmojiCatalog.split("🐶🐱🐭🐹🐰🦊🐻🐼🐨🐯🦁🐮🐷🐸🐵🙈🙉🙊🐒🐔🐧🐦🐤🐣🐥🦆🦅🦉🦇🐺🐗🐴🦄🐝🪱🐛🦋🐌🐞🐜🪰🪲🦟🦗🕷🦂🐢🐍🦎🦖🦕🐙🦑🦐🦞🦀🐡🐠🐟🐬🐳🐋🦈🐊🐅🐆🦓🦍🦧🐘🦛🦏🐪🐫🦒🦘🐃🐂🐄🐎🐖🐏🐑🦙🐐🦌🐕🐩🦮🐈🐓🦃🦚🦜🦢🦩🕊🐇🦝🦨🦡🦦🦥🐁🐀🐿🦔🐾🐉🐲🌵🎄🌲🌳🌴🌱🌿☘🍀🎍🎋🍃🍂🍁🍄🐚🌾💐🌷🌹🥀🌺🌸🌼🌻")
        case .food:
            return EmojiCatalog.split("🍏🍎🍐🍊🍋🍌🍉🍇🍓🫐🍈🍒🍑🥭🍍🥥🥝🍅🍆🥑🥦🥬🥒🌶🫑🌽🥕🧄🧅🥔🍠🥐🥯🍞🥖🥨🧀🥚🍳🧈🥞🧇🥓🥩🍗🍖🌭🍔🍟🍕🫓🥪🥙🧆🌮🌯🫔🥗🥘🫕🥫🍝🍜🍲🍛🍣🍱🥟🦪🍤🍙🍚🍘🍥🥠🥮🍢🍡🍧🍨🍦🥧🧁🍰🎂🍮🍭🍬🍫🍿🍩🍪🌰🥜🍯🥛🍼☕🍵🧃🥤🧋🍶🍺🍻🥂🍷🥃🍸🍹🧉🍾🧊🥄🍴🍽🥣🥡🥢🧂")
        case .activities:
            return EmojiCatalog.split("⚽🏀🏈⚾🥎🎾🏐🏉🥏🎱🪀🏓🏸🏒🏑🥍🏏🪃🥅⛳🪁🏹🎣🤿🥊🥋🎽🛹🛼🛷⛸🥌🎿🏆🥇🥈🥉🏅🎖🏵🎗🎫🎟🎪🤹🎭🩰🎨🎬🎤🎧🎼🎹🥁🪘🎷🎺🪗🎸🪕🎻🎲♟🎯🎳🎮🎰🧩🎉🎊🎈🎁🎀🪄🎃🎆🎇🧨✨🎐🎑🎎🏮🎏🧧")
        case .travel:
            return EmojiCatalog.split("🚗🚕🚙🚌🚎🏎🚓🚑🚒🚐🛻🚚🚛🚜🛵🏍🛺🚲🛴🚨🚔🚍🚘🚖🚡🚠🚟🚃🚋🚞🚝🚄🚅🚈🚂🚆🚇🚊🚉✈🛫🛬🛩💺🛰🚀🛸🚁🛶⛵🚤🛥🛳⛴🚢⚓⛽🚧🚦🚥🗺🗿🗽🗼🏰🏯🏟🎡🎢🎠⛲⛱🏖🏝🏜🌋⛰🏔🗻🏕⛺🏠🏡🏘🏚🏗🏭🏢🏬🏣🏤🏥🏦🏨🏪🏫🏩💒🏛⛪🕌🕍🛕🕋⛩🛤🛣🗾🎑🏞🌅🌄🌠🎇🎆🌇🌆🏙🌃🌌🌉🌁")
        case .objects:
            return EmojiCatalog.split("⌚📱💻⌨🖥🖨🖱💽💾💿📀📷📸📹🎥📽🎞📞☎📟📠📺📻🎙⏱⏲⏰🕰⌛⏳📡🔋🔌💡🔦🕯🪔🧯💸💵💴💶💷💰💳💎⚖🧰🔧🔨⚒🛠⛏🔩⚙🧱⛓🧲🔫💣🧨🪓🔪🗡⚔🛡🔮📿🧿💈⚗🔭🔬🕳🩹🩺💊💉🩸🧬🦠🧫🧪🌡🧹🧺🧻🚽🚰🚿🛁🧼🪥🪒🧽🪣🧴🛎🔑🗝🚪🪑🛋🛏🧸🪆🖼🪞🪟🛍🛒🎁🎈🎏🎀🪄🪅🎊🎉🎎🏮🎐🧧✉📩📨📧💌📥📤📦🏷📪📫📬📭📮📯📜📃📄📑🧾📊📈📉🗒🗓📆📅🗑📇🗃🗳🗄📋📁📂🗂🗞📰📓📔📒📕📗📘📙📚📖🔖🧷🔗📎🖇📐📏🧮📌📍✂🖊🖋✒🖌🖍📝✏🔍🔎🔏🔐🔒🔓")
        case .symbols:
            return EmojiCatalog.split("❤🧡💛💚💙💜🖤🤍🤎💔❣💕💞💓💗💖💘💝💟☮✝☪🕉☸✡🔯🕎☯☦🛐⛎♈♉♊♋♌♍♎♏♐♑♒♓🆔⚛🉑☢☣📴📳🈶🈚🈸🈺🈷✴🆚💮🉐㊙㊗🈴🈵🈹🈲🅰🅱🆎🆑🅾🆘❌⭕🛑⛔📛🚫💯💢♨🚷🚯🚳🚱🔞📵🚭❗❕❓❔‼⁉🔅🔆〽⚠🚸🔱⚜🔰♻✅🈯💹❇✳❎🌐💠Ⓜ🌀💤🏧🚾♿🅿🈳🈂🛂🛃🛄🛅🚹🚺🚼⚧🚻🚮🎦📶🈁🔣ℹ🔤🔡🔠🆖🆗🆙🆒🆕🆓🔟🔢#*⏏▶⏸⏯⏹⏺⏭⏮⏩⏪⏫⏬◀🔼🔽➡⬅⬆⬇↗↘↙↖↕↔↪↩⤴⤵🔀🔁🔂🔄🔃🎵🎶➕➖➗✖♾💲💱™©®〰➰➿🔚🔙🔛🔝🔜✔☑🔘🔴🟠🟡🟢🔵🟣⚫⚪🟤🔺🔻🔸🔹🔶🔷🔳🔲▪▫◾◽◼◻🟥🟧🟨🟩🟦🟪⬛⬜🟫🔈🔇🔉🔊🔔🔕📣📢💬💭🗯♠♣♥♦🃏🎴🀄🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛")
        case .flags:
            return EmojiCatalog.flags(["KR", "JP", "CN", "TW", "HK", "US", "CA", "MX", "BR", "AR", "GB", "FR", "DE", "IT", "ES", "PT", "NL", "BE", "CH", "AT", "SE", "NO", "DK", "FI", "IS", "IE", "PL", "CZ", "HU", "GR", "TR", "RU", "UA", "IN", "TH", "VN", "PH", "ID", "MY", "SG", "AU", "NZ", "EG", "MA", "ZA", "KE", "AE", "SA", "IL", "MN", "NP", "PE", "CL", "CU"])
                + ["🏳", "🏴", "🏁", "🚩", "🏳️‍🌈"]
        }
    }
}

enum EmojiCatalog {
    /// 이어 붙인 이모지 문자열을 글자(자소 클러스터) 단위로 나눈다. 수식자 없는 기본형만 넣었다.
    /// 기본이 글자 모양인 기호(✌, ❤ 등)는 이모지 모양 선택자(U+FE0F)를 붙이고, 이모지가 아닌 글자는 뺀다
    static func split(_ text: String) -> [String] {
        text.compactMap { character in
            let scalars = character.unicodeScalars
            guard let first = scalars.first, first.properties.isEmoji, first.value > 0x7F else { return nil }
            if scalars.count == 1, !first.properties.isEmojiPresentation {
                return String(character) + "\u{FE0F}"
            }
            return String(character)
        }
    }

    /// ISO 국가 코드 → 국기 이모지 (지역 표시 문자 두 개)
    static func flags(_ codes: [String]) -> [String] {
        codes.map { code in
            String(String.UnicodeScalarView(code.unicodeScalars.compactMap { scalar in
                UnicodeScalar(127_397 + scalar.value)
            }))
        }
    }

    /// "R" 버튼이 고르는 무작위 이모지. 레거시 작성 화면과 같은 유니코드 구간에서 고른다
    static func randomEmoji() -> String {
        let ranges = [
            0x1f600...0x1f64f,
            0x1f680...0x1f6c5,
            0x1f6cb...0x1f6d2,
            0x1f6e0...0x1f6e5,
            0x1f6f3...0x1f6fa,
            0x1f7e0...0x1f7eb,
            0x1f90d...0x1f93a,
            0x1f93c...0x1f945,
            0x1f947...0x1f971,
            0x1f973...0x1f976,
            0x1f97a...0x1f9a2,
            0x1f9a5...0x1f9aa,
            0x1f9ae...0x1f9ca,
            0x1f9cd...0x1f9ff,
            0x1fa70...0x1fa73,
            0x1fa78...0x1fa7a,
            0x1fa80...0x1fa82,
            0x1fa90...0x1fa95
        ]
        let scalars = ranges.flatMap { $0 }.compactMap(UnicodeScalar.init)
        guard let scalar = scalars.randomElement() else { return "❓" }
        return String(scalar)
    }
}
