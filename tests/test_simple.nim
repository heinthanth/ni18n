import unittest
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

suite "simple test suite":
    test "simple test #1":
        check hello(English, "name", "Ms. Huang") == "Hello, Ms. Huang!"
        check hello(Chinese, "name", "黄小姐") == "你好, 黄小姐!"

    test "simple test #2":
        check ihaveCatWithCount(Chinese, 0) == "我没有猫"
        check ihaveCatWithCount(Chinese, 1) == "我有一只猫"
        check ihaveCatWithCount(Chinese, 5) == "我有五只猫"

    test "simple test #3":
        check ihaveCat(English) == "I've cats"
