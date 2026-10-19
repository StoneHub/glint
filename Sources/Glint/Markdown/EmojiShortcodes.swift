import Foundation

/// GitHub-style `:shortcode:` emoji for the preview. The table covers the common names;
/// anything not in it stays literal, as on GitHub.
enum EmojiShortcodes {
    /// Replaces every `:name:` in `text` that names a known emoji, leaving inline code alone.
    /// Replacing through the characters view keeps the surrounding run's attributes, so an
    /// emoji inside bold text or a link stays bold or linked.
    static func replace(in text: inout AttributedString) {
        var replacements: [(Range<AttributedString.Index>, String)] = []
        for run in text.runs where run.inlinePresentationIntent?.contains(.code) != true {
            replacements += matches(in: text.characters, within: run.range)
        }
        for (range, emoji) in replacements.reversed() {
            text.characters.replaceSubrange(range, with: emoji)
        }
    }

    /// Scans for `:name:` where the name is made of shortcode characters. A colon that fails
    /// to close a name may still open the next one, so `:x:tada:` finds `:tada:`.
    private static func matches(
        in characters: AttributedString.CharacterView, within range: Range<AttributedString.Index>
    ) -> [(Range<AttributedString.Index>, String)] {
        var found: [(Range<AttributedString.Index>, String)] = []
        var opener: AttributedString.Index?
        var cursor = range.lowerBound
        while cursor < range.upperBound {
            let character = characters[cursor]
            let next = characters.index(after: cursor)
            if character == ":" {
                if let start = opener, let emoji = table[String(characters[characters.index(after: start)..<cursor])] {
                    found.append((start..<next, emoji))
                    opener = nil
                } else {
                    opener = cursor
                }
            } else if !isShortcodeCharacter(character) {
                opener = nil
            }
            cursor = next
        }
        return found
    }

    private static func isShortcodeCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_" || character == "+" || character == "-"
    }

    static let table: [String: String] = [
        "+1": "👍", "-1": "👎", "100": "💯", "1234": "🔢", "8ball": "🎱", "abacus": "🧮", "abc": "🔤",
        "adhesive_bandage": "🩹", "airplane": "✈️", "alarm_clock": "⏰", "alembic": "⚗️",
        "alien": "👽", "ambulance": "🚑", "anchor": "⚓", "angel": "👼", "anger": "💢", "angry": "😠",
        "anguished": "😧", "ant": "🐜", "apple": "🍎", "arrow_backward": "◀️", "arrow_down": "⬇️",
        "arrow_down_small": "🔽", "arrow_forward": "▶️", "arrow_left": "⬅️",
        "arrow_lower_left": "↙️", "arrow_lower_right": "↘️", "arrow_right": "➡️",
        "arrow_right_hook": "↪️", "arrow_up": "⬆️", "arrow_up_down": "↕️", "arrow_up_small": "🔼",
        "arrow_upper_left": "↖️", "arrow_upper_right": "↗️", "arrows_clockwise": "🔃",
        "arrows_counterclockwise": "🔄", "art": "🎨", "astonished": "😲", "atom_symbol": "⚛️",
        "avocado": "🥑", "axe": "🪓", "baby": "👶", "baby_chick": "🐤", "back": "🔙", "bacon": "🥓",
        "balloon": "🎈", "ballot_box": "🗳️", "ballot_box_with_check": "☑️", "bamboo": "🎍",
        "banana": "🍌", "bangbang": "‼️", "bar_chart": "📊", "baseball": "⚾", "basketball": "🏀",
        "bat": "🦇", "bathtub": "🛁", "battery": "🔋", "bear": "🐻", "bed": "🛏️", "bee": "🐝",
        "beer": "🍺", "beers": "🍻", "beetle": "🐞", "bell": "🔔", "bento": "🍱", "bike": "🚲",
        "bird": "🐦", "birthday": "🎂", "black_circle": "⚫", "black_heart": "🖤",
        "black_large_square": "⬛", "black_medium_square": "◼️", "black_nib": "✒️",
        "black_small_square": "▪️", "blossom": "🌼", "blowfish": "🐡", "blue_book": "📘",
        "blue_heart": "💙", "blue_square": "🟦", "blush": "😊", "bomb": "💣", "book": "📖",
        "bookmark": "🔖", "bookmark_tabs": "📑", "books": "📚", "boom": "💥", "bouquet": "💐",
        "bow": "🙇", "bow_and_arrow": "🏹", "boy": "👦", "brain": "🧠", "bread": "🍞", "bricks": "🧱",
        "bridge_at_night": "🌉", "briefcase": "💼", "broken_heart": "💔", "broom": "🧹", "bug": "🐛",
        "bulb": "💡", "burrito": "🌯", "bus": "🚌", "bust_in_silhouette": "👤",
        "busts_in_silhouette": "👥", "butterfly": "🦋", "cactus": "🌵", "cake": "🍰", "calendar": "📅",
        "call_me_hand": "🤙", "camel": "🐫", "camera": "📷", "camera_flash": "📸", "candle": "🕯️",
        "candy": "🍬", "car": "🚗", "card_index_dividers": "🗂️", "cat": "🐱", "cd": "💿", "chair": "🪑",
        "champagne": "🍾", "chart_with_downwards_trend": "📉", "chart_with_upwards_trend": "📈",
        "checkered_flag": "🏁", "cheese": "🧀", "cherries": "🍒", "cherry_blossom": "🌸",
        "chicken": "🐔", "children_crossing": "🚸", "chocolate_bar": "🍫", "christmas_tree": "🎄",
        "city_sunset": "🌇", "clap": "👏", "clapper": "🎬", "clipboard": "📋", "clock1": "🕐",
        "clock10": "🕙", "clock11": "🕚", "clock12": "🕛", "clock2": "🕑", "clock3": "🕒",
        "clock4": "🕓", "clock5": "🕔", "clock6": "🕕", "clock7": "🕖", "clock8": "🕗", "clock9": "🕘",
        "closed_book": "📕", "closed_lock_with_key": "🔐", "cloud": "☁️",
        "cloud_with_lightning": "⛈️", "cloud_with_rain": "🌧️", "clown_face": "🤡", "cocktail": "🍸",
        "coffee": "☕", "coffin": "⚰️", "cold_face": "🥶", "cold_sweat": "😰", "collision": "💥",
        "comet": "☄️", "compass": "🧭", "computer": "💻", "confetti_ball": "🎊", "confounded": "😖",
        "confused": "😕", "construction": "🚧", "construction_worker": "👷", "cookie": "🍪",
        "cool": "🆒", "cop": "👮", "copyright": "©️", "couch_and_lamp": "🛋️", "couple": "👫",
        "cow": "🐮", "cowboy_hat_face": "🤠", "crab": "🦀", "crayon": "🖍️", "credit_card": "💳",
        "crescent_moon": "🌙", "crossed_fingers": "🤞", "crossed_swords": "⚔️", "crown": "👑",
        "cry": "😢", "crystal_ball": "🔮", "cupid": "💘", "curly_loop": "➰", "dagger": "🗡️",
        "dancer": "💃", "dart": "🎯", "dash": "💨", "date": "📅", "deciduous_tree": "🌳",
        "desktop_computer": "🖥️", "detective": "🕵️", "disappointed": "😞",
        "disappointed_relieved": "😥", "dizzy": "💫", "dizzy_face": "😵", "dna": "🧬", "dog": "🐶",
        "dollar": "💵", "dolls": "🎎", "dolphin": "🐬", "door": "🚪", "doughnut": "🍩", "dragon": "🐉",
        "drooling_face": "🤤", "droplet": "💧", "drum": "🥁", "duck": "🦆", "dvd": "📀", "eagle": "🦅",
        "ear": "👂", "earth_africa": "🌍", "earth_americas": "🌎", "earth_asia": "🌏", "egg": "🥚",
        "eight": "8️⃣", "eight_pointed_black_star": "✴️", "eight_spoked_asterisk": "✳️",
        "electric_plug": "🔌", "elephant": "🐘", "email": "📧", "end": "🔚", "envelope": "✉️",
        "evergreen_tree": "🌲", "exclamation": "❗", "exploding_head": "🤯", "expressionless": "😑",
        "eye": "👁️", "eyeglasses": "👓", "eyes": "👀", "face_with_hand_over_mouth": "🤭",
        "face_with_head_bandage": "🤕", "face_with_thermometer": "🤒", "facepalm": "🤦",
        "facepunch": "👊", "fallen_leaf": "🍂", "family": "👪", "fast_forward": "⏩", "fearful": "😨",
        "female_sign": "♀️", "file_cabinet": "🗄️", "file_folder": "📁", "fire": "🔥",
        "fire_extinguisher": "🧯", "fireworks": "🎆", "first_place_medal": "🥇",
        "first_quarter_moon": "🌓", "fish": "🐟", "fist": "✊", "five": "5️⃣", "flags": "🎏",
        "flashlight": "🔦", "floppy_disk": "💾", "flushed": "😳", "fog": "🌫️", "football": "🏈",
        "fountain_pen": "🖋️", "four": "4️⃣", "four_leaf_clover": "🍀", "fox_face": "🦊", "free": "🆓",
        "fries": "🍟", "frog": "🐸", "frowning": "😦", "full_moon": "🌕", "game_die": "🎲",
        "gear": "⚙️", "gem": "💎", "ghost": "👻", "gift": "🎁", "gift_heart": "💝", "giraffe": "🦒",
        "girl": "👧", "globe_with_meridians": "🌐", "goal_net": "🥅", "goat": "🐐", "gorilla": "🦍",
        "grapes": "🍇", "green_apple": "🍏", "green_book": "📗", "green_circle": "🟢",
        "green_heart": "💚", "green_square": "🟩", "grey_exclamation": "❕", "grey_question": "❔",
        "grimacing": "😬", "grin": "😁", "grinning": "😀", "guitar": "🎸", "hamburger": "🍔",
        "hammer": "🔨", "hammer_and_wrench": "🛠️", "hamster": "🐹", "hand": "✋", "handshake": "🤝",
        "hankey": "💩", "hash": "#️⃣", "hatching_chick": "🐣", "headphones": "🎧",
        "hear_no_evil": "🙉", "heart": "❤️", "heart_eyes": "😍", "heart_eyes_cat": "😻",
        "heartbeat": "💓", "heartpulse": "💗", "heavy_check_mark": "✔️", "heavy_division_sign": "➗",
        "heavy_dollar_sign": "💲", "heavy_exclamation_mark": "❗", "heavy_minus_sign": "➖",
        "heavy_multiplication_x": "✖️", "heavy_plus_sign": "➕", "hedgehog": "🦔", "herb": "🌿",
        "hibiscus": "🌺", "honeybee": "🐝", "horse": "🐴", "hospital": "🏥", "hot_face": "🥵",
        "hotdog": "🌭", "hotsprings": "♨️", "hourglass": "⌛",
        "hourglass_flowing_sand": "⏳", "house": "🏠", "hugs": "🤗", "hushed": "😯", "icecream": "🍦",
        "id": "🆔", "imp": "👿", "inbox_tray": "📥", "infinity": "♾️", "information_desk_person": "💁",
        "information_source": "ℹ️", "innocent": "😇", "interrobang": "⁉️", "iphone": "📱",
        "jack_o_lantern": "🎃", "jigsaw": "🧩", "joy": "😂", "key": "🔑", "keyboard": "⌨️",
        "keycap_ten": "🔟", "kissing": "😗", "kissing_closed_eyes": "😚", "kissing_heart": "😘",
        "kissing_smiling_eyes": "😙", "knife": "🔪", "koala": "🐨", "label": "🏷️",
        "large_blue_circle": "🔵", "large_blue_diamond": "🔷", "large_orange_diamond": "🔶",
        "last_quarter_moon": "🌗", "laughing": "😆", "leaves": "🍃", "ledger": "📒",
        "left_right_arrow": "↔️", "leftwards_arrow_with_hook": "↩️", "lemon": "🍋", "link": "🔗",
        "lion": "🦁", "lips": "👄", "lipstick": "💄", "lizard": "🦎", "lock": "🔒",
        "lock_with_ink_pen": "🔏", "lollipop": "🍭", "loop": "➿", "loud_sound": "🔊",
        "loudspeaker": "📢", "lying_face": "🤥", "mag": "🔍", "mag_right": "🔎", "magnet": "🧲",
        "mailbox": "📫", "male_sign": "♂️", "man": "👨", "man_technologist": "👨‍💻",
        "maple_leaf": "🍁", "mask": "😷", "medal": "🏅", "medal_military": "🎖️", "medal_sports": "🏅",
        "mega": "📣", "memo": "📝", "metal": "🤘", "microbe": "🦠", "microphone": "🎤",
        "microscope": "🔬", "milky_way": "🌌", "mobile_phone_off": "📴", "money_mouth_face": "🤑",
        "money_with_wings": "💸", "moneybag": "💰", "monkey": "🐒", "monkey_face": "🐵",
        "monocle_face": "🧐", "moon": "🌔", "mortar_board": "🎓", "mountain": "⛰️", "mouse": "🐭",
        "movie_camera": "🎥", "moyai": "🗿", "muscle": "💪", "mushroom": "🍄", "musical_keyboard": "🎹",
        "musical_note": "🎵", "musical_score": "🎼", "mute": "🔇", "nauseated_face": "🤢",
        "necktie": "👔", "negative_squared_cross_mark": "❎", "nerd_face": "🤓", "neutral_face": "😐",
        "new": "🆕", "new_moon": "🌑", "newspaper": "📰", "night_with_stars": "🌃", "nine": "9️⃣",
        "no_bell": "🔕", "no_entry": "⛔", "no_entry_sign": "🚫", "no_good": "🙅", "no_mouth": "😶",
        "nose": "👃", "notebook": "📓", "notes": "🎶", "nut_and_bolt": "🔩", "ocean": "🌊",
        "octopus": "🐙", "office": "🏢", "ok": "🆗", "ok_hand": "👌", "ok_woman": "🙆",
        "old_key": "🗝️", "on": "🔛", "one": "1️⃣", "open_file_folder": "📂", "open_hands": "👐",
        "open_mouth": "😮", "orange_book": "📙", "orange_circle": "🟠", "orange_heart": "🧡",
        "orange_square": "🟧", "otter": "🦦", "outbox_tray": "📤", "owl": "🦉", "package": "📦",
        "page_facing_up": "📄", "page_with_curl": "📃", "paintbrush": "🖌️", "palm_tree": "🌴",
        "panda_face": "🐼", "paperclip": "📎", "parrot": "🦜", "partly_sunny": "⛅",
        "partying_face": "🥳", "passport_control": "🛂", "pause_button": "⏸️", "peace_symbol": "☮️",
        "peach": "🍑", "pen": "🖊️", "pencil": "📝", "pencil2": "✏️", "penguin": "🐧", "pensive": "😔",
        "performing_arts": "🎭", "persevere": "😣", "petri_dish": "🧫", "phone": "☎️", "pig": "🐷",
        "pill": "💊", "pineapple": "🍍", "pizza": "🍕", "pleading_face": "🥺", "point_down": "👇",
        "point_left": "👈", "point_right": "👉", "point_up": "☝️", "point_up_2": "👆", "poop": "💩",
        "popcorn": "🍿", "pray": "🙏", "printer": "🖨️", "punch": "👊", "purple_circle": "🟣",
        "purple_heart": "💜", "purple_square": "🟪", "pushpin": "📌", "question": "❓", "rabbit": "🐰",
        "radio": "📻", "radio_button": "🔘", "rage": "😡", "rainbow": "🌈", "raised_eyebrow": "🤨",
        "raised_hand": "✋", "raised_hands": "🙌", "raising_hand": "🙋", "record_button": "⏺️",
        "recycle": "♻️", "red_car": "🚗", "red_circle": "🔴", "red_square": "🟥", "registered": "®️",
        "relaxed": "☺️", "relieved": "😌", "reminder_ribbon": "🎗️", "repeat": "🔁",
        "revolving_hearts": "💞", "rewind": "⏪", "ribbon": "🎀", "rice_scene": "🎑",
        "ringed_planet": "🪐", "robot": "🤖", "rocket": "🚀", "rofl": "🤣", "roll_eyes": "🙄",
        "rose": "🌹", "rotating_light": "🚨", "round_pushpin": "📍", "runner": "🏃", "running": "🏃",
        "safety_pin": "🧷", "safety_vest": "🦺", "santa": "🎅", "satellite": "🛰️", "satisfied": "😆",
        "sauropod": "🦕", "saxophone": "🎷", "school": "🏫", "scissors": "✂️", "scream": "😱",
        "scroll": "📜", "second_place_medal": "🥈", "see_no_evil": "🙈", "seedling": "🌱",
        "seven": "7️⃣", "shamrock": "☘️", "shark": "🦈", "sheep": "🐑", "shield": "🛡️", "ship": "🚢",
        "shirt": "👕", "shit": "💩", "shopping": "🛍️", "shopping_cart": "🛒", "shower": "🚿",
        "shrimp": "🦐", "shrug": "🤷", "shushing_face": "🤫", "signal_strength": "📶", "six": "6️⃣",
        "skull": "💀", "skull_and_crossbones": "☠️", "sleeping": "😴", "sleepy": "😪",
        "slightly_frowning_face": "🙁", "slightly_smiling_face": "🙂", "sloth": "🦥",
        "small_blue_diamond": "🔹", "small_orange_diamond": "🔸", "small_red_triangle": "🔺",
        "small_red_triangle_down": "🔻", "smile": "😄", "smile_cat": "😸", "smiley": "😃",
        "smiley_cat": "😺", "smiling_imp": "😈", "smirk": "😏", "snail": "🐌", "snake": "🐍",
        "sneezing_face": "🤧", "snowflake": "❄️", "snowman": "⛄", "soap": "🧼", "sob": "😭",
        "soccer": "⚽", "soon": "🔜", "sos": "🆘", "sound": "🔉", "sparkle": "❇️", "sparkler": "🎇",
        "sparkles": "✨", "sparkling_heart": "💖", "speak_no_evil": "🙊", "speaker": "🔈",
        "speech_balloon": "💬", "spiral_notepad": "🗒️", "sponge": "🧽", "squid": "🦑", "star": "⭐",
        "star2": "🌟", "star_struck": "🤩", "stethoscope": "🩺", "stop_button": "⏹️",
        "stopwatch": "⏱️", "straight_ruler": "📏", "strawberry": "🍓", "stuck_out_tongue": "😛",
        "stuck_out_tongue_closed_eyes": "😝", "stuck_out_tongue_winking_eye": "😜",
        "sun_with_face": "🌞", "sunflower": "🌻", "sunglasses": "😎", "sunny": "☀️", "sunrise": "🌅",
        "sweat": "😓", "sweat_drops": "💦", "sweat_smile": "😅", "syringe": "💉", "t-rex": "🦖",
        "taco": "🌮", "tada": "🎉", "tanabata_tree": "🎋", "tangerine": "🍊", "taxi": "🚕", "tea": "🍵",
        "technologist": "🧑‍💻", "teddy_bear": "🧸", "telephone": "☎️", "telescope": "🔭",
        "tennis": "🎾", "test_tube": "🧪", "thinking": "🤔", "third_place_medal": "🥉",
        "thought_balloon": "💭", "thread": "🧵", "three": "3️⃣", "thumbsdown": "👎", "thumbsup": "👍",
        "ticket": "🎫", "tickets": "🎟️", "tiger": "🐯", "timer_clock": "⏲️", "tired_face": "😫",
        "tm": "™️", "toilet": "🚽", "tongue": "👅", "toolbox": "🧰", "top": "🔝", "tornado": "🌪️",
        "train": "🚆", "triangular_flag_on_post": "🚩", "triangular_ruler": "📐", "triumph": "😤",
        "trophy": "🏆", "tropical_drink": "🍹", "tropical_fish": "🐠", "truck": "🚚", "trumpet": "🎺",
        "tshirt": "👕", "tulip": "🌷", "turtle": "🐢", "tv": "📺", "twisted_rightwards_arrows": "🔀",
        "two": "2️⃣", "two_hearts": "💕", "umbrella": "☔", "unamused": "😒", "unicorn": "🦄",
        "unlock": "🔓", "up": "🆙", "upside_down_face": "🙃", "v": "✌️", "vibration_mode": "📳",
        "video_camera": "📹", "video_game": "🎮", "violin": "🎻", "volcano": "🌋", "vs": "🆚",
        "walking": "🚶", "waning_crescent_moon": "🌘", "waning_gibbous_moon": "🌖", "warning": "⚠️",
        "wastebasket": "🗑️", "watch": "⌚", "watermelon": "🍉", "wave": "👋", "wavy_dash": "〰️",
        "waxing_crescent_moon": "🌒", "weary": "😩", "whale": "🐳", "whale2": "🐋", "wheelchair": "♿",
        "white_check_mark": "✅", "white_circle": "⚪", "white_flower": "💮", "white_heart": "🤍",
        "white_large_square": "⬜", "white_medium_square": "◻️", "white_small_square": "▫️",
        "wind_chime": "🎐", "wind_face": "🌬️", "window": "🪟", "wine_glass": "🍷", "wink": "😉",
        "wolf": "🐺", "woman": "👩", "woman_technologist": "👩‍💻", "woozy_face": "🥴",
        "world_map": "🗺️", "worried": "😟", "wrench": "🔧", "writing_hand": "✍️", "x": "❌",
        "yarn": "🧶", "yawning_face": "🥱", "yellow_circle": "🟡", "yellow_heart": "💛",
        "yellow_square": "🟨", "yin_yang": "☯️", "yum": "😋", "zap": "⚡", "zebra": "🦓",
        "zero": "0️⃣", "zipper_mouth_face": "🤐", "zzz": "💤",
    ]
}
