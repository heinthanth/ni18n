# ni18n ( nim + i18n )

Super Fast Nim Macros For Internationalization and Localization. It can prevent missing locales, duplicated translation names and invalid string interpolation at compile-time. But implementation is super simple!

I was attempting to create a programming language in our local language ( Myanmar ) and I realized that I need to develop interpreter with multi-language approach because terminals can't render our language properly and I need to use English until I have a proper custom monospace font. This is the main motivation of creating this package.

## Installation

You can add package name or repo URL to `.nimble` file

```nim
requires "ni18n >= 0.1.0"
```

## Quick Start

Super simple, Super Fast. No runtime lookup for translation: all translations are compiled down to Nim functions ( except we still have a runtime `case` statement for `locale` to call locale-suffixed function we generated - see [Behind The Scene](#behind-the-scene) )

```nim
import ni18n

type
    Locale = enum
        English
        Chinese
        Myanmar

i18nInit Locale, true:
    hello:
        # translations can be string literal
        English = "Hello, $name!"
        Chinese = "你好, $name!"
        Myanmar = "မင်္ဂလာပါ၊ $name ရေ။"
    ihaveCat:
        English = "I've many cats."
        Chinese = "我有很多小猫。"
        Myanmar = "ငါ့ဆီမှာ ကြောင် အများကြီးရှိတယ်။"
        # translation definition can have sub-translation definition
        withCount:
            # translations can be lambda / closure
            English = proc(count: int): string =
                case count
                of 0: "I don't have a cat."
                of 1: "I have one cat."
                else: "I have " & $count & " cats."
            Chinese = proc(count: int): string =
                proc translateCount(count: int): string =
                    case count
                    of 2: "二"
                    of 3: "三"
                    of 4: "四"
                    of 5: "五"
                    else: $count # so on ...

                return case count
                    of 0: "我没有猫。"
                    of 1: "我有一只猫。"
                    else: "我有" & translateCount(count) & "只猫。"
            Myanmar = proc(count: int): string =
                proc translateCount(count: int): string =
                    case count
                    of 2: "နှစ်"
                    of 3: "သုံး"
                    of 4: "လေး"
                    of 5: "ငါး"
                    else: $count # so on ...

                return case count
                    of 0: "ငါ့မှာ ကြောင်တစ်ကောင်မှ မရှိဘူး။"
                    of 1: "ငါ့မှာ ကြောင်တစ်ကောင် ရှိတယ်။"
                    else: "ငါ့မှာ ကြောင်" & translateCount(count) & "ကောင် ရှိတယ်။"

# prints "你好, 黄小姐!". This function behave the same as `strutils.format`
echo hello(Chinese, "name", "黄小姐")

# prints 我有猫
echo ihaveCat(Chinese)

# prints 我有五只猫
echo ihaveCat_withCount(Chinese, 5)

# or like this ( because Nim compiler is smart! )
echo ihaveCatWithCount(Chinese, 5)

# print ငါ့မှာ ကြောင်သုံးကောင် ရှိတယ်။"
echo ihaveCatWithCount(Myanmar, 3)

# compiler error here since each function is generated with the same signature from lambda
echo ihaveCat_withCount(Chinese, "some str") 
```

## Behind the Scene

Imagine u write this code:

```nim
type
    Locale = enum
        English
        Chinese

i18nInit Locale, true:
    hello:
        English = "Hello, $name!"
        Chinese = "你好, $name!"
```

Magic macro will convert that code into this:

```nim
type
    Locale = enum
        English
        Chinese

proc hello_English(args: varargs[string, `$`]): string {.inline.} =
    format("Hello, $name!", args)

proc hello_Chinese(args: varargs[string, `$`]): string {.inline.} =
    format("你好, $name!", args)

proc hello*(locale: Locale, args: varargs[string, `$`]): string {.inline.} =
    case locale
    of English: hello_English(args)
    of Chinese: hello_Chinese(args)
```

So, we have just locale runtime check, but since that's enum, we're still going fast!

## Roadmap / Todos

- [ ] set locale at compile time for multiple ( single locale ) binaries
- [ ] write extensive test cases

## Contribution and Other

Contributions, Ideas are welcome! For now, we're missing extensive test cases.

## License

ni18n is licensed under MIT License. See [LICENSE](LICENSE) for more.
