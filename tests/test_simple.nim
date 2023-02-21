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

suite "simple test suite":
    test "simple test #1":
        check hello(English, ["name", "Ms. Huang"]) == "Hello, Ms. Huang!"
        check hello(Chinese, ["name", "黄小姐"]) == "你好, 黄小姐!"

    test "simple test #2":
        check ihaveCat_withCount(Chinese, 0) == "我没有猫"
        check ihaveCat_withCount(Chinese, 1) == "我有一只猫"
        check ihaveCat_withCount(Chinese, 2) == "我有2只猫"
