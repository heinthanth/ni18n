# ni18n ( nim + i18n )

Super Fast Nim Macros For Internationalization and Localization.

## Installation

You can add repo URL to `.nimble` file

```nim
requires "https://github.com/heinthanth/ni18n >= 0.1.0"
```

I've submitted PR to nim packges repo here <https://github.com/nim-lang/packages/pull/2509>.
Once the PR is merged, u can install or require using just package name:

```nim
requires "ni18n >= 0.1.0"
```

## Quick Start

Super simple, Super Fast. No runtime lookup for translation: all translations are compiled down to Nim functions ( except we still have a runtime `case` statement for `locale` to call correct generated locale specific function )

```nim
import ni18n

type
    Locale = enum
        English
        Chinese

i18nInit Locale, true:
    hello:
        English = "Hello, $name!"
        Chinese = "你好, $name!"
    ihaveCat:
        English = "I've cats"
        Chinese = "我有猫"
        withCount:
            English = proc(count: int): string =
                case count
                of 0: "I have no cats"
                of 1: "I have one cat"
                else: "I have " & $count & " cats"
            Chinese = proc(count: int): string =
                proc translateCount(count: int): string =
                    case count
                    of 2: "二"
                    of 3: "三"
                    of 4: "四"
                    of 5: "五"
                    else: $count
                return case count
                    of 0: "我没有猫"
                    of 1: "我有一只猫"
                    else: "我有" & translateCount(count) & "只猫"

# prints "你好, 黄小姐!". This function behave the same as `strutils.format`
echo hello(Chinese, "name", "黄小姐")

# prints 我有猫
echo ihaveCat(Chinese)

# prints 我有五只猫
echo ihaveCat_withCount(Chinese, 5)

# compiler error here since each function is generated with the same signature from lambda
echo ihaveCat_withCount(Chinese, "some str") 
```

## Todos

- [ ] more readable ( `hello(Chinese, "name", "黄小姐")` -> `hello(Chinese, "黄小姐")` )
- [ ] cleaner lookup function ( `ihaveCat_withCount` -> `ihaveCat.withCount` )

## License

ni18n is licensed under MIT License. See [LICENSE](LICENSE) for more.