class_name MochiCatalog
extends RefCounted

const GAMES := [
	["fruit_drop", "Fruit Drop", "水果合成", "Drop a little joy", "投下一颗小快乐", "Drag to aim. Release to drop. Matching fruit merges; keep the pile below the dotted line.", "拖动瞄准，松手投放。同级水果会合成，别让水果堆超过虚线。"],
	["bubble_garden", "Bubble Garden", "泡泡花园", "Pop & let go", "瞄准，消除，放轻松", "Drag to aim, then release. Match three colors. Bubbles disconnected from the roof fall away.", "拖动瞄准，松手发射。三个同色泡泡消除，不连接顶部的泡泡会掉落。"],
	["cake_stack", "Cake Stack", "蛋糕高塔", "One sweet layer", "再叠一层甜蜜", "Tap to place the moving cake. Line up the edges: a perfect layer keeps your cake wide!", "点击放下移动的蛋糕。对准边缘，完美叠放能保留全部宽度！"],
	["bouncy_balls", "Bouncy Balls", "弹珠派对", "Catch a happy bounce", "接住快乐的弹跳", "Drag the paddle to catch your balls. Hit bricks and send balls through multiplier gates.", "拖动挡板接住弹珠。击碎砖块，穿过倍增门，变出更多弹珠。"],
	["tile_trio", "Tile Trio", "三三小铺", "Find your little trio", "找到你的三件套", "Tap uncovered tiles. Three matching tiles clear the tray. Keep room in your seven-slot tray.", "点击未被遮挡的图块，三个相同图案会消除。托盘只有七格，请留出空位。"],
	["mochi_hop", "Mochi Hop", "麻薯跳跳乐", "A tiny leap of joy", "蓄一点力，跳一点远", "Hold to squish, release to hop. A longer hold jumps farther. Aim for the center of the next sweet!", "按住蓄力，松手起跳。按得越久跳得越远。试着落在下一块甜点的中心！"],
	["number_bloom", "Number Bloom", "数字花园", "Make room to bloom", "合并数字，慢慢绽放", "Swipe in any direction. Equal numbers merge once per move. Grow a 2048 tile, then keep going.", "上下左右滑动，相同数字每步合并一次。合出 2048 后可以继续挑战。"],
	["jelly_slice", "Jelly Slice", "果冻切切", "Slice into a softer day", "划开一份轻松", "Swipe through the jelly fruit. Fast swipes count too. No bombs, no hurry: enjoy your Zen break.", "滑动切开果冻水果，快速划过也有效。没有炸弹和倒计时，享受轻松的禅意时光。"]
]

static func words(en: String, zh: String) -> String:
	return zh if Save.setting("language") == "zh" else en

static func title(index: int) -> String:
	return str(GAMES[index][2 if Save.setting("language") == "zh" else 1])

static func subtitle(index: int) -> String:
	return str(GAMES[index][4 if Save.setting("language") == "zh" else 3])

static func help(index: int) -> String:
	return str(GAMES[index][6 if Save.setting("language") == "zh" else 5])
