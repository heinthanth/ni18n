# ni18n ( nim + i18n )

Super Fast Nim Macros For Internationalization and Localization.

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
        withCount:
            English = proc(count: int): string =
                case count
                of 0: "I have no cats"
                of 1: "I have one cat"
                else: "I have " & $count & " cats"
            Chinese = proc(count: int): string =
                case count
                of 0: "我没有猫"
                of 1: "我有一只猫"
                else: "我有" & $count & "只猫"

# prints 我有一只猫
echo ihaveCat_withCount(Chinese, 1)

# compiler error here since each function is generated with the same signature from lambda
echo ihaveCat_withCount(Chinese, "some str") 

# prints "你好, 黄小姐!". This function behave the same as `strutils.format`
hello(Chinese, ["name", "黄小姐"]) == "你好, 黄小姐!"
```

## Todos

- [ ] cleaner lookup function ( i.e. `ihaveCat.withCount` instead of `ihaveCat_withCount` )

## License

ni18n is licensed under MIT License. See [LICENSE](LICENSE) for more.