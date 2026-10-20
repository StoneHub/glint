import Foundation

/// GitHub-style `:shortcode:` → emoji, applied to prose runs in the preview only. The editor
/// keeps the literal text, and anything in inline code or a code block is left alone.
enum EmojiShortcodes {
    /// Replaces every `:name:` whose name is in the table; unknown names stay as typed.
    static func replacing(in text: String) -> String {
        guard text.contains(":") else { return text }
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            guard text[index] == ":" else {
                result.append(text[index])
                index = text.index(after: index)
                continue
            }
            let nameStart = text.index(after: index)
            var nameEnd = nameStart
            while nameEnd < text.endIndex, isNameCharacter(text[nameEnd]) {
                nameEnd = text.index(after: nameEnd)
            }
            if nameEnd > nameStart, nameEnd < text.endIndex, text[nameEnd] == ":",
               let emoji = table[String(text[nameStart..<nameEnd])] {
                result.append(emoji)
                index = text.index(after: nameEnd)
            } else {
                // Not a shortcode: keep the colon and let the next one start a fresh match.
                result.append(":")
                index = nameStart
            }
        }
        return result
    }

    private static func isNameCharacter(_ character: Character) -> Bool {
        character.isASCII && (character.isLowercase || character.isNumber || character == "_" || character == "+" || character == "-")
    }

    static let table: [String: String] = [
        // Faces
        "smile": "😄", "smiley": "😃", "grinning": "😀", "grin": "😁", "laughing": "😆", "satisfied": "😆",
        "joy": "😂", "rofl": "🤣", "sweat_smile": "😅", "wink": "😉", "blush": "😊", "innocent": "😇",
        "slightly_smiling_face": "🙂", "upside_down_face": "🙃", "relaxed": "☺️", "yum": "😋",
        "heart_eyes": "😍", "kissing_heart": "😘", "smiling_face_with_three_hearts": "🥰",
        "star_struck": "🤩", "stuck_out_tongue": "😛", "stuck_out_tongue_winking_eye": "😜",
        "stuck_out_tongue_closed_eyes": "😝", "zany_face": "🤪", "thinking": "🤔", "neutral_face": "😐",
        "expressionless": "😑", "no_mouth": "😶", "smirk": "😏", "unamused": "😒", "roll_eyes": "🙄",
        "grimacing": "😬", "relieved": "😌", "pensive": "😔", "sleepy": "😪", "sleeping": "😴",
        "mask": "😷", "nerd_face": "🤓", "sunglasses": "😎", "confused": "😕", "worried": "😟",
        "frowning_face": "☹️", "open_mouth": "😮", "hushed": "😯", "astonished": "😲", "flushed": "😳",
        "pleading_face": "🥺", "cry": "😢", "sob": "😭", "scream": "😱", "confounded": "😖",
        "persevere": "😣", "disappointed": "😞", "sweat": "😓", "weary": "😩", "tired_face": "😫",
        "rage": "😡", "pout": "😡", "angry": "😠", "cursing_face": "🤬", "exploding_head": "🤯",
        "partying_face": "🥳", "hugs": "🤗", "shushing_face": "🤫", "face_with_hand_over_mouth": "🤭",
        "monocle_face": "🧐", "yawning_face": "🥱", "woozy_face": "🥴", "nauseated_face": "🤢",
        "vomiting_face": "🤮", "sneezing_face": "🤧", "hot_face": "🥵", "cold_face": "🥶",
        "dizzy_face": "😵", "money_mouth_face": "🤑", "lying_face": "🤥", "cowboy_hat_face": "🤠",
        "kissing": "😗", "smiling_imp": "😈", "imp": "👿", "skull": "💀", "skull_and_crossbones": "☠️",
        "poop": "💩", "hankey": "💩", "shit": "💩", "clown_face": "🤡", "ghost": "👻", "alien": "👽",
        "robot": "🤖", "jack_o_lantern": "🎃",

        // Hands and people
        "+1": "👍", "thumbsup": "👍", "-1": "👎", "thumbsdown": "👎", "ok_hand": "👌", "wave": "👋",
        "raised_hand": "✋", "hand": "✋", "raised_back_of_hand": "🤚", "vulcan_salute": "🖖",
        "clap": "👏", "raised_hands": "🙌", "open_hands": "👐", "pray": "🙏", "handshake": "🤝",
        "muscle": "💪", "point_up": "☝️", "point_up_2": "👆", "point_down": "👇", "point_left": "👈",
        "point_right": "👉", "v": "✌️", "crossed_fingers": "🤞", "metal": "🤘", "call_me_hand": "🤙",
        "fist": "✊", "facepunch": "👊", "punch": "👊", "fist_left": "🤛", "fist_right": "🤜",
        "writing_hand": "✍️", "nail_care": "💅", "selfie": "🤳", "eyes": "👀", "eye": "👁️", "brain": "🧠",
        "ear": "👂", "nose": "👃", "tongue": "👅", "lips": "👄", "see_no_evil": "🙈", "hear_no_evil": "🙉",
        "speak_no_evil": "🙊", "shrug": "🤷", "man_shrugging": "🤷‍♂️", "woman_shrugging": "🤷‍♀️",
        "facepalm": "🤦", "man_facepalming": "🤦‍♂️", "woman_facepalming": "🤦‍♀️", "bow": "🙇",
        "raising_hand": "🙋", "person_raising_hand": "🙋", "no_good": "🙅", "ok_person": "🙆",
        "information_desk_person": "💁", "tipping_hand_person": "💁", "baby": "👶", "boy": "👦",
        "girl": "👧", "man": "👨", "woman": "👩", "older_man": "👴", "older_woman": "👵",
        "cop": "👮", "police_officer": "👮", "construction_worker": "👷", "detective": "🕵️",
        "santa": "🎅", "angel": "👼", "superhero": "🦸", "mage": "🧙", "zombie": "🧟",
        "technologist": "🧑‍💻", "man_technologist": "👨‍💻", "woman_technologist": "👩‍💻",
        "bust_in_silhouette": "👤", "busts_in_silhouette": "👥", "family": "👪", "couple": "👫",
        "dancer": "💃", "man_dancing": "🕺", "runner": "🏃", "running": "🏃", "walking": "🚶",

        // Hearts and feelings
        "heart": "❤️", "orange_heart": "🧡", "yellow_heart": "💛", "green_heart": "💚", "blue_heart": "💙",
        "purple_heart": "💜", "black_heart": "🖤", "white_heart": "🤍", "brown_heart": "🤎",
        "broken_heart": "💔", "two_hearts": "💕", "sparkling_heart": "💖", "heartpulse": "💗",
        "heartbeat": "💓", "revolving_hearts": "💞", "cupid": "💘", "gift_heart": "💝",
        "heart_decoration": "💟", "heavy_heart_exclamation": "❣️", "100": "💯", "anger": "💢",
        "boom": "💥", "collision": "💥", "dizzy": "💫", "sweat_drops": "💦", "dash": "💨", "zzz": "💤",
        "speech_balloon": "💬", "thought_balloon": "💭", "hole": "🕳️",

        // Symbols
        "white_check_mark": "✅", "heavy_check_mark": "✔️", "ballot_box_with_check": "☑️", "x": "❌",
        "negative_squared_cross_mark": "❎", "heavy_multiplication_x": "✖️", "heavy_plus_sign": "➕",
        "heavy_minus_sign": "➖", "heavy_division_sign": "➗", "o": "⭕", "question": "❓",
        "grey_question": "❔", "exclamation": "❗", "heavy_exclamation_mark": "❗", "grey_exclamation": "❕",
        "bangbang": "‼️", "interrobang": "⁉️", "warning": "⚠️", "no_entry": "⛔", "no_entry_sign": "🚫",
        "construction": "🚧", "recycle": "♻️", "radio_button": "🔘", "white_circle": "⚪",
        "black_circle": "⚫", "red_circle": "🔴", "large_blue_circle": "🔵", "green_circle": "🟢",
        "yellow_circle": "🟡", "orange_circle": "🟠", "purple_circle": "🟣", "brown_circle": "🟤",
        "red_square": "🟥", "green_square": "🟩", "blue_square": "🟦", "yellow_square": "🟨",
        "orange_square": "🟧", "purple_square": "🟪", "brown_square": "🟫", "white_large_square": "⬜",
        "black_large_square": "⬛", "small_blue_diamond": "🔹", "small_orange_diamond": "🔸",
        "large_blue_diamond": "🔷", "large_orange_diamond": "🔶", "small_red_triangle": "🔺",
        "small_red_triangle_down": "🔻", "arrow_right": "➡️", "arrow_left": "⬅️", "arrow_up": "⬆️",
        "arrow_down": "⬇️", "arrow_upper_right": "↗️", "arrow_lower_right": "↘️", "arrow_lower_left": "↙️",
        "arrow_upper_left": "↖️", "arrow_up_down": "↕️", "left_right_arrow": "↔️", "arrow_forward": "▶️",
        "arrow_backward": "◀️", "arrow_up_small": "🔼", "arrow_down_small": "🔽",
        "arrows_counterclockwise": "🔄", "arrows_clockwise": "🔃", "arrow_right_hook": "↪️",
        "leftwards_arrow_with_hook": "↩️", "repeat": "🔁", "repeat_one": "🔂", "fast_forward": "⏩",
        "rewind": "⏪", "play_or_pause_button": "⏯️", "pause_button": "⏸️", "stop_button": "⏹️",
        "record_button": "⏺️", "eject_button": "⏏️", "infinity": "♾️", "copyright": "©️",
        "registered": "®️", "tm": "™️", "hash": "#️⃣", "asterisk": "*️⃣", "zero": "0️⃣", "one": "1️⃣",
        "two": "2️⃣", "three": "3️⃣", "four": "4️⃣", "five": "5️⃣", "six": "6️⃣", "seven": "7️⃣",
        "eight": "8️⃣", "nine": "9️⃣", "keycap_ten": "🔟", "1234": "🔢", "capital_abcd": "🔠", "abcd": "🔡",
        "abc": "🔤", "symbols": "🔣", "new": "🆕", "free": "🆓", "ok": "🆗", "cool": "🆒", "up": "🆙",
        "sos": "🆘", "ng": "🆖", "id": "🆔", "vs": "🆚", "cl": "🆑", "ab": "🆎", "a": "🅰️", "b": "🅱️",
        "o2": "🅾️", "information_source": "ℹ️", "soon": "🔜", "top": "🔝", "back": "🔙", "end": "🔚",
        "on": "🔛", "underage": "🔞", "wavy_dash": "〰️", "curly_loop": "➰", "loop": "➿",
        "part_alternation_mark": "〽️", "eight_spoked_asterisk": "✳️", "eight_pointed_black_star": "✴️",
        "sparkle": "❇️", "wheelchair": "♿", "children_crossing": "🚸", "passport_control": "🛂",
        "checkered_flag": "🏁", "triangular_flag_on_post": "🚩", "crossed_flags": "🎌",
        "white_flag": "🏳️", "black_flag": "🏴", "rainbow_flag": "🏳️‍🌈",

        // Nature, weather, sky
        "star": "⭐", "star2": "🌟", "sparkles": "✨", "zap": "⚡", "fire": "🔥", "snowflake": "❄️",
        "sunny": "☀️", "cloud": "☁️", "partly_sunny": "⛅", "umbrella": "☔", "rainbow": "🌈",
        "ocean": "🌊", "droplet": "💧", "earth_americas": "🌎", "earth_africa": "🌍", "earth_asia": "🌏",
        "globe_with_meridians": "🌐", "new_moon": "🌑", "full_moon": "🌕", "crescent_moon": "🌙",
        "first_quarter_moon": "🌓", "last_quarter_moon": "🌗", "waxing_crescent_moon": "🌒",
        "seedling": "🌱", "herb": "🌿", "four_leaf_clover": "🍀", "evergreen_tree": "🌲",
        "deciduous_tree": "🌳", "palm_tree": "🌴", "cactus": "🌵", "sunflower": "🌻", "rose": "🌹",
        "tulip": "🌷", "cherry_blossom": "🌸", "blossom": "🌼", "hibiscus": "🌺", "maple_leaf": "🍁",
        "fallen_leaf": "🍂", "leaves": "🍃", "mushroom": "🍄", "mountain": "⛰️", "volcano": "🌋",

        // Animals
        "bug": "🐛", "ant": "🐜", "bee": "🐝", "honeybee": "🐝", "beetle": "🪲", "lady_beetle": "🐞",
        "spider": "🕷️", "snake": "🐍", "turtle": "🐢", "dog": "🐶", "cat": "🐱", "mouse": "🐭",
        "hamster": "🐹", "rabbit": "🐰", "fox_face": "🦊", "bear": "🐻", "panda_face": "🐼", "koala": "🐨",
        "tiger": "🐯", "lion": "🦁", "cow": "🐮", "pig": "🐷", "frog": "🐸", "monkey_face": "🐵",
        "monkey": "🐒", "chicken": "🐔", "penguin": "🐧", "bird": "🐦", "octopus": "🐙", "whale": "🐳",
        "dolphin": "🐬", "fish": "🐟", "unicorn": "🦄", "dragon": "🐉", "crab": "🦀", "butterfly": "🦋",
        "owl": "🦉", "duck": "🦆", "eagle": "🦅", "shark": "🦈", "horse": "🐴", "sheep": "🐑",
        "elephant": "🐘", "sloth": "🦥", "parrot": "🦜", "goat": "🐐", "wolf": "🐺", "camel": "🐫",
        "snail": "🐌", "squid": "🦑", "t-rex": "🦖", "sauropod": "🦕",

        // Food and drink
        "coffee": "☕", "tea": "🍵", "beer": "🍺", "beers": "🍻", "wine_glass": "🍷", "cocktail": "🍸",
        "tropical_drink": "🍹", "champagne": "🍾", "clinking_glasses": "🥂", "pizza": "🍕",
        "hamburger": "🍔", "fries": "🍟", "hotdog": "🌭", "taco": "🌮", "burrito": "🌯", "sushi": "🍣",
        "ramen": "🍜", "bento": "🍱", "apple": "🍎", "green_apple": "🍏", "banana": "🍌", "cherries": "🍒",
        "strawberry": "🍓", "lemon": "🍋", "watermelon": "🍉", "peach": "🍑", "grapes": "🍇",
        "avocado": "🥑", "eggplant": "🍆", "hot_pepper": "🌶️", "corn": "🌽", "bread": "🍞", "cheese": "🧀",
        "egg": "🥚", "bacon": "🥓", "cookie": "🍪", "doughnut": "🍩", "icecream": "🍦", "ice_cream": "🍨",
        "candy": "🍬", "lollipop": "🍭", "chocolate_bar": "🍫", "popcorn": "🍿", "cake": "🍰",
        "birthday": "🎂", "cupcake": "🧁", "pancakes": "🥞", "croissant": "🥐", "salad": "🥗",

        // Objects and tools
        "rocket": "🚀", "tada": "🎉", "confetti_ball": "🎊", "balloon": "🎈", "gift": "🎁",
        "trophy": "🏆", "medal_sports": "🏅", "medal_military": "🎖️", "1st_place_medal": "🥇",
        "2nd_place_medal": "🥈", "3rd_place_medal": "🥉", "crown": "👑", "gem": "💎", "bulb": "💡",
        "memo": "📝", "pencil": "📝", "pencil2": "✏️", "book": "📖", "books": "📚", "notebook": "📓",
        "blue_book": "📘", "green_book": "📗", "orange_book": "📙", "closed_book": "📕",
        "bookmark": "🔖", "bookmark_tabs": "📑", "page_facing_up": "📄", "page_with_curl": "📃",
        "scroll": "📜", "newspaper": "📰", "clipboard": "📋", "calendar": "📆", "date": "📅",
        "pushpin": "📌", "round_pushpin": "📍", "paperclip": "📎", "paperclips": "🖇️", "link": "🔗",
        "scissors": "✂️", "straight_ruler": "📏", "triangular_ruler": "📐", "bar_chart": "📊",
        "chart_with_upwards_trend": "📈", "chart_with_downwards_trend": "📉", "file_folder": "📁",
        "open_file_folder": "📂", "card_index_dividers": "🗂️", "card_file_box": "🗃️",
        "file_cabinet": "🗄️", "wastebasket": "🗑️", "lock": "🔒", "unlock": "🔓",
        "lock_with_ink_pen": "🔏", "closed_lock_with_key": "🔐", "key": "🔑", "old_key": "🗝️",
        "hammer": "🔨", "wrench": "🔧", "hammer_and_wrench": "🛠️", "gear": "⚙️", "nut_and_bolt": "🔩",
        "toolbox": "🧰", "magnet": "🧲", "pick": "⛏️", "axe": "🪓", "shield": "🛡️", "mag": "🔍",
        "mag_right": "🔎", "microscope": "🔬", "telescope": "🔭", "satellite": "📡", "computer": "💻",
        "desktop_computer": "🖥️", "keyboard": "⌨️", "computer_mouse": "🖱️", "printer": "🖨️",
        "floppy_disk": "💾", "cd": "💿", "dvd": "📀", "minidisc": "💽", "iphone": "📱", "phone": "☎️",
        "telephone": "☎️", "telephone_receiver": "📞", "pager": "📟", "fax": "📠", "email": "📧",
        "e-mail": "📧", "envelope": "✉️", "envelope_with_arrow": "📩", "incoming_envelope": "📨",
        "inbox_tray": "📥", "outbox_tray": "📤", "package": "📦", "mailbox": "📫", "postbox": "📮",
        "bell": "🔔", "no_bell": "🔕", "loudspeaker": "📢", "mega": "📣", "speaker": "🔈", "sound": "🔉",
        "loud_sound": "🔊", "mute": "🔇", "battery": "🔋", "electric_plug": "🔌", "flashlight": "🔦",
        "candle": "🕯️", "hourglass": "⌛", "hourglass_flowing_sand": "⏳", "watch": "⌚",
        "alarm_clock": "⏰", "stopwatch": "⏱️", "timer_clock": "⏲️", "clock1": "🕐", "clock12": "🕛",
        "money_with_wings": "💸", "dollar": "💵", "moneybag": "💰", "credit_card": "💳", "chart": "💹",
        "label": "🏷️", "ticket": "🎫", "art": "🎨", "clapper": "🎬", "movie_camera": "🎥", "camera": "📷",
        "camera_flash": "📸", "video_camera": "📹", "tv": "📺", "radio": "📻", "headphones": "🎧",
        "microphone": "🎤", "musical_note": "🎵", "notes": "🎶", "guitar": "🎸", "video_game": "🎮",
        "game_die": "🎲", "dart": "🎯", "jigsaw": "🧩", "test_tube": "🧪", "alembic": "⚗️", "dna": "🧬",
        "pill": "💊", "syringe": "💉", "stethoscope": "🩺", "adhesive_bandage": "🩹", "thread": "🧵",
        "bricks": "🧱", "necktie": "👔", "lipstick": "💄", "safety_vest": "🦺", "coffin": "⚰️",
        "rotating_light": "🚨", "ambulance": "🚑", "fire_engine": "🚒", "police_car": "🚓",
        "goal_net": "🥅", "crystal_ball": "🔮", "bomb": "💣", "gun": "🔫",
        "knife": "🔪", "hocho": "🔪", "trident": "🔱", "fleur_de_lis": "⚜️", "beginner": "🔰",
        "name_badge": "📛", "vibration_mode": "📳", "mobile_phone_off": "📴", "cinema": "🎦",
        "signal_strength": "📶", "currency_exchange": "💱", "heavy_dollar_sign": "💲",
        "atom_symbol": "⚛️", "balance_scale": "⚖️", "chains": "⛓️", "placard": "🪧",

        // Places and transport
        "house": "🏠", "house_with_garden": "🏡", "office": "🏢", "hospital": "🏥", "bank": "🏦",
        "school": "🏫", "church": "⛪", "building_construction": "🏗️", "statue_of_liberty": "🗽",
        "tokyo_tower": "🗼", "world_map": "🗺️", "compass": "🧭", "camping": "🏕️", "beach_umbrella": "🏖️",
        "desert": "🏜️", "car": "🚗", "red_car": "🚗", "taxi": "🚕", "bus": "🚌", "truck": "🚚",
        "bike": "🚲", "airplane": "✈️", "helicopter": "🚁", "ship": "🚢", "sailboat": "⛵", "train": "🚋",
        "bullettrain_front": "🚅", "traffic_light": "🚥", "vertical_traffic_light": "🚦",
        "stop_sign": "🛑", "construction_worker_man": "👷‍♂️", "anchor": "⚓", "fuelpump": "⛽",

        // Sport and activity
        "soccer": "⚽", "basketball": "🏀", "football": "🏈", "baseball": "⚾", "tennis": "🎾",
        "volleyball": "🏐", "golf": "⛳", "ski": "🎿", "swimmer": "🏊", "surfer": "🏄", "bicyclist": "🚴",
        "8ball": "🎱", "bowling": "🎳", "weight_lifting": "🏋️", "mountain_bicyclist": "🚵",
        "sparkler": "🎇", "fireworks": "🎆", "christmas_tree": "🎄", "performing_arts": "🎭",
        "circus_tent": "🎪", "ribbon": "🎀", "wind_chime": "🎐",
    ]
}
