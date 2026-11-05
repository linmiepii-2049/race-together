extends RefCounted

const CHAPTERS: Array = [
	{
		"title": "第一章・地下迴廊",
		"goal": 7200.0,
		"wave": "tutorial",
		"boss": false,
		"tutorial": true,
	},
	{
		"title": "第二章・霓虹高架",
		"goal": 10800.0,
		"wave": "city",
		"boss": false,
		"tutorial": false,
	},
	{
		"title": "第三章・鷹巢",
		"goal": 9600.0,
		"wave": "boss",
		"boss": true,
		"tutorial": false,
	},
]

const OPENING: Array = [
	{
		"speaker": "旁白",
		"panel": 0,
		"text": "地下霓虹城不承認白天。法律只剩一條迴廊，而你的車隊在終點前被整隊劫走。",
	},
	{
		"speaker": "霓虹狐・緋",
		"panel": 1,
		"text": "嵐，人在我劃的光裡。想把車隊要回去，就從這條迴廊活著開出來。",
	},
	{
		"speaker": "鐵軌男爵・鋼",
		"panel": 2,
		"text": "高架不留退路。擦得夠近才叫本事，擦太近就只剩零件。",
	},
	{
		"speaker": "電壓鷹・隼",
		"panel": 3,
		"text": "是我下的手。最後一章，獵鷹無人機會咬住你的車尾。贏了，他們跟你走。",
	},
]

const INTERLUDES: Array = [
	[
		{"speaker": "嵐", "panel": 0, "text": "迴廊的呼吸我摸到了。車隊的燈還在前面。"},
		{"speaker": "霓虹狐・緋", "panel": 1, "text": "摸到不算過關。高架上見，別指望我讓路。"},
	],
	[
		{"speaker": "鐵軌男爵・鋼", "panel": 2, "text": "鷹在上面等。金幣留著，車漆有時比護盾誠實。"},
		{"speaker": "電壓鷹・隼", "panel": 3, "text": "上來。我的無人機不吃藉口。"},
	],
]

const ENDING: Array = [
	{
		"speaker": "旁白",
		"panel": 3,
		"text": "獵鷹墜進霓虹。被劫走的車燈一盞盞重新點亮。",
	},
	{
		"speaker": "嵐",
		"panel": 0,
		"text": "車隊回來了。下一趟，換我們帶路。",
	},
]

const HINTS: Array = [
	{"at": 0.0, "text": "教學：A／D 或方向鍵左右閃避。"},
	{"at": 1600.0, "text": "按住空白鍵漂移，氮氣槽會累積；滿槽按 Shift 噴射。"},
	{"at": 3400.0, "text": "貼著障礙擦過可拿近失分，短時間內再擦會堆連擊。"},
	{"at": 5200.0, "text": "收集金幣。回主選單的設定可以解鎖車色。"},
]


static func chapter_count() -> int:
	return CHAPTERS.size()


static func chapter(index: int) -> Dictionary:
	return CHAPTERS[index]


static func opening_lines() -> Array:
	return OPENING


static func interlude_lines(cleared_index: int) -> Array:
	return INTERLUDES[cleared_index]


static func ending_lines() -> Array:
	return ENDING


static func tutorial_hints() -> Array:
	return HINTS
